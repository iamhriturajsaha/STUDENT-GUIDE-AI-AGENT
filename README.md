# 🎓Student Guide AI Agent

An intelligent study companion that transforms questions into structured learning notes — powered by Google ADK and Gemini, deployed on Cloud Run.

**Live endpoint -** `https://student-guide-315961907444.europe-west1.run.app` 

## Overview

The Student Guide AI Agent is a production-ready AI system that acts as a smart tutor. Rather than returning raw answers, it teaches concepts by organizing responses into a consistent, exam-ready format -

| Section | Purpose |
|---|---|
| 📖 **Definition** | Core concept explained simply |
| 🔑 **Key Points** | Essential facts to remember |
| 💡 **Examples** | Real-world illustrations |
| 📝 **Summary** | Quick revision takeaway |

## Architecture

```
User Query
   │
   ▼
Root Agent (Controller)
   │
   ├─▶ Save Query Tool
   │
   ▼
Concept Explainer Agent
   ├── Gemini 2.5 Flash (reasoning)
   └── Wikipedia Tool (factual grounding)
   │
   ▼
Study Notes Formatter Agent
   │
   ▼
Structured Output (Definition · Key Points · Examples · Summary)
```

### Agent Roles

**Root Agent -** Entry point. Handles user input and routes tasks through the workflow.

**Concept Explainer Agent -** Uses Gemini for reasoning and Wikipedia for factual grounding to generate clear, accurate explanations.

**Study Notes Formatter Agent -** Converts raw explanations into consistently structured study notes.


## Tech Stack

| Technology | Role |
|---|---|
| Google ADK `1.14.0` | Agent orchestration |
| Gemini `gemini-2.5-flash` | LLM inference |
| Cloud Run | Serverless deployment |
| Python | Core language |
| Wikipedia API (LangChain) | External knowledge retrieval |
| Docker | Containerization |
| Cloud Logging | Monitoring |

## Project Structure

```
.
├── agent.py           # ADK agent workflow definition
├── __init__.py        # Package initialization
├── requirements.txt   # Python dependencies
├── .env               # Environment variables (not committed)
└── README.md
```

## Setup & Deployment

### 1. Environment Variables

Create a `.env` file in the project root -

```env
PROJECT_ID=your-project-id
PROJECT_NUMBER=your-project-number
SA_NAME=your-service-account-name
SERVICE_ACCOUNT=your-service-account-email
MODEL=gemini-2.5-flash
```

### 2. Load Environment

```bash
source .env
```

### 3. Create Service Account

```bash
gcloud iam service-accounts create ${SA_NAME} \
  --display-name="Service Account for Student Guide Agent"
```

### 4. Grant Permissions

```bash
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/aiplatform.user"
```

### 5. Deploy to Cloud Run

```bash
uvx --from google-adk==1.14.0 \
adk deploy cloud_run \
  --project=$PROJECT_ID \
  --region=europe-west1 \
  --service_name=student-guide \
  --with_ui \
  . \
  -- \
  --labels=dev-tutorial=codelab-adk \
  --service-account=$SERVICE_ACCOUNT
```

## API Reference

### `POST /invoke`

**Request**
```json
{
  "query": "What is Machine Learning?"
}
```

**Response**
```json
{
  "definition": "Machine learning is a subset of AI...",
  "key_points": [
    "Models learn patterns from data",
    "Three main types: supervised, unsupervised, reinforcement"
  ],
  "examples": [
    "Email spam filters",
    "Product recommendation engines"
  ],
  "summary": "ML enables systems to learn and improve from experience without being explicitly programmed."
}
```

## Dependencies

```
google-adk==1.14.0
langchain-community==0.3.27
wikipedia==1.4.0
```

## Troubleshooting

| Issue | Resolution |
|---|---|
| `Permission denied` | Re-run the IAM role binding in Step 4 |
| Model error | Verify `MODEL` value in `.env` |
| Deployment failure | Confirm the target region is supported |
| `403` on API call | Validate the service account email is correct |

## Roadmap

- Quiz generation from study notes.
- Adjustable explanation depth (beginner / intermediate / advanced).
- Multi-turn tutoring sessions.
- Voice input and output.
- Progress tracking across topics.
