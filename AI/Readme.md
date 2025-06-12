# Top Open Source Software (OSS) Agentic AI Projects:

•	[Autogpt](https://github.com/Significant-Gravitas/AutoGPT)

•	[Langchain](https://github.com/langchain-ai/langchain)

•	[Autogen](https://github.com/microsoft/autogen) |  is a framework for creating multi-agent AI applications that can act autonomously or work alongside humans.

•	[Haystack](https://github.com/deepset-ai/haystack) | Developers needing full control over NLP/RAG applications

•	[Crewai](https://github.com/crewAIInc/crewAI)

•	[Flowise](https://github.com/FlowiseAI/Flowise)  | Non-developers, fast prototyping, building simple LLM agents


•	[Continue](https://github.com/continuedev/continue) | enables developers to create, share, and use custom AI code assistants
•	[Openhands](https://github.com/All-Hands-AI/OpenHands) | a platform for software development agents powered by AI.
•	[Dspy](https://github.com/stanfordnlp/dspy)
•	[Milvus](https://github.com/milvus-io/milvus) | is a high-performance vector database built for scale

### Tool overview

| Tool          | Core Purpose                                          |
| ------------- | ----------------------------------------------------- |
| **LangGraph** | Graph-based LLM state machines (multi-agent + memory) |
| **Flowise**   | Visual builder for LLM workflows (no-code/low-code)   |
| **Haystack**  | Full NLP pipeline builder, focused on RAG + search    |
| **CrewAI**    | Multi-agent framework with roles and collaboration    |
| **AutoGen**   | Microsoft’s multi-agent framework with control loop   |

### Use cases

| Use Case                                                 | **LangGraph**       | **Flowise**       | **Haystack**        | **CrewAI**           | **AutoGen**         |
| -------------------------------------------------------- | ------------------- | ----------------- | ------------------- | -------------------- | ------------------- |
| **1. RAG chatbot for internal documents**                | ✅ Complex flow      | ✅ Easy UI         | ✅ Excellent         | ⚠️ Overkill          | ⚠️ Not ideal        |
| **2. Visual chatbot with file upload**                   | ❌ No UI             | ✅ Yes             | ⚠️ Requires code    | ❌ No UI              | ❌ No UI             |
| **3. Autonomous research assistant**                     | ✅ With agents       | ⚠️ Limited        | ⚠️ Needs extensions | ✅ Good fit           | ✅ Ideal             |
| **4. AI team with specialist roles (e.g., CEO, coder)**  | ✅ Graph-based       | ❌ No agent model  | ❌ Not suitable      | ✅ Designed for it    | ✅ Best fit          |
| **5. Conversational QA over PDFs/knowledge base**        | ✅ Multi-step        | ✅ Very easy       | ✅ Native            | ⚠️ Overkill          | ⚠️ Needs tweaking   |
| **6. Tool-using agent (e.g., planner with calculator)**  | ✅ Built-in          | ✅ LangChain tools | ✅ With plugins      | ✅ Agents use tools   | ✅ Very flexible     |
| **7. Developer co-pilot with planning + coding agents**  | ✅ With LLM calls    | ❌ Not ideal       | ❌ Not suitable      | ⚠️ Okay              | ✅ Excellent         |
| **8. Multi-turn task delegation (write → review → fix)** | ✅ Modeled as states | ❌ Sequential only | ❌ Not agent-based   | ✅ Natural fit        | ✅ Native feature    |
| **9. Graph of LLM functions with memory at each node**   | ✅ Core design       | ❌ Flat flow       | ❌ Limited           | ❌ No graph structure | ⚠️ Needs workaround |
| **10. Production-ready enterprise NLP search**           | ⚠️ Early-stage      | ⚠️ Hobby-grade    | ✅ Very strong       | ❌ Not meant for this | ❌ Not suitable      |



## [Haystack](https://github.com/deepset-ai/haystack)

Haystack is toolbox for building smart AI apps that understand and work with text. 
It helps you connect different tools (like AI models, databases, and readers) to create powerful applications like chatbots, search engines or question-answering systems.
### Key Parts
 - Components : These are like Lego Blocks (eg. AI models, Databases, file readers)
 - PipelinesAgents: You connects these blocks to make a working system
 - Retrieval methods = helps the system find the best answers from the data

### Example
Imagine you own a website, and customers keep asking the same questions 'What is your return policy?'.
Instead of answering manually, you can build a chatbot with Haystack:
- Store FAQs - Save your FAQs in a database (like a smart notebook that remembers everything)
- Ask a Question - When a user asks "How do I return a product?", Haystack:
  - Search the database (retrival)
  - Picks the best answer using an AI model.
- Get the answer - The chatbot replied: "You can return within 7 days with a receipt"

Notes:
Haystack isnt omniscient - it only knows what you teach it (via tables/files/models)



| Feature        | **Flowise**                           | **Haystack**                                    | **CreawAI**                                 | **Autogen**                          | **LangGraph**                               |
| -------------- | ------------------------------------- | ----------------------------------------------- | --------------------------------------------| -------------------------------------| ------------------------------------------- |
| **Type**       | Visual LLM app builder                | RAG/QA Pipeline Framework                       | Multi-agent Orchestration                   | Multi-agent conversational framework | Statetful worktflow builder                 |
| **Focus**      | No-code/low-code workflows for LLMs   | Developer-focused LLM pipelines and RAG systems | Autonomous multi-agent task execution       |
| **Main Use**   | Drag-and-drop to create LLM workflows | Build robust, scalable LLM apps (e.g. RAG, QA)  | Agent orchestration for task-based teamwork |
| **Built With** | Node.js                               | Python                                          | Python codebase (developer focused)         |


###  Example use cases

| Use Case                                   | **Flowise**                    | **Haystack**          | **CrewAI**                                 |**CrewAI**                                 |
| ------------------------------------------ | ------------------------------ | --------------------- | ------------------------------------------ | ------------------------------------------ |
| Chatbot for documents (PDF's)              | ✅ Drag and drop nodes        |  ✅ Load docs-embed-retrieve-llm | Very easy to build | ⚠️ Requires custom work                    |
| Build an AI customer service team          | ❌ Not suitable       | ❌ Not suitable       | ✅ Ideal (multiple agents: greeter, expert) |

