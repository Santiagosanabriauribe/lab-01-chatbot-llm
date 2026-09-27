"""Cliente del LLM: la única parte de la aplicación que conoce al proveedor.

Recibe una lista de mensajes y parámetros; devuelve un LLMResponse.
El resto de la aplicación no importa `openai` ni sabe qué proveedor se usa.
"""

from dataclasses import dataclass

import openai

from config import Settings

# Un mensaje es un diccionario {"role": "system" | "user" | "assistant", "content": "..."}
Message = dict[str, str]


@dataclass
class LLMResponse:
    text: str
    model: str
    finish_reason: str  # "stop" = terminó normalmente, "length" = se agotó max_tokens
    prompt_tokens: int
    completion_tokens: int


class LLMError(Exception):
    """Error al comunicarse con el proveedor, expresado sin detalles del SDK."""


class LLMClient:
    def __init__(self, settings: Settings):
        self.settings = settings
        self._client = openai.OpenAI(base_url=settings.base_url, api_key=settings.api_key)

    def chat(
        self,
        messages: list[Message],
        *,
        temperature: float | None = None,
        max_tokens: int | None = None,
        json_mode: bool = False,
    ) -> LLMResponse:
        params = {
            "model": self.settings.model,
            "messages": messages,
            "temperature": self.settings.temperature if temperature is None else temperature,
            "max_tokens": self.settings.max_tokens if max_tokens is None else max_tokens,
        }
        if json_mode:
            params["response_format"] = {"type": "json_object"}

        try:
            completion = self._client.chat.completions.create(**params)
        except openai.APIError as exc:
            raise LLMError(f"Falló la llamada al proveedor ({self.settings.provider}): {exc}") from exc

        choice = completion.choices[0]
        usage = completion.usage
        return LLMResponse(
            text=choice.message.content or "",
            model=completion.model,
            finish_reason=choice.finish_reason,
            prompt_tokens=usage.prompt_tokens if usage else 0,
            completion_tokens=usage.completion_tokens if usage else 0,
        )


class FakeLLMClient:
    """Proveedor falso para pruebas: mismo método chat, respuestas predefinidas, sin red."""

    def __init__(self, responses: list[str] | None = None):
        self.responses = list(responses) if responses else ["Respuesta simulada."]
        self.calls: list[dict] = []

    def chat(
        self,
        messages: list[Message],
        *,
        temperature: float | None = None,
        max_tokens: int | None = None,
        json_mode: bool = False,
    ) -> LLMResponse:
        self.calls.append(
            {
                "messages": messages,
                "temperature": temperature,
                "max_tokens": max_tokens,
                "json_mode": json_mode,
            }
        )
        text = self.responses[min(len(self.calls), len(self.responses)) - 1]
        prompt_tokens = sum(len(m["content"].split()) for m in messages)
        return LLMResponse(
            text=text,
            model="fake-model",
            finish_reason="stop",
            prompt_tokens=prompt_tokens,
            completion_tokens=len(text.split()),
        )


def make_client(settings: Settings) -> "LLMClient | FakeLLMClient":
    """Elige la implementación según LLM_PROVIDER. Solo este módulo conoce las opciones."""
    if settings.provider == "fake":
        return FakeLLMClient()
    return LLMClient(settings)


if __name__ == "__main__":
    # Prueba de humo: una sola llamada, sin interfaz ni historial.
    from config import load_settings

    client = make_client(load_settings())
    response = client.chat(
        [
            {"role": "system", "content": "Responde en una sola frase, en español."},
            {"role": "user", "content": "¿Qué es un Transformer en IA?"},
        ]
    )
    print(response)
