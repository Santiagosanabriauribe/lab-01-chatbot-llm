import json

import pytest
from pydantic import ValidationError

from config import load_settings
from llm_client import FakeLLMClient, make_client
from prompts import SYSTEM_PROMPT, build_messages
from structured import analyze_question


def test_build_messages_sin_historial():
    messages = build_messages([], "Hola")
    assert messages == [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": "Hola"},
    ]


def test_build_messages_con_historial_respeta_el_orden():
    history = [
        {"role": "user", "content": "uno"},
        {"role": "assistant", "content": "dos"},
    ]
    messages = build_messages(history, "tres")
    assert [m["role"] for m in messages] == ["system", "user", "assistant", "user"]
    assert messages[-1]["content"] == "tres"
    assert history == [
        {"role": "user", "content": "uno"},
        {"role": "assistant", "content": "dos"},
    ]


def test_analyze_question_devuelve_objeto_validado():
    payload = {
        "tema": "atención",
        "dificultad": "intermedia",
        "requiere_documentos_del_curso": False,
        "respuesta_corta": "Pondera la relevancia entre tokens.",
    }
    client = FakeLLMClient([json.dumps(payload)])
    analysis = analyze_question(client, "¿Qué es la atención?")
    assert analysis.requiere_documentos_del_curso is False
    assert analysis.dificultad == "intermedia"
    assert client.calls[0]["json_mode"] is True
    assert client.calls[0]["temperature"] == 0


def test_analyze_question_rechaza_json_invalido(capsys):
    with pytest.raises(json.JSONDecodeError):
        analyze_question(FakeLLMClient(["esto no es json"]), "pregunta")


def test_analyze_question_rechaza_esquema_invalido(capsys):
    bad = {
        "tema": "x",
        "dificultad": "media",
        "requiere_documentos_del_curso": True,
        "respuesta_corta": "y",
    }
    with pytest.raises(ValidationError):
        analyze_question(FakeLLMClient([json.dumps(bad)]), "pregunta")


def test_provider_fake_no_necesita_clave(monkeypatch):
    monkeypatch.setenv("LLM_PROVIDER", "fake")
    monkeypatch.delenv("LLM_API_KEY", raising=False)
    client = make_client(load_settings())
    assert isinstance(client, FakeLLMClient)


def test_config_sin_clave_da_mensaje_claro(monkeypatch):
    monkeypatch.setattr("config.load_dotenv", lambda *a, **k: None)
    monkeypatch.setenv("LLM_PROVIDER", "groq")
    monkeypatch.setenv("LLM_API_KEY", "")
    with pytest.raises(ValueError, match="LLM_API_KEY"):
        load_settings()
