from __future__ import annotations

import json
import os
from dataclasses import dataclass
from typing import Any, Protocol

from mcp_server.server import call_tool


@dataclass(frozen=True)
class RuntimeResponse:
    text: str
    template_name: str
    data: dict[str, Any]


class AgentRuntime(Protocol):
    def run(self, message: str) -> RuntimeResponse:
        ...


class DeterministicRuntime:
    def _intent(self, message: str) -> str:
        m = message.lower()
        if "mortgage" in m:
            return "mortgage"
        if "credit" in m or "card" in m:
            return "credit"
        if "savings" in m:
            return "savings"
        if "transaction" in m:
            return "transactions"
        if "detail" in m or "account" in m and "show my" not in m:
            return "account_detail"
        return "overview"

    def _net_worth(self, accounts: list[dict[str, Any]]) -> str:
        total = 0.0
        for account in accounts:
            total += float(account["balance"])
        return f"{total:.2f}"

    def run(self, message: str) -> RuntimeResponse:
        intent = self._intent(message)
        if intent == "mortgage":
            account = next(a for a in call_tool("get_accounts") if a["type"] == "mortgage")
            mortgage = call_tool("get_mortgage_summary", account_id=account["id"])
            return RuntimeResponse(
                text="Here is your mortgage summary.",
                template_name="mortgage_summary.json",
                data={"mortgage": mortgage},
            )
        if intent == "credit":
            account = next(a for a in call_tool("get_accounts") if a["type"] == "credit")
            credit = call_tool("get_credit_card_statement", account_id=account["id"])
            return RuntimeResponse(
                text="Here is your credit card statement.",
                template_name="credit_card_statement.json",
                data={"credit": credit},
            )
        if intent == "savings":
            account = next(a for a in call_tool("get_accounts") if a["type"] == "savings")
            savings = call_tool("get_account_detail", account_id=account["id"])
            return RuntimeResponse(
                text="Here is your savings account summary.",
                template_name="savings_summary.json",
                data={"savings": savings},
            )
        if intent == "transactions":
            account = next(a for a in call_tool("get_accounts") if a["type"] == "current")
            txs = call_tool("get_transactions", account_id=account["id"], limit=10)
            return RuntimeResponse(
                text="Here are your latest transactions.",
                template_name="transaction_list.json",
                data={"transactions": txs},
            )
        if intent == "account_detail":
            account = call_tool("get_accounts")[0]
            detail = call_tool("get_account_detail", account_id=account["id"])
            transactions = call_tool("get_transactions", account_id=account["id"], limit=10)
            return RuntimeResponse(
                text=f"Details for {detail['name']}.",
                template_name="account_detail.json",
                data={**detail, "transactions": transactions},
            )

        accounts = call_tool("get_accounts")
        return RuntimeResponse(
            text="Here is an overview of all your accounts.",
            template_name="account_overview.json",
            data={"accounts": accounts, "netWorth": self._net_worth(accounts)},
        )


class ADKRuntime:
    def __init__(self) -> None:
        self._model = os.getenv("LLM_MODEL", "gpt-5-mini")
        self._runner = None
        self._session_id = os.getenv("ADK_SESSION_ID", "aibank-default-session")
        self._user_id = os.getenv("ADK_USER_ID", "aibank-user")
        self._app_name = os.getenv("ADK_APP_NAME", "aibank-agent")

    @staticmethod
    def _tool_get_accounts() -> list[dict[str, Any]]:
        """Get all accounts for the customer."""
        return call_tool("get_accounts")

    @staticmethod
    def _tool_get_account_detail(account_id: str) -> dict[str, Any]:
        """Get detailed information for one account by id."""
        return call_tool("get_account_detail", account_id=account_id)

    @staticmethod
    def _tool_get_transactions(account_id: str, limit: int = 10) -> list[dict[str, Any]]:
        """Get transactions for an account, newest first."""
        return call_tool("get_transactions", account_id=account_id, limit=limit)

    @staticmethod
    def _tool_get_mortgage_summary(account_id: str) -> dict[str, Any]:
        """Get mortgage summary for a mortgage account."""
        return call_tool("get_mortgage_summary", account_id=account_id)

    @staticmethod
    def _tool_get_credit_card_statement(account_id: str) -> dict[str, Any]:
        """Get credit card statement for a credit account."""
        return call_tool("get_credit_card_statement", account_id=account_id)

    def _build_runner(self):
        from google.adk.agents.llm_agent import LlmAgent
        from google.adk.runners import Runner
        from google.adk.sessions import InMemorySessionService

        instruction = """
You are a banking assistant for mock data.
Always use available tools to fetch account data before answering.
Return ONLY a strict JSON object with keys:
- text: short user-facing text
- template_name: one of ["account_overview.json","account_detail.json","transaction_list.json","mortgage_summary.json","credit_card_statement.json","savings_summary.json"]
- data: object payload matching template bindings
Do not include markdown fences.
"""

        agent = LlmAgent(
            name="aibank_agent",
            model=self._model,
            instruction=instruction,
            tools=[
                self._tool_get_accounts,
                self._tool_get_account_detail,
                self._tool_get_transactions,
                self._tool_get_mortgage_summary,
                self._tool_get_credit_card_statement,
            ],
        )
        session_service = InMemorySessionService()
        session_service.create_session(
            app_name=self._app_name,
            user_id=self._user_id,
            session_id=self._session_id,
        )
        self._runner = Runner(app_name=self._app_name, agent=agent, session_service=session_service)

    def _extract_final_text(self, events: list[Any]) -> str:
        for event in reversed(events):
            if event.is_final_response() and event.content and event.content.parts:
                text = event.content.parts[0].text
                if text:
                    return text
        raise RuntimeError("ADK runtime produced no final text response")

    def run(self, message: str) -> RuntimeResponse:
        if self._runner is None:
            self._build_runner()

        from google.genai import types

        content = types.Content(role="user", parts=[types.Part(text=message)])
        try:
            events = list(self._runner.run(user_id=self._user_id, session_id=self._session_id, new_message=content))
        except Exception as exc:
            raise RuntimeError(f"ADK runtime execution failed: {exc}") from exc

        final_text = self._extract_final_text(events)
        try:
            payload = json.loads(final_text)
        except json.JSONDecodeError as exc:
            raise RuntimeError("ADK runtime did not return valid JSON output") from exc

        template_name = payload.get("template_name")
        allowed = {
            "account_overview.json",
            "account_detail.json",
            "transaction_list.json",
            "mortgage_summary.json",
            "credit_card_statement.json",
            "savings_summary.json",
        }
        if template_name not in allowed:
            raise RuntimeError(f"ADK runtime returned unsupported template: {template_name}")

        text = str(payload.get("text", "")).strip()
        data = payload.get("data")
        if not isinstance(data, dict):
            raise RuntimeError("ADK runtime returned invalid data payload")

        return RuntimeResponse(text=text or "Here is your banking update.", template_name=template_name, data=data)


def get_runtime() -> AgentRuntime:
    runtime = os.getenv("AGENT_RUNTIME", "deterministic").lower()
    if runtime == "adk":
        return ADKRuntime()
    return DeterministicRuntime()
