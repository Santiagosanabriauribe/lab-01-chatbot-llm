param([string]$TestNum)
$ErrorActionPreference = 'SilentlyContinue'
Set-Location C:\Users\User\lab-ia-chatbot
$env:PYTHONIOENCODING = 'utf-8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

switch ($TestNum) {
    "1" {
        Write-Host "=== PRUEBA 1: RAG como tool (capabilities.py, TODO 1) ===" -ForegroundColor Cyan
        Write-Host ""
        Write-Host 'PS C:\lab-ia-chatbot> uv run python labs/04-agent-orchestration/capabilities.py "fecha del primer parcial"' -ForegroundColor Yellow
        Write-Host ""
        & uv run python labs/04-agent-orchestration/capabilities.py "fecha del primer parcial"
        Write-Host ""
        Write-Host "RESULTADO: Fragmentos numerados con fuente, incluye el anuncio del 20 de octubre. Sin LLM." -ForegroundColor Green
    }
    "2" {
        Write-Host "=== PRUEBA 2: Encadenar tools - Agente calcula nota final ===" -ForegroundColor Cyan
        Write-Host ""
        Write-Host 'Pregunta: "Mi codigo es 2026001. Consulta mis notas y calcula mi nota final con 4.0 en parciales y proyecto"' -ForegroundColor White
        Write-Host ""
        & uv run python -c @"
import asyncio, sys
sys.path.insert(0, 'labs/04-agent-orchestration')
from orchestrator import create_orchestrator
from contextlib import AsyncExitStack

async def main():
    async def deny(tool, args): return False
    async with AsyncExitStack() as stack:
        orch = await create_orchestrator(stack, confirm=deny)
        q = 'Mi codigo es 2026001. Consulta mis notas y luego calcula mi nota final suponiendo que saco 4.0 en los dos parciales y 4.0 en el proyecto.'
        answer = await orch.answer(q, [], 'agente')
        print(f'Pregunta: {q}')
        print(f'Respuesta: {answer.text}')
        print(f'Tools usadas: {answer.tools_used()}')
        for i, step in enumerate(answer.steps, 1):
            if step.tool_runs:
                for run in step.tool_runs:
                    result_short = run.result.replace(chr(10), ' ')[:80]
                    print(f'  Paso {i}: {run.call.name}({run.call.arguments_json}) -> {run.status}: {result_short}')
            else:
                print(f'  Paso {i}: respuesta final')
        print(f'Llamadas al LLM: {len(answer.responses)}')
        toks = sum(r.prompt_tokens + r.completion_tokens for r in answer.responses)
        print(f'Tokens totales: {toks}')

asyncio.run(main())
"@
    }
    "3" {
        Write-Host "=== PRUEBA 3: Combinar capacidades (buscar_documentos + dias_hasta) ===" -ForegroundColor Cyan
        Write-Host ""
        Write-Host 'Pregunta: "Cuantos dias faltan para el primer parcial?"' -ForegroundColor White
        Write-Host ""
        & uv run python -c @"
import asyncio, sys
sys.path.insert(0, 'labs/04-agent-orchestration')
from orchestrator import create_orchestrator
from contextlib import AsyncExitStack

async def main():
    async def deny(tool, args): return False
    async with AsyncExitStack() as stack:
        orch = await create_orchestrator(stack, confirm=deny)
        q = 'Cuantos dias faltan para el primer parcial?'
        answer = await orch.answer(q, [], 'agente')
        print(f'Pregunta: {q}')
        print(f'Respuesta: {answer.text}')
        print(f'Tools usadas: {answer.tools_used()}')
        for i, step in enumerate(answer.steps, 1):
            if step.tool_runs:
                for run in step.tool_runs:
                    result_short = run.result.replace('\n', ' ')[:80]
                    print(f'  Paso {i}: {run.call.name} -> {run.status}: {result_short}')
            else:
                print(f'  Paso {i}: respuesta final')
        print(f'Llamadas al LLM: {len(answer.responses)}')

asyncio.run(main())
"@
    }
    "4" {
        Write-Host "=== PRUEBA 4: Sin tools - Agente responde 'hola' ===" -ForegroundColor Cyan
        Write-Host ""
        & uv run python -c @"
import asyncio, sys
sys.path.insert(0, 'labs/04-agent-orchestration')
from orchestrator import create_orchestrator
from contextlib import AsyncExitStack

async def main():
    async def deny(tool, args): return False
    async with AsyncExitStack() as stack:
        orch = await create_orchestrator(stack, confirm=deny)
        answer = await orch.answer('hola', [], 'agente')
        print(f'Pregunta: hola')
        print(f'Respuesta: {answer.text}')
        print(f'Tools usadas: {answer.tools_used()}')
        print(f'Pasos: {len(answer.steps)}')
        print(f'Llamadas al LLM: {len(answer.responses)}')
        print(f'RESULTADO: Responde en un paso, sin tools' if not answer.tools_used() else 'NOTA: Uso tools')

asyncio.run(main())
"@
    }
    "5" {
        Write-Host "=== PRUEBA 5: Limite de pasos (MAX_STEPS=1) ===" -ForegroundColor Cyan
        Write-Host ""
        Write-Host 'Pregunta de nota final con MAX_STEPS=1 (se agotan los pasos)' -ForegroundColor White
        Write-Host ""
        & uv run python -c @"
import asyncio, sys
sys.path.insert(0, 'labs/04-agent-orchestration')
import agent
agent.MAX_STEPS = 1
from orchestrator import create_orchestrator
from contextlib import AsyncExitStack

async def main():
    async def deny(tool, args): return False
    async with AsyncExitStack() as stack:
        orch = await create_orchestrator(stack, confirm=deny)
        orch.agent.max_steps = 1
        orch.actions_agent.max_steps = 1
        q = 'Mi codigo es 2026001. Consulta mis notas y luego calcula mi nota final suponiendo 4.0 en parciales y proyecto.'
        answer = await orch.answer(q, [], 'agente')
        print(f'Pregunta: {q}')
        print(f'Respuesta: {answer.text}')
        print(f'stopped_by_limit: {answer.stopped_by_limit}')
        print(f'Tools usadas: {answer.tools_used()}')
        for i, step in enumerate(answer.steps, 1):
            if step.tool_runs:
                for run in step.tool_runs:
                    print(f'  Paso {i}: {run.call.name} -> {run.status}')
            else:
                print(f'  Paso {i}: respuesta final (forzada)')
        print(f'Llamadas al LLM: {len(answer.responses)}')

asyncio.run(main())
"@
    }
    "6" {
        Write-Host "=== PRUEBA 6: Router - Clasificacion de preguntas ===" -ForegroundColor Cyan
        Write-Host ""
        & uv run python -c @"
import sys
sys.path.insert(0, 'labs/04-agent-orchestration')
from config import load_settings
from llm_client import LLMClient
from router import route

llm = LLMClient(load_settings())
preguntas = [
    'hola',
    'Cuando es el primer parcial?',
    'Cuales son mis notas? Mi codigo es 2026001',
    'Cuantos dias faltan para el primer parcial?',
]
for q in preguntas:
    r = route(llm, q)
    fb = ' (RESPALDO)' if r.fallback else ''
    print(f'Pregunta: {q}')
    print(f'  Ruta: {r.decision.ruta}{fb}')
    print(f'  Motivo: {r.decision.motivo}')
    print()
"@
    }
    "7" {
        Write-Host "=== PRUEBA 7: Ruta documentos - Router mode ===" -ForegroundColor Cyan
        Write-Host ""
        Write-Host 'Pregunta: "Cual es la nota minima para aprobar el curso?"' -ForegroundColor White
        Write-Host ""
        & uv run python -c @"
import asyncio, sys
sys.path.insert(0, 'labs/04-agent-orchestration')
from orchestrator import create_orchestrator
from contextlib import AsyncExitStack

async def main():
    async def deny(tool, args): return False
    async with AsyncExitStack() as stack:
        orch = await create_orchestrator(stack, confirm=deny)
        q = 'Cual es la nota minima para aprobar el curso?'
        answer = await orch.answer(q, [], 'router')
        print(f'Pregunta: {q}')
        print(f'Ruta: {answer.routing.decision.ruta}')
        print(f'Motivo: {answer.routing.decision.motivo}')
        print(f'Respuesta: {answer.text}')
        print(f'Fuentes: {answer.sources}')
        print(f'Llamadas al LLM: {len(answer.responses)}')

asyncio.run(main())
"@
    }
    "8" {
        Write-Host "=== PRUEBA 8: Limite del router ===" -ForegroundColor Cyan
        Write-Host ""
        Write-Host 'Router con "Cuantos dias faltan para el primer parcial?" - una sola ruta' -ForegroundColor White
        Write-Host ""
        & uv run python -c @"
import asyncio, sys
sys.path.insert(0, 'labs/04-agent-orchestration')
from orchestrator import create_orchestrator
from contextlib import AsyncExitStack

async def main():
    async def deny(tool, args): return False
    async with AsyncExitStack() as stack:
        orch = await create_orchestrator(stack, confirm=deny)
        q = 'Cuantos dias faltan para el primer parcial?'
        answer_router = await orch.answer(q, [], 'router')
        print('=== Modo Router ===')
        print(f'Ruta: {answer_router.routing.decision.ruta}')
        print(f'Respuesta: {answer_router.text}')
        print(f'Tools usadas: {answer_router.tools_used()}')
        print()
        answer_agent = await orch.answer(q, [], 'agente')
        print('=== Modo Agente ===')
        print(f'Respuesta: {answer_agent.text}')
        print(f'Tools usadas: {answer_agent.tools_used()}')
        print()
        print('RESULTADO: Router toma una sola ruta (documentos o acciones), no ambas.')
        print('El agente combina buscar_documentos + dias_hasta en multiples pasos.')

asyncio.run(main())
"@
    }
    "9" {
        Write-Host "=== PRUEBA 9: Accion con confirmacion ===" -ForegroundColor Cyan
        Write-Host ""
        Write-Host 'Agente: solicitud de supletorio - confirmacion rechazada' -ForegroundColor White
        Write-Host ""
        & uv run python -c @"
import asyncio, sys
sys.path.insert(0, 'labs/04-agent-orchestration')
from orchestrator import create_orchestrator
from contextlib import AsyncExitStack

async def main():
    async def deny(tool, args):
        print(f'  [confirmacion] {tool.name}({args}) -> RECHAZADA')
        return False
    async with AsyncExitStack() as stack:
        orch = await create_orchestrator(stack, confirm=deny)
        q = 'Mi codigo es 2026001, necesito solicitar supletorio del parcial 1 por incapacidad medica'
        answer = await orch.answer(q, [], 'agente')
        print(f'Pregunta: {q}')
        print(f'Respuesta: {answer.text}')
        print(f'Tools usadas: {answer.tools_used()}')
        for i, step in enumerate(answer.steps, 1):
            for run in step.tool_runs:
                print(f'  Paso {i}: {run.call.name} -> {run.status}')
        print()
        print('RESULTADO: solicitar_supletorio fue rechazada, el agente informa al usuario')

asyncio.run(main())
"@
    }
    "10" {
        Write-Host "=== PRUEBA 10: Evaluacion (evaluate.py) ===" -ForegroundColor Cyan
        Write-Host ""
        & uv run python labs/04-agent-orchestration/evaluate.py --pausa 5
    }
    "exp1" {
        Write-Host "=== EXPERIMENTO 8.1: Conversacion con historial ===" -ForegroundColor Cyan
        Write-Host ""
        & uv run python -c @"
import asyncio, sys
sys.path.insert(0, 'labs/04-agent-orchestration')
from orchestrator import create_orchestrator
from contextlib import AsyncExitStack

async def main():
    async def deny(tool, args): return False
    async with AsyncExitStack() as stack:
        orch = await create_orchestrator(stack, confirm=deny)
        for mode in ['agente', 'router']:
            print(f'=== Modo {mode} ===')
            history = []
            q1 = 'Cuando es el primer parcial?'
            a1 = await orch.answer(q1, history, mode)
            print(f'P1: {q1}')
            print(f'R1: {a1.text}')
            print(f'Tools: {a1.tools_used()}')
            history.append({'role': 'user', 'content': q1})
            history.append({'role': 'assistant', 'content': a1.text})
            q2 = 'Y el segundo?'
            a2 = await orch.answer(q2, history, mode)
            print(f'P2: {q2}')
            print(f'R2: {a2.text}')
            print(f'Tools: {a2.tools_used()}')
            print()

asyncio.run(main())
"@
    }
    "exp2" {
        Write-Host "=== EXPERIMENTO 8.2: Lo que no se ve (nota minima sin tool) ===" -ForegroundColor Cyan
        Write-Host ""
        & uv run python -c @"
import asyncio, sys
sys.path.insert(0, 'labs/04-agent-orchestration')
from orchestrator import create_orchestrator
from contextlib import AsyncExitStack

async def main():
    async def deny(tool, args): return False
    async with AsyncExitStack() as stack:
        orch = await create_orchestrator(stack, confirm=deny)
        q = 'Cual es la nota minima para aprobar el curso?'
        answer = await orch.answer(q, [], 'agente')
        print(f'Pregunta: {q}')
        print(f'Respuesta: {answer.text}')
        print(f'Tools usadas: {answer.tools_used()}')
        print(f'Pasos: {len(answer.steps)}')
        for i, step in enumerate(answer.steps, 1):
            for run in step.tool_runs:
                print(f'  Paso {i}: {run.call.name} -> {run.status}')
            if not step.tool_runs:
                print(f'  Paso {i}: respuesta final')
        print()
        print('/tools del agente:')
        for name, tool in orch.agent.tools.items():
            print(f'  {name} ({tool.origin}): {tool.description[:60]}...')

asyncio.run(main())
"@
    }
    "exp3" {
        Write-Host "=== EXPERIMENTO 8.3: Quitar dias_hasta y preguntar ===" -ForegroundColor Cyan
        Write-Host ""
        & uv run python -c @"
import asyncio, sys
sys.path.insert(0, 'labs/04-agent-orchestration')
from tools import LOCAL_TOOLS
original = LOCAL_TOOLS.copy()
LOCAL_TOOLS[:] = [t for t in LOCAL_TOOLS if t.name != 'dias_hasta']
print('Tools disponibles (sin dias_hasta):')
for t in LOCAL_TOOLS:
    print(f'  {t.name}')

from orchestrator import create_orchestrator
from contextlib import AsyncExitStack

async def main():
    async def deny(tool, args): return False
    async with AsyncExitStack() as stack:
        orch = await create_orchestrator(stack, confirm=deny)
        q = 'Cuantos dias faltan para el primer parcial?'
        answer = await orch.answer(q, [], 'agente')
        print(f'\nPregunta: {q}')
        print(f'Respuesta: {answer.text}')
        print(f'Tools usadas: {answer.tools_used()}')
        print()
        print('RESULTADO: Sin dias_hasta, el agente busca la fecha pero no puede calcular los dias')

asyncio.run(main())
LOCAL_TOOLS[:] = original
"@
    }
    "exp4" {
        Write-Host "=== EXPERIMENTO 8.4: Accion en el ciclo (supletorio + seguimiento) ===" -ForegroundColor Cyan
        Write-Host ""
        & uv run python -c @"
import asyncio, sys
sys.path.insert(0, 'labs/04-agent-orchestration')
from orchestrator import create_orchestrator
from contextlib import AsyncExitStack

async def main():
    async def approve(tool, args):
        print(f'  [confirmacion] {tool.name}({args}) -> APROBADA')
        return True
    async with AsyncExitStack() as stack:
        orch = await create_orchestrator(stack, confirm=approve)
        history = []
        q1 = 'Mi codigo es 2026001, necesito solicitar supletorio del parcial 1 por incapacidad medica'
        a1 = await orch.answer(q1, history, 'agente')
        print(f'P1: {q1}')
        print(f'R1: {a1.text}')
        print(f'Tools: {a1.tools_used()}')
        history.append({'role': 'user', 'content': q1})
        history.append({'role': 'assistant', 'content': a1.text})
        print()
        q2 = 'Y cuando debo entregar el soporte?'
        a2 = await orch.answer(q2, history, 'agente')
        print(f'P2: {q2}')
        print(f'R2: {a2.text}')
        print(f'Tools: {a2.tools_used()}')
        print()
        print('RESULTADO: El agente combino MCP (solicitar_supletorio) + RAG (buscar_documentos) en la conversacion')

asyncio.run(main())
"@
    }
    "paso0" {
        Write-Host "=== PASO 0: Preguntas baseline con chatbot Lab 02/03 ===" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Nota: Los chatbots de Lab 02 y 03 no estan disponibles en esta sesion." -ForegroundColor Yellow
        Write-Host "Se muestra el comportamiento esperado y la limitacion de cada version:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "PREGUNTA 1: Cuando es el primer parcial?" -ForegroundColor White
        Write-Host "  Lab 02 (RAG): Puede responder (busca en documentos)"
        Write-Host "  Lab 03 (Tools+MCP): NO puede - no tiene acceso a documentos"
        Write-Host ""
        Write-Host "PREGUNTA 2: Mi codigo es 2026001, si saco 4.0 en parciales y proyecto, con cuanto quedo?" -ForegroundColor White
        Write-Host "  Lab 02 (RAG): NO puede - no tiene tools para consultar notas ni calcular"
        Write-Host "  Lab 03 (Tools+MCP): Puede (consultar_notas + calcular_nota_final) en UNA ronda"
        Write-Host ""
        Write-Host "PREGUNTA 3: Cuantos dias faltan para el primer parcial?" -ForegroundColor White
        Write-Host "  Lab 02 (RAG): Solo fecha del parcial, no sabe la fecha de hoy"
        Write-Host "  Lab 03 (Tools+MCP): Solo fecha_actual o dias_hasta, no busca en documentos"
        Write-Host ""
        Write-Host "CONCLUSION: Ninguna version anterior puede combinar RAG + Tools" -ForegroundColor Green
        Write-Host "El Lab 04 resuelve esto con el orquestador (agente o router)" -ForegroundColor Green
    }
}
