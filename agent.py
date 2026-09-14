import os
import logging
from dotenv import load_dotenv
from google.adk import Agent
from google.adk.agents import SequentialAgent
from google.adk.models.lite_llm import LiteLlm
from google.adk.tools.tool_context import ToolContext

# Setup Logging and Environment
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)
load_dotenv()

# Use Groq via LiteLLM (free tier: 14,400 req/day)
GROQ_MODEL = LiteLlm(model=f"groq/{os.getenv('MODEL', 'llama-3.3-70b-versatile')}")

# Custom Tools
def save_student_query(
    tool_context: ToolContext, query: str
) -> dict[str, str]:
    """
    Saves the student's question/topic into the shared state.
    CRITICAL: DO NOT use this tool for basic greetings like 'hello' or 'hi'. Only use for actual study topics.
    """
    tool_context.state["STUDENT_QUERY"] = query
    logging.info(f"[State updated] STUDENT_QUERY: {query}")
    return {"status": "saved"}

# Agent Definitions
# 1. Concept Explainer Agent
concept_explainer = Agent(
    name="concept_explainer",
    model=GROQ_MODEL,
    description="Explains academic concepts clearly using built-in knowledge.",
    instruction="""
    Your name is Elena, an expert teacher and academic guide with deep knowledge across all subjects.
    Your goal is to explain the STUDENT_QUERY clearly and thoroughly using your knowledge.
    Steps:
    1. Understand the STUDENT_QUERY.
    2. Break the concept into simple, clear explanations.
    3. Provide real-world examples where possible.
    4. Keep the explanation student-friendly and engaging.
    STUDENT_QUERY:
    { STUDENT_QUERY }
    """,
    output_key="concept_data"
)

# 2. Study Notes Formatter Agent
study_notes_formatter = Agent(
    name="study_notes_formatter",
    model=GROQ_MODEL,
    description="Formats explanations into structured study notes.",
    instruction="""
    Your name is Elena, a professional academic tutor.
    Convert the CONCEPT_DATA into well-structured study material.
    Format:
    - Definition
    - Key Points
    - Examples
    - Summary
    Use clear and concise language suitable for students.
    CONCEPT_DATA:
    { concept_data }
    """
)

# Workflow Setup
student_learning_workflow = SequentialAgent(
    name="student_learning_workflow",
    description="Handles student queries and converts them into structured learning content.",
    sub_agents=[
        concept_explainer,
        study_notes_formatter
    ]
)

# Root Agent
root_agent = Agent(
    name="student_guide_greeter",
    model=GROQ_MODEL,
    description="Main entry point for the Student Guide System.",
    instruction="""
    Your name is Elena, a friendly and supportive Student Guide AI.
    
    RULE 1 - GREETINGS: If the user says a greeting (e.g., 'hello', 'hi', 'hey'):
    - Reply directly with a warm welcome and ask what they want to learn.
    - DO NOT call any tools. DO NOT transfer control.
    
    RULE 2 - STUDY TOPICS: If the user provides a study topic or question:
    - First, call 'save_student_query' to store their topic.
    - Then, transfer control to 'student_learning_workflow'.
    """,
    tools=[save_student_query],
    sub_agents=[student_learning_workflow]
)
