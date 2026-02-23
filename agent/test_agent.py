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
    assert 'propertyAddress' in response.data


def test_handle_query_assigns_unique_surface_id_per_response():
    first = handle_query('show my accounts')
    second = handle_query('show my accounts')

    def extract_surface_ids(response):
        ids = {}
        for key in ("surfaceUpdate", "dataModelUpdate", "beginRendering"):
            payload = next(item[key] for item in response.a2ui if key in item)
            ids[key] = payload["surfaceId"]
        return ids

    first_ids = extract_surface_ids(first)
    second_ids = extract_surface_ids(second)

    assert len(set(first_ids.values())) == 1
    assert len(set(second_ids.values())) == 1
    assert first_ids["surfaceUpdate"] != second_ids["surfaceUpdate"]
    assert next(item["dataModelUpdate"] for item in first.a2ui if "dataModelUpdate" in item)["contents"] == first.data
