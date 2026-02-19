from agent.agent import handle_query


def test_overview_query_returns_accounts():
    response = handle_query('show my accounts')
    assert 'accounts' in response.data
    assert response.a2ui


def test_transactions_query_returns_transactions():
    response = handle_query('show transactions for my current account')
    assert 'transactions' in response.data
    assert len(response.data['transactions']) > 0


def test_mortgage_query_returns_mortgage_data():
    response = handle_query('what is my mortgage balance')
    assert 'mortgage' in response.data
