# 📘 Student Guide AI Agent

## 🚀 Project Overview
The **Student Guide AI Agent** is an AI-powered educational assistant that helps students understand complex topics in a clear, structured, and exam-ready format. Unlike traditional Q&A systems, this agent focuses on **teaching rather than just answering**.

Built using **Google ADK** and **Groq (Llama 3.3 70B)**, the system processes user queries and converts them into well-organized study notes:
- 📌 Definition
- 🔑 Key Points
- 💡 Examples
- 📝 Summary

🌐 **Live Demo** → [student-guide-ai-agent.onrender.com](https://student-guide-ai-agent.onrender.com)

## Quick Glance
<p align="center">
  <img src="Screenshots/1.png" alt="1" width="1000"/><br>
  <img src="Screenshots/2.png" alt="2" width="1000"/><br>
  <img src="Screenshots/3.png" alt="3" width="1000"/><br>
  <img src="Screenshots/4.png" alt="4" width="1000"/><br>
  <img src="Screenshots/5.png" alt="5" width="1000"/><br>
</p>

## 🎯 Problem Statement
Build and deploy a single AI agent that:
- Uses Google ADK framework
- Performs one clearly defined task (structured learning)
- Is deployed and accessible via a public URL
- Exposes functionality via an HTTP API

## 💡 Solution
The Student Guide Agent acts as a smart, always-available **tutor + note-maker**.

### Example Query
> "What is Machine Learning?"

### Output Format
- **Definition** — Clear explanation of the concept
- **Key Points** — Bullet-point breakdown
- **Examples** — Real-world applications
- **Summary** — Quick revision paragraph

## 🏗️ System Architecture

```
User Message
     ↓
Root Agent (Greeter)        ← Welcomes student, saves query
     ↓
Concept Explainer Agent     ← Explains the topic using LLM knowledge
     ↓
Study Notes Formatter       ← Formats into structured study notes
     ↓
Final Response
```

## ⚙️ Tech Stack

| Component       | Technology                  |
| --------------- | --------------------------- |
| Agent Framework | Google ADK                  |
| AI Model        | Llama 3.3 70B (via Groq)    |
| Backend         | Python 3.11                 |
| Deployment      | Render.com                  |
| Containerization| Docker                      |
| API Interface   | HTTP / SSE (ADK Web Server) |

## 📦 Features
- ✅ Accepts natural language queries
- ✅ Generates structured study notes
- ✅ Uses Llama 3.3 70B for intelligent reasoning
- ✅ Provides clear concept explanations
- ✅ Consistent output format every time
- ✅ Fast responses (Groq inference)
- ✅ Modular ADK multi-agent architecture
- ✅ Publicly deployed via Render

## 🚀 Local Setup

### Prerequisites
- Python 3.11+
- [Groq API Key](https://console.groq.com/keys) (free)

### Install & Run
```bash
# Clone the repo
git clone https://github.com/iamhriturajsaha/STUDENT-GUIDE-AI-AGENT.git
cd STUDENT-GUIDE-AI-AGENT

# Install dependencies
pip install -r requirements.txt

# Set environment variables
export GROQ_API_KEY=your_groq_api_key
export MODEL=llama-3.3-70b-versatile

# Run the ADK web server
adk web
```

Then open: `http://localhost:8080`

## 🌍 Deployment (Render.com)

1. Fork this repo
2. Create a new **Web Service** on [Render](https://render.com)
3. Connect your GitHub repo — Render auto-detects the `Dockerfile`
4. Add environment variables:
   - `GROQ_API_KEY` = your key from [console.groq.com](https://console.groq.com/keys)
   - `MODEL` = `llama-3.3-70b-versatile`
5. Click **Deploy** ✅

## 🔮 Future Enhancements
- 🎯 Adaptive learning based on student level
- 📝 Quiz generation for practice
- 📊 Progress tracking system
- 🧩 Multi-agent expansion (planner + tutor + evaluator)
- 🎙️ Voice-based interaction

## 📌 Build Criteria Alignment

| Requirement       | Status |
| ----------------- | ------ |
| ADK Used          | ✅      |
| LLM Integration   | ✅      |
| Single Task Agent | ✅      |
| HTTP Input/Output | ✅      |
| Cloud Deployment  | ✅      |

## 📢 Conclusion
The Student Guide AI Agent is a lightweight yet powerful AI system that transforms how students learn by delivering structured, easy-to-understand, and exam-ready content.
