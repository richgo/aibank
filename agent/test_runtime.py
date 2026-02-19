from agent.runtime import ADKRuntime, DeterministicRuntime, get_runtime


def test_get_runtime_defaults_to_deterministic(monkeypatch):
    monkeypatch.delenv('AGENT_RUNTIME', raising=False)
    runtime = get_runtime()
    assert isinstance(runtime, DeterministicRuntime)


def test_get_runtime_supports_adk(monkeypatch):
    monkeypatch.setenv('AGENT_RUNTIME', 'adk')
    runtime = get_runtime()
    assert isinstance(runtime, ADKRuntime)


class _FakePart:
    def __init__(self, text: str):
        self.text = text


class _FakeContent:
    def __init__(self, text: str):
        self.parts = [_FakePart(text)]


class _FakeEvent:
    def __init__(self, text: str):
        self.content = _FakeContent(text)

    def is_final_response(self) -> bool:
        return True


class _FakeRunner:
    def __init__(self, text: str):
        self._text = text

    def run(self, **kwargs):
        yield _FakeEvent(self._text)


def test_adk_runtime_parses_valid_json(monkeypatch):
    runtime = ADKRuntime()
    payload = '{"text":"ok","template_name":"account_overview.json","data":{"accounts":[],"netWorth":"0.00"}}'
    runtime._runner = _FakeRunner(payload)
    result = runtime.run('show my accounts')
    assert result.template_name == 'account_overview.json'
    assert result.data['netWorth'] == '0.00'


def test_adk_runtime_raises_on_invalid_json():
    runtime = ADKRuntime()
    runtime._runner = _FakeRunner('not-json')
    try:
        runtime.run('show my accounts')
    except RuntimeError as exc:
        assert 'valid JSON' in str(exc)
    else:
        raise AssertionError('Expected RuntimeError')
