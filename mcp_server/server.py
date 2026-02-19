from __future__ import annotations

from typing import Any

from .mock_data import ACCOUNTS, CUSTOMER, TRANSACTIONS


class ToolError(ValueError):
    pass


def _find_account(account_id: str) -> dict[str, Any]:
    for account in ACCOUNTS:
        if account["id"] == account_id:
            return account
    raise ToolError("Account not found")


def get_accounts() -> list[dict[str, Any]]:
    return [
        {
            "id": a["id"],
            "type": a["type"],
            "name": a["name"],
            "balance": a["balance"],
            "currency": a["currency"],
        }
        for a in ACCOUNTS
    ]


def get_account_detail(account_id: str) -> dict[str, Any]:
    account = _find_account(account_id)
    return {"customer": CUSTOMER, **account}


def get_transactions(account_id: str, limit: int = 20) -> list[dict[str, Any]]:
    _find_account(account_id)
    transactions = TRANSACTIONS.get(account_id, [])
    transactions = sorted(transactions, key=lambda tx: tx["date"], reverse=True)
    return transactions[: max(0, int(limit))]


def get_mortgage_summary(account_id: str) -> dict[str, Any]:
    account = _find_account(account_id)
    if account["type"] != "mortgage":
        raise ToolError("Account is not a mortgage account")
    return {
        "id": account["id"],
        "propertyAddress": account["propertyAddress"],
        "originalAmount": account["originalAmount"],
        "outstandingBalance": account["outstandingBalance"],
        "monthlyPayment": account["monthlyPayment"],
        "interestRate": account["interestRate"],
        "rateType": account["rateType"],
        "termEndDate": account["termEndDate"],
        "nextPaymentDate": account["nextPaymentDate"],
    }


def get_credit_card_statement(account_id: str) -> dict[str, Any]:
    account = _find_account(account_id)
    if account["type"] != "credit":
        raise ToolError("Account is not a credit card account")
    return {
        "id": account["id"],
        "cardNumber": account["cardNumberMasked"],
        "creditLimit": account["creditLimit"],
        "currentBalance": account["balance"],
        "availableCredit": account["availableCredit"],
        "minimumPayment": account["minimumPayment"],
        "paymentDueDate": account["paymentDueDate"],
        "recentTransactions": get_transactions(account_id, limit=5),
    }


TOOLS = {
    "get_accounts": get_accounts,
    "get_account_detail": get_account_detail,
    "get_transactions": get_transactions,
    "get_mortgage_summary": get_mortgage_summary,
    "get_credit_card_statement": get_credit_card_statement,
}


def call_tool(name: str, **kwargs: Any) -> Any:
    if name not in TOOLS:
        raise ToolError(f"Unknown tool: {name}")
    return TOOLS[name](**kwargs)


if __name__ == "__main__":
    import json
    import sys

    # Minimal stdio loop compatible with simple local agent integration.
    # Input lines: {"tool": "get_accounts", "args": {...}}
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            payload = json.loads(line)
            result = call_tool(payload["tool"], **payload.get("args", {}))
            print(json.dumps({"ok": True, "result": result}), flush=True)
        except Exception as exc:
            print(json.dumps({"ok": False, "error": str(exc)}), flush=True)
