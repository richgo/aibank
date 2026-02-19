import json
from pathlib import Path

import jsonschema

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
