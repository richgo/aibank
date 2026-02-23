import json
from pathlib import Path

import jsonschema
import pytest

from agent.a2ui_schema import A2UI_SCHEMA


def test_all_templates_validate():
    templates_dir = Path(__file__).parent / 'templates'
    files = sorted(templates_dir.glob('*.json'))
    assert files
    for file in files:
        payload = json.loads(file.read_text(encoding='utf-8'))
        jsonschema.validate(instance=payload, schema=A2UI_SCHEMA)
        message_keys = {next(iter(item.keys())) for item in payload}
        assert 'surfaceUpdate' in message_keys
        assert 'dataModelUpdate' in message_keys
        assert 'beginRendering' in message_keys


@pytest.mark.parametrize("template_name", ["transaction_list.json", "account_detail.json"])
def test_transaction_row_button_action_structure(template_name):
    templates_dir = Path(__file__).parent / 'templates'
    payload = json.loads((templates_dir / template_name).read_text(encoding='utf-8'))
    surface_update = next(item["surfaceUpdate"] for item in payload if "surfaceUpdate" in item)
    tx_row_button = next(
        component["component"]["Button"]
        for component in surface_update["components"]
        if component["id"] == "txRowButton"
    )
    assert tx_row_button["action"]["name"] == "selectTransaction"
    context = tx_row_button["action"]["context"]
    assert [item["key"] for item in context] == [
        "transactionId",
        "description",
        "formattedDate",
        "amountDisplay",
    ]
    assert {item["key"]: item["value"] for item in context} == {
        "transactionId": {"path": "id"},
        "description": {"path": "description"},
        "formattedDate": {"path": "formattedDate"},
        "amountDisplay": {"path": "amountDisplay"},
    }
