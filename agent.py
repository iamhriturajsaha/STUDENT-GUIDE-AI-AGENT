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

# Use Gemini via LiteLLM
GEMINI_MODEL = LiteLlm(model=f"gemini/{os.getenv('MODEL', 'gemini-2.5-flash')}")

# No custom tools needed; relying on conversation history.

# Agent Definitions
# 1. Concept Explainer Agent
concept_explainer = Agent(
    name="concept_explainer",
    model=GEMINI_MODEL,
    description="Explains academic concepts clearly using built-in knowledge.",
    instruction="""
    Your name is Elena, an expert teacher and academic guide with deep knowledge across all subjects.
    Your goal is to explain the user's requested topic clearly and thoroughly using your knowledge.
    Steps:
    1. Look at the user's latest message to understand what they want to learn.
    2. Break the concept into simple, clear explanations.
    3. Provide real-world examples where possible.
    4. Keep the explanation student-friendly and engaging.
    """,
    output_key="concept_data"
)

# 2. Study Notes Formatter Agent
study_notes_formatter = Agent(
    name="study_notes_formatter",
    model=GEMINI_MODEL,
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

# 3. Greeting Agent
greeting_agent = Agent(
    name="greeting_agent",
    model=GEMINI_MODEL,
    description="Handles basic greetings.",
    instruction="""
    Your name is Elena, a friendly and supportive Student Guide AI.
    The user just greeted you. Warmly welcome them, introduce yourself as Elena, and ask what topic they would like to learn about today.
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
    model=GEMINI_MODEL,
    description="Main entry point for the Student Guide System.",
    instruction="""
    Your name is Elena, a friendly and supportive Student Guide AI.
    
    RULE 1 - GREETINGS: If the user says a greeting (e.g., 'hello', 'hi', 'hey'):
    - Transfer control to 'greeting_agent'.
    
    RULE 2 - STUDY TOPICS: If the user provides a study topic or question:
    - Transfer control to 'student_learning_workflow'.
    """,
    tools=[],
    sub_agents=[student_learning_workflow, greeting_agent]
)
