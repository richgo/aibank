from __future__ import annotations

import json
import os
from dataclasses import dataclass
from typing import Any, Protocol

from mcp_server.server import call_tool
from agent.mcp_apps import geocode_merchant


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
        # Check for transaction location intent first (more specific)
        location_keywords = ["where", "location", "map"]
        if any(kw in m for kw in location_keywords):
            return "transaction_location"
        if "show me" in m and ("shopped" in m or "spent" in m or "purchase" in m):
            return "transaction_location"
        if "mortgage" in m:
            return "mortgage"
        if "credit" in m or "card" in m:
            return "credit"
        if "savings" in m:
            return "savings"
        if "transaction" in m:
            return "transactions"
        if "detail" in m or "show details" in m:
            return "account_detail"
        if any(w in m for w in ["all account", "my account", "accounts", "overview"]):
            return "overview"
        if "account" in m:
            return "account_detail"
        return "overview"

    def _extract_merchant(
        self, message: str, transactions: list[dict[str, Any]]
    ) -> tuple[dict[str, Any], str] | None:
        """
        Find a transaction matching a merchant mentioned in the user's message.

        Returns tuple of (transaction, merchant_name) or None if no match.
        If multiple matches, returns the most recent (first in list).
        """
        m = message.lower()

        for tx in transactions:
            description = tx.get("description", "")
            # Extract words from description for matching
            desc_words = description.lower().split()
            # Check if any significant word from description appears in message
            for word in desc_words:
                if len(word) > 3 and word in m:  # Skip short words
                    return (tx, description)

        return None

    def _net_worth(self, accounts: list[dict[str, Any]]) -> str:
        total = 0.0
        for account in accounts:
            total += float(account["balance"])
        return f"{total:.2f}"

    _MONTHS = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
               'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

    @staticmethod
    def _format_date(date_str: str) -> str:
        """Format 'YYYY-MM-DD' to 'DD Mon'."""
        try:
            parts = date_str.split('-')
            if len(parts) == 3:
                month = int(parts[1])
                return f"{parts[2]} {DeterministicRuntime._MONTHS[month]}"
        except (ValueError, IndexError):
            pass
        return date_str

    @staticmethod
    def _format_transactions(transactions: list[dict[str, Any]]) -> None:
        """Add display-ready fields to each transaction (mutates in place)."""
        for tx in transactions:
            amt = tx.get("amount", "0.00")
            tx["amountDisplay"] = f"-£{amt}" if tx.get("type") == "debit" else f"+£{amt}"
            tx["formattedDate"] = DeterministicRuntime._format_date(tx.get("date", ""))

    @staticmethod
    def _list_to_map(items: list) -> dict[str, Any]:
        """Convert a list to an index-keyed dict for genui DataModel compatibility."""
        return {str(i): item for i, item in enumerate(items)}

    @staticmethod
    def _format_detail_data(
        detail: dict[str, Any], transactions: list[dict[str, Any]]
    ) -> dict[str, Any]:
        """Prepare account detail data with display-ready fields."""
        balance = detail.get("balance", "0.00")
        is_negative = balance.startswith("-")
        display_bal = f"-£{balance[1:]}" if is_negative else f"£{balance}"

        acct_type = detail.get("type", "")
        parts = []
        if detail.get("accountNumber"):
            parts.append(f"Account: {detail['accountNumber']}")
        if detail.get("sortCode"):
            parts.append(f"Sort Code: {detail['sortCode']}")
        if detail.get("interestRate"):
            parts.append(f"Interest: {detail['interestRate']}%")
        if detail.get("overdraftLimit"):
            parts.append(f"Overdraft: £{detail['overdraftLimit']}")
        detail_line = " · ".join(parts) if parts else ""

        DeterministicRuntime._format_transactions(transactions)

        return {
            **detail,
            "balanceDisplay": display_bal,
            "typeLabel": acct_type.title(),
            "detailLine": detail_line,
            "transactions": DeterministicRuntime._list_to_map(transactions),
        }

    @staticmethod
    def _format_mortgage_data(mortgage: dict[str, Any]) -> dict[str, Any]:
        """Prepare mortgage data with display-ready fields."""
        return {
            **mortgage,
            "balanceDisplay": f"£{mortgage.get('outstandingBalance', '0.00')}",
            "paymentDisplay": f"£{mortgage.get('monthlyPayment', '0.00')}",
            "rateDisplay": f"{mortgage.get('interestRate', '')}% ({mortgage.get('rateType', '')})",
            "originalDisplay": f"£{mortgage.get('originalAmount', '0.00')}",
        }

    @staticmethod
    def _format_credit_data(credit: dict[str, Any]) -> dict[str, Any]:
        """Prepare credit card data with display-ready fields."""
        limit_val = float(credit.get("creditLimit", 0))
        balance_val = abs(float(credit.get("currentBalance", 0)))
        utilization = int(balance_val / limit_val * 100) if limit_val else 0
        txs = credit.get("recentTransactions", [])
        DeterministicRuntime._format_transactions(txs)
        return {
            **credit,
            "balanceDisplay": f"£{credit.get('currentBalance', '0.00')}",
            "availableDisplay": f"£{credit.get('availableCredit', '0.00')}",
            "limitDisplay": f"£{credit.get('creditLimit', '0.00')}",
            "utilizationDisplay": f"{utilization}% of limit used",
            "minimumPaymentDisplay": f"£{credit.get('minimumPayment', '0.00')}",
            "transactions": DeterministicRuntime._list_to_map(txs),
        }

    @staticmethod
    def _format_savings_data(savings: dict[str, Any]) -> dict[str, Any]:
        """Prepare savings data with display-ready fields."""
        return {
            **savings,
            "balanceDisplay": f"£{savings.get('balance', '0.00')}",
            "rateDisplay": f"Interest rate: {savings.get('interestRate', '')}%",
        }

    def run(self, message: str) -> RuntimeResponse:
        # Handle UI action events (button taps from A2UI components)
        if "useraction" in message.lower():
            try:
                import json as _json
                action = _json.loads(message)
                ctx = action.get("userAction", {}).get("context", {})
                action_name = action.get("userAction", {}).get("name", "")

                if action_name == "backToOverview":
                    accounts = call_tool("get_accounts")
                    net_worth = self._net_worth(accounts)
                    return RuntimeResponse(
                        text="Here is an overview of all your accounts.",
                        template_name="account_overview.json",
                        data={"accounts": self._list_to_map(accounts), "headerText": f"Net Worth: £{net_worth}"},
                    )

                account_id = ctx.get("accountId")
                if account_id:
                    detail = call_tool("get_account_detail", account_id=account_id)
                    transactions = call_tool("get_transactions", account_id=account_id, limit=10)
                    data = self._format_detail_data(detail, transactions)
                    return RuntimeResponse(
                        text=detail["name"],
                        template_name="account_detail.json",
                        data=data,
                    )
            except (ValueError, KeyError):
                pass

        intent = self._intent(message)
        if intent == "transaction_location":
            # Get transactions from current account
            accounts = call_tool("get_accounts")
            current_account = next(
                (a for a in accounts if a["type"] == "current"),
                accounts[0] if accounts else None
            )
            if not current_account:
                return RuntimeResponse(
                    text="I couldn't find any accounts.",
                    template_name="account_overview.json",
                    data={"accounts": self._list_to_map([]), "netWorth": "0.00"},
                )

            transactions = call_tool("get_transactions", account_id=current_account["id"], limit=20)

            # Try to extract merchant from message
            merchant_result = self._extract_merchant(message, transactions)

            if merchant_result is None:
                # No specific merchant found, show general text
                self._format_transactions(transactions)
                return RuntimeResponse(
                    text="I couldn't identify which transaction you're asking about. Please specify a merchant name.",
                    template_name="transaction_list.json",
                    data={
                        "transactions": self._list_to_map(transactions),
                        "accountName": current_account.get("name", "Account"),
                        "transactionCount": f"{len(transactions)} transactions",
                    },
                )

            tx, merchant_name = merchant_result

            # Geocode the merchant
            location = geocode_merchant(merchant_name)

            if location is None:
                # Geocoding failed
                self._format_transactions([tx])
                return RuntimeResponse(
                    text=f"I couldn't find the location for {merchant_name}. This may be an online purchase or the location is unavailable.",
                    template_name="transaction_list.json",
                    data={
                        "transactions": self._list_to_map([tx]),
                        "accountName": current_account.get("name", "Account"),
                        "transactionCount": "1 transaction",
                    },
                )

            # Success - return transaction with location
            return RuntimeResponse(
                text=f"Here is where your {merchant_name} transaction occurred.",
                template_name="transaction_location.json",
                data={
                    "transaction": tx,
                    "location": location,
                },
            )

        if intent == "mortgage":
            account = next(a for a in call_tool("get_accounts") if a["type"] == "mortgage")
            mortgage = call_tool("get_mortgage_summary", account_id=account["id"])
            data = self._format_mortgage_data(mortgage)
            return RuntimeResponse(
                text="Here is your mortgage summary.",
                template_name="mortgage_summary.json",
                data=data,
            )
        if intent == "credit":
            account = next(a for a in call_tool("get_accounts") if a["type"] == "credit")
            credit = call_tool("get_credit_card_statement", account_id=account["id"])
            data = self._format_credit_data(credit)
            return RuntimeResponse(
                text="Here is your credit card statement.",
                template_name="credit_card_statement.json",
                data=data,
            )
        if intent == "savings":
            account = next(a for a in call_tool("get_accounts") if a["type"] == "savings")
            savings = call_tool("get_account_detail", account_id=account["id"])
            data = self._format_savings_data(savings)
            return RuntimeResponse(
                text="Here is your savings account summary.",
                template_name="savings_summary.json",
                data=data,
            )
        if intent == "transactions":
            all_accounts = call_tool("get_accounts")
            # Try to match by account name mentioned in the message
            account = next(
                (a for a in all_accounts if a["name"].lower() in message.lower()),
                next((a for a in all_accounts if a["type"] == "current"), all_accounts[0])
            )
            txs = call_tool("get_transactions", account_id=account["id"], limit=10)
            self._format_transactions(txs)
            return RuntimeResponse(
                text=f"Here are the latest transactions for {account['name']}.",
                template_name="transaction_list.json",
                data={
                    "transactions": self._list_to_map(txs),
                    "accountName": account["name"],
                    "transactionCount": f"{len(txs)} transactions",
                },
            )
        if intent == "account_detail":
            all_accounts = call_tool("get_accounts")
            account = next(
                (a for a in all_accounts if a["name"].lower() in message.lower()),
                next((a for a in all_accounts if a["type"] == "current"), all_accounts[0])
            )
            detail = call_tool("get_account_detail", account_id=account["id"])
            transactions = call_tool("get_transactions", account_id=account["id"], limit=10)
            data = self._format_detail_data(detail, transactions)
            return RuntimeResponse(
                text=detail["name"],
                template_name="account_detail.json",
                data=data,
            )

        accounts = call_tool("get_accounts")
        net_worth = self._net_worth(accounts)
        return RuntimeResponse(
            text="Here is an overview of all your accounts.",
            template_name="account_overview.json",
            data={"accounts": self._list_to_map(accounts), "headerText": f"Net Worth: £{net_worth}"},
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
            "transaction_location.json",
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
