from mcp_server.server import ToolError, get_account_detail, get_accounts, get_credit_card_statement, get_mortgage_summary, get_transactions
from mcp_server.mock_data import ACCOUNTS, CUSTOMER, TRANSACTIONS


# Task 2.1: Mock Data Tests
def test_mock_data_has_one_account_per_type():
    """Verify at least one account of each type (current, savings, credit, mortgage)"""
    types = {a['type'] for a in ACCOUNTS}
    assert 'current' in types
    assert 'savings' in types
    assert 'credit' in types
    assert 'mortgage' in types


def test_mock_data_has_minimum_transactions():
    """Verify 15-20 transactions per account"""
    for account_id, txs in TRANSACTIONS.items():
        assert 15 <= len(txs) <= 20, f"Account {account_id} has {len(txs)} transactions, expected 15-20"


def test_mock_data_uses_gbp():
    """Verify all accounts use GBP currency"""
    for account in ACCOUNTS:
        assert account['currency'] == 'GBP', f"Account {account['id']} uses {account['currency']}, expected GBP"


def test_mock_data_is_fictitious():
    """Verify no real account numbers or customer names"""
    # Customer should be clearly fictitious
    assert CUSTOMER['id'].startswith('cust_demo') or CUSTOMER['id'].startswith('cust_test')
    
    # Account numbers should be demo/test
    for account in ACCOUNTS:
        if 'accountNumber' in account:
            # UK account numbers are 8 digits, but should not be real
            assert len(account['accountNumber']) == 8
        if 'sortCode' in account:
            # UK sort codes format XX-XX-XX
            assert '-' in account['sortCode']
        if 'cardNumberMasked' in account:
            # Card numbers should be masked
            assert '****' in account['cardNumberMasked']


def test_get_accounts_contains_all_types():
    accounts = get_accounts()
    types = {a['type'] for a in accounts}
    assert {'current', 'savings', 'credit', 'mortgage'} <= types


def test_get_account_detail_invalid_id():
    try:
        get_account_detail('missing')
    except ToolError as exc:
        assert 'Account not found' in str(exc)
    else:
        raise AssertionError('Expected ToolError')


def test_get_transactions_limit_and_sort():
    txs = get_transactions('acc_current_001', limit=5)
    assert len(txs) == 5
    assert txs[0]['date'] >= txs[-1]['date']


def test_credit_and_mortgage_tools():
    cc = get_credit_card_statement('acc_credit_001')
    assert cc['cardNumber'].endswith('9021')
    mtg = get_mortgage_summary('acc_mortgage_001')
    assert mtg['rateType'] in {'fixed', 'variable'}


# Task 2.2: get_accounts Tool Tests
def test_get_accounts_returns_list():
    """get_accounts should return a JSON array"""
    accounts = get_accounts()
    assert isinstance(accounts, list)
    assert len(accounts) > 0


def test_get_accounts_includes_required_fields():
    """Each account should include id, type, name, balance, currency"""
    accounts = get_accounts()
    for account in accounts:
        assert 'id' in account, f"Account missing 'id': {account}"
        assert 'type' in account, f"Account missing 'type': {account}"
        assert 'name' in account, f"Account missing 'name': {account}"
        assert 'balance' in account, f"Account missing 'balance': {account}"
        assert 'currency' in account, f"Account missing 'currency': {account}"


def test_get_accounts_type_values():
    """Account types should be current, savings, credit, or mortgage"""
    accounts = get_accounts()
    valid_types = {'current', 'savings', 'credit', 'mortgage'}
    for account in accounts:
        assert account['type'] in valid_types, f"Invalid account type: {account['type']}"


# Task 2.3: get_account_detail Tool Tests
def test_get_account_detail_current_account():
    """Current account detail should include specific fields"""
    detail = get_account_detail('acc_current_001')
    assert detail['id'] == 'acc_current_001'
    assert detail['type'] == 'current'
    assert 'name' in detail
    assert 'balance' in detail
    assert 'currency' in detail
    assert 'accountNumber' in detail
    assert 'sortCode' in detail
    assert 'overdraftLimit' in detail
    assert 'customer' in detail


def test_get_account_detail_savings_account():
    """Savings account detail should include specific fields"""
    detail = get_account_detail('acc_savings_001')
    assert detail['id'] == 'acc_savings_001'
    assert detail['type'] == 'savings'
    assert 'interestRate' in detail
    assert 'interestEarned' in detail
    assert 'accountNumber' in detail


def test_get_account_detail_includes_customer():
    """All account details should include customer information"""
    detail = get_account_detail('acc_current_001')
    assert 'customer' in detail
    assert 'id' in detail['customer']
    assert 'name' in detail['customer']


# Task 2.4: get_transactions Tool Tests
def test_get_transactions_returns_array():
    """get_transactions should return a JSON array"""
    txs = get_transactions('acc_current_001')
    assert isinstance(txs, list)


def test_get_transactions_includes_required_fields():
    """Each transaction should include required fields"""
    txs = get_transactions('acc_current_001')
    assert len(txs) > 0
    for tx in txs:
        assert 'id' in tx
        assert 'date' in tx
        assert 'description' in tx
        assert 'amount' in tx
        assert 'currency' in tx
        assert 'type' in tx
        assert 'runningBalance' in tx


def test_get_transactions_type_values():
    """Transaction types should be debit or credit"""
    txs = get_transactions('acc_current_001')
    for tx in txs:
        assert tx['type'] in {'debit', 'credit'}, f"Invalid transaction type: {tx['type']}"


def test_get_transactions_default_limit():
    """get_transactions should default to 20 transactions"""
    txs = get_transactions('acc_current_001')
    assert len(txs) <= 20


def test_get_transactions_sorted_descending():
    """Transactions should be sorted by date descending (most recent first)"""
    txs = get_transactions('acc_current_001')
    for i in range(len(txs) - 1):
        assert txs[i]['date'] >= txs[i + 1]['date'], f"Transactions not sorted: {txs[i]['date']} < {txs[i + 1]['date']}"


# Task 2.5: get_mortgage_summary Tool Tests
def test_get_mortgage_summary_includes_required_fields():
    """Mortgage summary should include all required fields"""
    mtg = get_mortgage_summary('acc_mortgage_001')
    assert 'id' in mtg
    assert 'propertyAddress' in mtg
    assert 'originalAmount' in mtg
    assert 'outstandingBalance' in mtg
    assert 'monthlyPayment' in mtg
    assert 'interestRate' in mtg
    assert 'rateType' in mtg
    assert 'termEndDate' in mtg
    assert 'nextPaymentDate' in mtg


def test_get_mortgage_summary_rate_type_valid():
    """Rate type should be fixed or variable"""
    mtg = get_mortgage_summary('acc_mortgage_001')
    assert mtg['rateType'] in {'fixed', 'variable'}


def test_get_mortgage_summary_wrong_account_type():
    """Should error when called on non-mortgage account"""
    try:
        get_mortgage_summary('acc_current_001')
        raise AssertionError('Expected ToolError for non-mortgage account')
    except ToolError as exc:
        assert 'not a mortgage' in str(exc).lower()
