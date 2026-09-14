from fastapi import FastAPI, Request
from pydantic import BaseModel
import sys
import os

# Add parent directory to path to import agent
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from agent import root_agent, GROQ_MODEL
from google.adk.tools.tool_context import ToolContext

app = FastAPI(title="Student Guide AI Agent")

class QueryRequest(BaseModel):
    query: str

@app.get("/")
def read_root():
    return {"message": "Welcome to the Student Guide AI Agent API."}

@app.post("/api/chat")
async def chat_endpoint(request: QueryRequest):
    # Depending on google.adk exact syntax, something like:
    try:
        # Simplistic wrapper for the root agent execution
        # A more complex adk runner might be needed depending on the SDK
        result = root_agent.run(request.query)
        return {"status": "success", "result": result}
    except Exception as e:
        return {"status": "error", "message": str(e)}
