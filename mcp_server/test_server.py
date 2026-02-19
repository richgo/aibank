from mcp_server.server import ToolError, get_account_detail, get_accounts, get_credit_card_statement, get_mortgage_summary, get_transactions


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
