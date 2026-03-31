# 🛠️ Contributing to Papas Shaormeria

Welcome to the development team! (Amelia, Bianca, Maia, and Razvan). 
This document outlines the standard workflow we will use to build our game for the Software Development Methods (MDS) lab. Please read this carefully to ensure our environments match and we avoid Git merge conflicts.

---

## 1. Local Environment Setup

To run the project and the AI features correctly, you must have the following installed:

### A. Godot Engine
* **Version:** Godot 4.x **Standard** (Do NOT download the .NET version).
* **Setup:** Download the executable from [godotengine.org](https://godotengine.org/download/), extract it, and open `project.godot` from this repository.

### NU FACEM B (INCA)

### B. Local AI (LLM) Setup
Since our game relies on local AI Agents, your machine needs to run a local server during gameplay.
* **Tool:** Install **Ollama** (or LM Studio).
* **Model:** We are standardizing on `llama3` (or specify another model here, e.g., `mistral`). 
* **Command:** Open your terminal and run `ollama run llama3` before hitting "Play" in Godot.
* **Port:** Ensure your local AI server is running on the default port `localhost:11434`, as the Godot `HTTPRequest` nodes are hardcoded to hit this endpoint.

---

## 2. Git Workflow & Rules

To meet the lab requirements (branch creation, PRs, minimum 5 commits per student), we follow a strict branch-based workflow. **Do not push directly to the `main` branch!**

### Step-by-Step Process:
1. **Pick an Issue:** Go to the GitHub Projects (Kanban board) and assign yourself a User Story from the **To Do** column. Move it to **In Progress**.
2. **Create a Branch:** From your local `main` branch, pull the latest changes, then create a new branch named after your task:
   * Format: `type/issue-number-short-desc`
   * Examples: `feature/US1-order-intake`, `bugfix/US7-json-parse-error`
3. **Write Code & Commit:** Work in Godot. Make small, frequent commits. 
   * *Reminder: Every student must have at least 5 meaningful commits over the course of the project.*
   * Commit message format: `[US#] Brief description of what changed`. (e.g., `[US2] Added perfect cut detection logic`).
4. **Push & Pull Request (PR):** Push your branch to GitHub and open a Pull Request against `main`. 
5. **Code Review:** Tag at least one teammate to review your PR. Once approved, you can merge it. Move your Kanban card to **Done**.

---

## 3. Godot Best Practices

* **.gitignore:** Never remove or modify the `.gitignore` file. It prevents the `.godot/` cache folder from being uploaded, which would cause massive merge conflicts.
* **Scene Organization:** Do not build the entire game in a single scene. Each User Story (like the Cutting Station or the Wrap Area) should be its own `.tscn` file, which we will later instance into the main game level.
* **AI Tooling:** Remember our *AI-first* rule. If you use ChatGPT, Copilot, or Cursor to generate a GDScript, save the prompt and add it to our `./docs/AI_USAGE_REPORT.md` file before you open your PR.

Happy coding! 🌯
