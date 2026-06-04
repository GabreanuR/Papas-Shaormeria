# 🛠️ Contributing to Papas Shaormeria

Welcome to the development team! (Amelia, Bianca, Maia, and Razvan). 
This document outlines the standard workflow we use to build our game for the Software Development Methods (MDS) lab. Please read this carefully to ensure our environments match and we avoid Git merge conflicts.

---

## 1. Local Environment Setup

To run the project correctly, you must have the following installed:

### A. Godot Engine
* **Version:** Godot **4.3 Standard** (Do NOT download the .NET version).
* **Setup:** Download the executable from [godotengine.org](https://godotengine.org/download/), extract it, and open `project.godot` from this repository.

### B. Local AI (Ollama + Llama 3.2)
The game's AI agents require a locally running LLM. To set it up:
1. **Install Ollama:** Download from [ollama.ai](https://ollama.ai) and install it.
2. **Pull the model:**
   ```bash
   ollama pull llama3.2
   ```
3. **Start the server:** Ollama runs automatically in the background after installation. The game connects to `http://localhost:11434/api/generate`.
4. **Fallback:** If Ollama is not running, the AI agents will use deterministic fallback dialogue/recipes — the game will not crash.

### C. GUT (Godot Unit Test) Framework
The GUT addon is already included in `addons/gut/`. No additional installation needed. To run tests:
* **In-editor:** Open Godot → click the **GUT** tab at the bottom → **Run All**.
* **CLI (headless):**
  ```bash
  godot --headless -s addons/gut/gut_cmdln.gd
  ```
* Tests are located in `test/unit/` and configured via `.gutconfig.json`.

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

### ⚠️ Important: CI/CD is Active
Every push to `main` triggers the GitHub Actions pipeline which:
- Exports the game for Web using Godot 4.3.
- Deploys to GitHub Pages automatically.
- If your merge breaks the export, the deployment will fail — check the [Actions tab](../../actions).

---

## 3. Godot & Art Best Practices

To keep our project clean and scalable, please adhere to the following rules:

### A. Project Structure
Do not drop files randomly in the `res://` root. Use the designated folders:
* `assets/graphics/` — For all images (UI, backgrounds, ingredients).
* `assets/theme/` — For all `.tres` theme resources (buttons, styles, toggles).
* `assets/fonts/` — For custom fonts.
* `scenes/` — For all `.tscn` files (grouped by `menus`, `gameplay`, `entities`, `components`, `ui`).
* `scripts/` — For all `.gd` code files (mirrors the `scenes/` structure).
* `scripts/ai/` — For AI agent scripts and customer history.
* `test/unit/` — For GUT unit tests (prefix: `test_`).
* `autoloads/` — For autoloaded singletons (`Global`, `AudioManager`).

### B. Art & Canvas Rules (Canva/Assets)
* **Base Resolution:** Our game runs at **1920x1080**.
* **Parallax Assets:** If you are designing layers for a Parallax background, the images MUST be slightly larger than the screen (e.g., 2050x1150) to prevent borders from showing during camera movement.
* **Transparency:** Always export game assets as `.png` with **Transparent Backgrounds**. White backgrounds will break the 2.5D illusion.

### C. Scene Organization & Architecture
* **.gitignore:** Never remove or modify the `.gitignore` file. It prevents the `.godot/` cache folder from being uploaded, which would cause massive merge conflicts.
* **Modularity:** Do not build the entire game in a single scene. Each User Story (like the Cutting Station or the Wrap Area) should be its own `.tscn` file, which we instance into the `GameplayMaster` scene.
* **Theme Resources:** All `.tres` theme files are preloaded in `global.gd` to ensure they are included in exports. If you add a new `.tres`, add a corresponding `preload()` constant there.

### D. Autoloads
The project uses two autoloads defined in `project.godot`:
* **`Global`** (`scripts/global.gd`) — Central game state: save/load system, money, day progression, daily stats, signals.
* **`AudioManager`** (`autoloads/audio_manager.tscn`) — Handles background music (with fade) and SFX. Automatically connects a click sound to every `BaseButton` in the scene tree.

### E. AI Tooling
* Remember our *AI-first* rule. If you use ChatGPT, Copilot, Antigravity, or Cursor to generate a GDScript or a GLSL Shader, save the prompt and add it to our `./docs/AI_USAGE_REPORT.md` file before you open your PR.

### F. Testing
* When adding new game logic (scoring, save data, AI agents), write corresponding GUT tests in `test/unit/`.
* Test file naming convention: `test_<script_name>.gd`.
* All test classes must `extend GutTest`.
* Run the full suite before opening a PR to make sure nothing is broken.

Happy coding! 🌯
