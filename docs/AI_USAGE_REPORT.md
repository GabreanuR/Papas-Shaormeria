# AI Usage Report: Papas Shaormeria

This document outlines the extensive use of Artificial Intelligence tools throughout the Software Development Life Cycle (SDLC) of the "Papas Shaormeria" project. We adopted an **AI-first approach** to meet the requirements of the MDS laboratory.

---

## 1. Project Planning & Backlog Creation
**Tools Used:** [e.g., ChatGPT (GPT-4), Gemini Advanced, Claude 3]

We used LLMs to brainstorm game mechanics and translate them into professional agile artifacts.
* **Process:** We provided the AI with the core concept ("a shaorma shop simulator in Godot with AI agents") and asked it to generate atomic, actionable User Stories.
* **Result:** The AI successfully generated the 13 core User Stories, complete with Acceptance Criteria and Technical Tasks, which we then imported into our GitHub Projects Kanban board.
* **Example Prompt:** *"Create a user story for a drag-and-drop assembly station in a Godot 2D game. Include acceptance criteria and technical Godot nodes required."*

## 2. System Architecture & Diagrams
**Tools Used:** [e.g., ChatGPT for Mermaid.js, Eraser.io, Draw.io AI]

To design a scalable architecture before coding, we used AI to generate UML and Workflow diagrams.
* **Process:** We described the interaction between the Godot client and the local LLM endpoint to the AI and requested a sequence diagram.
* **Result:** The AI generated Mermaid.js code which we compiled into the visual diagrams stored in the `./docs/diagrams/` folder.
* **Example Prompt:** *"Write a Mermaid sequence diagram showing how the Godot HTTPRequest node sends game state data to a local Python LLM server and parses the JSON response for the Influencer Agent."*

## 3. Code Generation (Godot & GDScript)
**Tools Used:** [e.g., GitHub Copilot, Cursor IDE, ChatGPT]

A significant portion of the boilerplate code and complex GDScript logic was written with AI assistance.
* **Implementation Examples:**
  * **Drag & Drop Mechanic (US3):** AI generated the `_get_drag_data`, `_can_drop_data`, and `_drop_data` override functions.
  * **Swipe Gesture Math (US5):** We used AI to calculate the normalized vector between mouse click and release to determine the swipe direction.
  * **JSON Parsing:** AI wrote the safe parsing logic for handling LLM responses to avoid game crashes if the AI hallucinates bad formatting.

## 4. In-Game AI Agents (Core Mechanics)
**Tools Used:** [e.g., Ollama running Llama 3 8B locally, LM Studio]

The core differentiator of our game is the integration of live AI agents.
* **Agent 1: The Loyal Customer (Contextual Memory)**
  * **Implementation:** We pass a JSON array of the last 3 days' interactions into the system prompt.
  * **System Prompt Used:** *"[Insert your exact prompt here, e.g., 'You are a recurring customer at a fast food shop. Here is your history: {history}. React to today's service.']"*
* **Agent 2: The Influencer (JSON Structured Output)**
  * **Implementation:** We used strict prompting to force the local LLM to output only valid JSON.
  * **System Prompt Used:** *"[Insert your exact prompt here, e.g., 'Review this shaorma recipe: {ingredients}. Output strictly in JSON format: {"review": "...", "trend_ingredient": "..."}']"*

## 5. Automated Testing & AI Evals
**Tools Used:** [e.g., ChatGPT, Copilot]

* **Godot Unit Tests (GUT):** We used Copilot to quickly generate unit tests for our scoring logic and shop math (US8).
* **AI Evals:** We created an automated script that sends 10 mock requests to our local LLM to test if it consistently returns the correct JSON structure for the Influencer Agent, achieving a [X]% success rate during testing.

## 6. Asset Generation (Art & Audio)
**Tools Used:** [e.g., Midjourney, DALL-E 3, ElevenLabs, Suno]

* **2D Graphics:** The sprites for the ingredients, the wrap, and the UI elements were generated using AI image generators, ensuring a cohesive art style without needing a dedicated 2D artist.
* **Audio:** SFX like the sizzling meat and UI clicks were sourced or synthesized using AI audio tools.

## 7. DevOps & CI/CD Pipeline
**Tools Used:** [e.g., ChatGPT]

* **Process:** We needed a GitHub Actions pipeline to automatically build the Godot project for Windows and Web. We used AI to write the `.yml` workflow file.
* **Result:** A fully functional CI/CD pipeline that runs tests and creates artifacts on every push to the `main` branch.
