from __future__ import annotations

from datetime import date, timedelta
from decimal import Decimal

CUSTOMER = {"id": "cust_demo_001", "name": "Alex Morgan"}

ACCOUNTS = [
    {
        "id": "acc_current_001",
        "type": "current",
        "name": "Everyday Current Account",
        "balance": "2450.67",
        "currency": "GBP",
        "accountNumber": "12345678",
        "sortCode": "12-34-56",
        "overdraftLimit": "500.00",
    },
    {
        "id": "acc_savings_001",
        "type": "savings",
        "name": "Rainy Day Saver",
        "balance": "10420.15",
        "currency": "GBP",
        "accountNumber": "87654321",
        "interestRate": "4.10",
        "interestEarned": "182.44",
    },
    {
        "id": "acc_credit_001",
        "type": "credit",
        "name": "AIBank Platinum Card",
        "balance": "-734.28",
        "currency": "GBP",
        "cardNumberMasked": "**** **** **** 9021",
        "creditLimit": "5000.00",
        "availableCredit": "4265.72",
        "minimumPayment": "36.71",
        "paymentDueDate": (date.today() + timedelta(days=12)).isoformat(),
    },
    {
        "id": "acc_mortgage_001",
        "type": "mortgage",
        "name": "Home Mortgage",
        "balance": "-187500.00",
        "currency": "GBP",
        "propertyAddress": "24 Cedar Grove, Bristol, BS1 4AB",
        "originalAmount": "250000.00",
        "outstandingBalance": "187500.00",
        "monthlyPayment": "1285.34",
        "interestRate": "3.85",
        "rateType": "fixed",
        "termEndDate": (date.today() + timedelta(days=365 * 21)).isoformat(),
        "nextPaymentDate": (date.today() + timedelta(days=18)).isoformat(),
    },
]


def _merchant(i: int) -> str:
    names = [
        "Tesco Superstore",
        "Transport for London",
        "Pret A Manger",
        "Octopus Energy",
        "Council Tax",
        "Spotify",
        "Amazon UK",
        "Boots",
        "M&S Food",
        "Costa Coffee",
    ]
    return names[i % len(names)]


def build_transactions(account_id: str, count: int = 20) -> list[dict]:
    today = date.today()
    running = Decimal("2450.67") if account_id == "acc_current_001" else Decimal("10420.15")
    txs: list[dict] = []
    for i in range(count):
        amount = Decimal((i % 7) * 9 + 8) / Decimal("1.0")
        is_debit = i % 3 != 0
        signed = -amount if is_debit else amount
        running = running + signed
        txs.append(
            {
                "id": f"tx_{account_id}_{i+1:03d}",
                "date": (today - timedelta(days=i * 3)).isoformat(),
                "description": _merchant(i),
                "amount": f"{abs(signed):.2f}",
                "currency": "GBP",
                "type": "debit" if is_debit else "credit",
                "runningBalance": f"{running:.2f}",
            }
        )
    return txs


TRANSACTIONS = {
    "acc_current_001": build_transactions("acc_current_001", 20),
    "acc_savings_001": build_transactions("acc_savings_001", 18),
    "acc_credit_001": build_transactions("acc_credit_001", 15),
}
