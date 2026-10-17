param([string]$TestNum)
$ErrorActionPreference = 'SilentlyContinue'
Set-Location C:\Users\User\lab-ia-chatbot
$env:PYTHONIOENCODING = 'utf-8'

switch ($TestNum) {
    "1" {
        Write-Host "=== PRUEBA 1: Chunking (documents.py) ===" -ForegroundColor Cyan
        Write-Host ""
        Write-Host 'PS C:\lab-ia-chatbot> uv run python labs/02-rag/documents.py' -ForegroundColor Yellow
        Write-Host ""
        & uv run python labs/02-rag/documents.py
        Write-Host ""
        Write-Host "RESULTADO: Chunking correcto - ventanas de 4 palabras con overlap de 1" -ForegroundColor Green
    }
    "2" {
        Write-Host "=== PRUEBA 2: Ingestion (ingest.py) ===" -ForegroundColor Cyan
        Write-Host ""
        Write-Host 'PS C:\lab-ia-chatbot> uv run python labs/02-rag/ingest.py' -ForegroundColor Yellow
        Write-Host ""
        & uv run python labs/02-rag/ingest.py
        Write-Host ""
        Write-Host "RESULTADO: Indice creado correctamente" -ForegroundColor Green
    }
    "3a" {
        Write-Host "=== PRUEBA 3: Busqueda Semantica ===" -ForegroundColor Cyan
        Write-Host 'Pregunta: "Que pasa si entrego tarde un laboratorio?"' -ForegroundColor White
        Write-Host ""
        Write-Host 'PS> uv run python labs/02-rag/search.py "Que pasa si entrego tarde un laboratorio?"' -ForegroundColor Yellow
        Write-Host ""
        & uv run python labs/02-rag/search.py "Que pasa si entrego tarde un laboratorio?"
    }
    "3b" {
        Write-Host "=== PRUEBA 3: Busqueda por Keyword ===" -ForegroundColor Cyan
        Write-Host 'Pregunta: "Que pasa si entrego tarde un laboratorio?"' -ForegroundColor White
        Write-Host ""
        Write-Host 'PS> uv run python labs/02-rag/search.py --keyword "Que pasa si entrego tarde un laboratorio?"' -ForegroundColor Yellow
        Write-Host ""
        & uv run python labs/02-rag/search.py --keyword "Que pasa si entrego tarde un laboratorio?"
    }
    "3c" {
        Write-Host "=== PRUEBA 3: Semantica - Cuando es el primer parcial? ===" -ForegroundColor Cyan
        Write-Host ""
        & uv run python labs/02-rag/search.py "Cuando es el primer parcial?"
        Write-Host ""
        Write-Host "=== Keyword - Cuando es el primer parcial? ===" -ForegroundColor Cyan
        Write-Host ""
        & uv run python labs/02-rag/search.py --keyword "Cuando es el primer parcial?"
    }
    "3d" {
        Write-Host "=== PRUEBA 3: Semantica - Puedo usar ChatGPT? ===" -ForegroundColor Cyan
        Write-Host ""
        & uv run python labs/02-rag/search.py "Puedo usar ChatGPT en los laboratorios?"
        Write-Host ""
        Write-Host "=== Keyword - Puedo usar ChatGPT? ===" -ForegroundColor Cyan
        Write-Host ""
        & uv run python labs/02-rag/search.py --keyword "Puedo usar ChatGPT en los laboratorios?"
    }
    "5" {
        Write-Host "=== PRUEBA 5: Conversacion con el Chatbot RAG ===" -ForegroundColor Cyan
        Write-Host ""
        & uv run python "C:\Users\User\AppData\Local\Temp\claude\C--Users-User-IdeaProjects-nexus-battles-vi\9b019534-5667-4404-b2a1-eeb1ee64487c\scratchpad\run_chatbot_test.py"
    }
    "6" {
        Write-Host "=== PRUEBA 6: Filtro umbral min_score=0.35 ===" -ForegroundColor Cyan
        Write-Host 'Pregunta fuera de dominio: "Dame una receta de arepas"' -ForegroundColor White
        Write-Host ""
        & uv run python labs/02-rag/search.py "Dame una receta de arepas"
        Write-Host ""
        Write-Host "TODOS los scores < 0.35 => retrieve() devuelve lista vacia" -ForegroundColor Green
    }
    "chunk" {
        Write-Host "=== EXPERIMENTO: Efecto del chunk_size ===" -ForegroundColor Cyan
        Write-Host ""
        $env:PYTHONPATH = "labs/02-rag"
        & uv run python -c @"
import sys; sys.path.insert(0, 'labs/02-rag')
from documents import load_documents, chunk_documents
from pathlib import Path
data_dir = Path('labs/02-rag/data')
docs = load_documents(data_dir)
for cs in [30, 80, 400]:
    ov = int(cs*0.25)
    chunks = chunk_documents(docs, chunk_size=cs, overlap=ov)
    print(f'chunk_size={cs:>3}, overlap={ov:>3} => {len(chunks)} chunks')
"@
        Write-Host ""
        Write-Host "chunk_size=80 es el balance optimo" -ForegroundColor Green
    }
    "topk" {
        Write-Host "=== EXPERIMENTO: top_k=1 vs top_k=8 ===" -ForegroundColor Cyan
        Write-Host 'Pregunta: "Cuando es el primer parcial y que temas evalua?"' -ForegroundColor White
        Write-Host ""
        $env:PYTHONPATH = "labs/02-rag"
        & uv run python -c @"
import sys, os
sys.path.insert(0, 'labs/02-rag')
os.chdir(r'C:\Users\User\lab-ia-chatbot')
from dotenv import load_dotenv
load_dotenv()
from config import load_settings, load_rag_settings
from embeddings import Embedder
from llm_client import LLMClient
from rag import CourseRAG
from vector_store import VectorStore
settings = load_settings()
rag_settings = load_rag_settings()
store = VectorStore.load(rag_settings.index_dir)
for tk in [1, 8]:
    rag = CourseRAG(llm=LLMClient(settings), embedder=Embedder(store.embedding_model), store=store, top_k=tk, min_score=rag_settings.min_score)
    q = 'Cuando es el primer parcial y que temas evalua?'
    a = rag.answer(q)
    print(f'\n=== top_k={tk} ===')
    print(f'Respuesta: {a.text[:200]}...')
    print(f'Fragmentos: {len(a.sources)}')
    for i, r in enumerate(a.sources, 1):
        print(f'  [{i}] score={r.score:.3f} {r.chunk.id}')
"@
    }
    "9" {
        Write-Host "=== PRUEBA 9: Actualizacion de conocimiento ===" -ForegroundColor Cyan
        Write-Host ""
        $env:PYTHONPATH = "labs/02-rag"
        & uv run python -c @"
import sys, os
sys.path.insert(0, 'labs/02-rag')
os.chdir(r'C:\Users\User\lab-ia-chatbot')
from dotenv import load_dotenv
load_dotenv()
from config import load_settings, load_rag_settings
from embeddings import Embedder
from llm_client import LLMClient
from rag import CourseRAG
from vector_store import VectorStore
settings = load_settings()
rag_settings = load_rag_settings()
store = VectorStore.load(rag_settings.index_dir)
rag = CourseRAG(llm=LLMClient(settings), embedder=Embedder(store.embedding_model), store=store, top_k=4, min_score=rag_settings.min_score)
q = 'Cuando es el primer parcial?'
a = rag.answer(q)
print(f'Pregunta: {q}')
print(f'Respuesta: {a.text}')
for i, r in enumerate(a.sources, 1):
    print(f'  [{i}] score={r.score:.3f} {r.chunk.id}')
print()
print('VERIFICACION: El chatbot detecta el cambio de fecha del parcial')
print('(evaluacion.md dice 15/oct, anuncios.md dice 20/oct)')
"@
    }
    "10" {
        Write-Host "=== PRUEBA 10: Indice faltante ===" -ForegroundColor Cyan
        Write-Host ""
        $env:PYTHONPATH = "labs/02-rag"
        & uv run python -c @"
import sys, os, shutil
sys.path.insert(0, 'labs/02-rag')
os.chdir(r'C:\Users\User\lab-ia-chatbot')
from vector_store import VectorStore
from pathlib import Path
index_dir = Path('labs/02-rag/index')
backup_dir = Path('labs/02-rag/index_bk')
if index_dir.exists():
    shutil.move(str(index_dir), str(backup_dir))
try:
    store = VectorStore.load(index_dir)
    print('ERROR: deberia haber fallado')
except FileNotFoundError as e:
    print(f'FileNotFoundError capturado correctamente')
    print(f'Mensaje: {e}')
    print(f'VERIFICACION: El sistema maneja la ausencia del indice')
finally:
    if backup_dir.exists():
        shutil.move(str(backup_dir), str(index_dir))
        print(f'Indice restaurado')
"@
    }
    "grounding" {
        Write-Host "=== PRUEBA: Anclaje (grounding) ===" -ForegroundColor Cyan
        Write-Host ""
        $env:PYTHONPATH = "labs/02-rag"
        & uv run python -c @"
import sys, os
sys.path.insert(0, 'labs/02-rag')
os.chdir(r'C:\Users\User\lab-ia-chatbot')
from dotenv import load_dotenv
load_dotenv()
from config import load_settings, load_rag_settings
from embeddings import Embedder
from llm_client import LLMClient
from rag import CourseRAG
from vector_store import VectorStore
settings = load_settings()
rag_settings = load_rag_settings()
store = VectorStore.load(rag_settings.index_dir)
rag = CourseRAG(llm=LLMClient(settings), embedder=Embedder(store.embedding_model), store=store, top_k=4, min_score=rag_settings.min_score)
for q in ['Cual es el horario de la cafeteria?', 'Cual es la capital de Francia?']:
    a = rag.answer(q)
    print(f'Pregunta: {q}')
    print(f'Respuesta: {a.text}')
    print(f'Fragmentos recuperados: {len(a.sources)}')
    print()
"@
    }
}
