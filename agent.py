import os
import logging
import google.cloud.logging
from dotenv import load_dotenv
from google.adk import Agent
from google.adk.agents import SequentialAgent
from google.adk.tools.tool_context import ToolContext
from google.adk.tools.langchain_tool import LangchainTool
from langchain_community.tools import WikipediaQueryRun
from langchain_community.utilities import WikipediaAPIWrapper

# Setup Logging and Environment
cloud_logging_client = google.cloud.logging.Client()
cloud_logging_client.setup_logging()
load_dotenv()
model_name = os.getenv("MODEL")

# Custom Tools 
def save_student_query(
    tool_context: ToolContext, query: str
) -> dict[str, str]:
    """
    Saves the student's question/topic into the shared state.
    """
    tool_context.state["STUDENT_QUERY"] = query
    logging.info(f"[State updated] STUDENT_QUERY: {query}")
    return {"status": "saved"}

# Wikipedia tool for academic explanations
wikipedia_tool = LangchainTool(
    tool=WikipediaQueryRun(api_wrapper=WikipediaAPIWrapper())
)

# Agent Definitions 
# 1. Concept Explainer Agent
concept_explainer = Agent(
    name="concept_explainer",
    model=model_name,
    description="Explains academic concepts using external knowledge sources.",
    instruction="""
    You are an expert teacher and academic guide.

    Your goal is to explain the STUDENT_QUERY clearly and thoroughly.

    You have access to:
    - Wikipedia tool for general knowledge and definitions.

    Steps:
    1. Understand the STUDENT_QUERY.
    2. If needed, use Wikipedia to gather accurate information.
    3. Break the concept into simple explanations.
    4. Provide examples where possible.
    5. Keep the explanation student-friendly.

    STUDENT_QUERY:
    { STUDENT_QUERY }
    """,
    tools=[wikipedia_tool],
    output_key="concept_data"
)

# 2. Study Notes Formatter Agent
study_notes_formatter = Agent(
    name="study_notes_formatter",
    model=model_name,
    description="Formats explanations into structured study notes.",
    instruction="""
    You are a professional academic tutor.

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
    model=model_name,
    description="Main entry point for the Student Guide System.",
    instruction="""
    - Welcome the student warmly.
    - Ask what topic or question they need help with.
    - When the student provides a query:
        1. Use 'save_student_query' tool to store it.
        2. Then transfer control to 'student_learning_workflow'.

    Keep tone friendly, encouraging, and supportive.
    """,
    tools=[save_student_query],
    sub_agents=[student_learning_workflow]
)
