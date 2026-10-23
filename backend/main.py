"""
Backend FastAPI + Gemini 1.5 Flash para RumiArt IA.
Deploy en Render. La API key vive SOLO en las variables de entorno del servidor.

Endpoints:
  GET  /        → health check básico
  GET  /health  → health check detallado
  POST /chat    → asistente IA sobre obras del museo
"""
import os
import json
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import google.generativeai as genai
import uvicorn

# ── Configuración ──────────────────────────────────────────────────────────────
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "")

app = FastAPI(
    title="RumiArt IA Backend",
    description="Asistente IA para el Museo y Centro Cultural Rumiñahui",
    version="1.0.0",
)

# CORS — permite todas las origenes (la app Flutter hace las peticiones)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Inicializar Gemini si hay API key
model = None
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)
    model = genai.GenerativeModel("gemini-1.5-flash")


# ── Schemas ────────────────────────────────────────────────────────────────────
class ChatRequest(BaseModel):
    message: str
    context: str = ""
    history: list = []


# ── Endpoints ──────────────────────────────────────────────────────────────────
@app.get("/")
def root():
    return {"status": "ok", "service": "RumiArt IA Backend", "version": "1.0.0"}


@app.get("/health")
def health():
    return {
        "status": "healthy",
        "gemini_configured": bool(GEMINI_API_KEY),
    }


@app.post("/chat")
async def chat(request: ChatRequest):
    """
    Recibe un mensaje del usuario y retorna la respuesta del asistente IA.
    El campo 'context' contiene info de la obra reconocida actualmente.
    El campo 'history' contiene los últimos mensajes de la conversación.
    """
    if not GEMINI_API_KEY or model is None:
        raise HTTPException(
            status_code=503,
            detail="El servicio de IA no está configurado. Contacta al administrador.",
        )

    # Construir el prompt del sistema
    system_context = (
        "Eres un guía experto y amigable del Museo y Centro Cultural Rumiñahui, "
        "ubicado en Sangolquí, Ecuador. Tu nombre es RumiArt IA. "
        "Respondes SIEMPRE en español, de manera educativa, clara y entusiasta. "
        "Tienes conocimiento profundo sobre las 6 salas del museo: "
        "Primeros Pobladores, La Colonia, La Independencia, El Maíz, "
        "Plástica Ecuatoriana y La Cantonización. "
        "Cuando no sepas algo, lo admites honestamente y sugieres preguntar al personal del museo."
    )

    if request.context:
        system_context += f"\n\nContexto de la obra que el visitante está observando ahora:\n{request.context}"

    # Construir el historial de conversación
    history_text = ""
    if request.history:
        recent = request.history[-6:]  # últimos 6 mensajes
        for msg in recent:
            role = "Visitante" if msg.get("role") == "user" else "RumiArt IA"
            history_text += f"{role}: {msg.get('content', '')}\n"

    # Prompt completo
    full_prompt = f"{system_context}\n\n"
    if history_text:
        full_prompt += f"Conversación previa:\n{history_text}\n"
    full_prompt += f"Visitante: {request.message}\nRumiArt IA:"

    try:
        response = model.generate_content(
            full_prompt,
            generation_config=genai.types.GenerationConfig(
                max_output_tokens=500,
                temperature=0.7,
            ),
        )
        reply = response.text.strip()
        return {"reply": reply}

    except Exception as e:
        error_msg = str(e).lower()
        if "quota" in error_msg or "rate" in error_msg:
            raise HTTPException(
                status_code=429,
                detail="El asistente está ocupado. Intenta de nuevo en unos momentos.",
            )
        raise HTTPException(
            status_code=500,
            detail="Error al procesar tu consulta. Intenta de nuevo.",
        )


# ── Entry point ────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
