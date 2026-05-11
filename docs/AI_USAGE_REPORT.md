# 🤖 AI Usage Report: Papas Shaormeria

This document outlines the extensive use of Artificial Intelligence tools throughout the Software Development Life Cycle (SDLC) of the "Papas Shaormeria" project. We adopted a **100% AI-first approach** — every line of code in this project was written or reviewed by AI — to meet the requirements of the MDS laboratory.

---

## 1. Project Planning & Backlog Creation
**Tools Used:** Gemini / ChatGPT

We used LLMs to brainstorm game mechanics and translate them into professional agile artifacts.
* **Process:** We provided the AI with the core concept ("a shaorma shop simulator in Godot with AI agents") and asked it to generate atomic, actionable User Stories.
* **Result:** The AI successfully generated the 13 core User Stories, complete with Acceptance Criteria and Technical Tasks, which we then imported into our GitHub Projects Kanban board. We also used AI to structure our `CONTRIBUTING.md` and define our Git branching strategy.
* **Example Prompt:** *"Create 13 user stories for a shaorma shop simulator in Godot. Include acceptance criteria and technical Godot nodes required for mechanics like cutting meat, drag-and-drop assembly, and interacting with AI customers."*

## 2. System Architecture & Diagrams
**Tools Used:** Gemini / AI Diagramming Tools

To design a scalable architecture before coding, we used AI to generate our Godot project structure and workflow diagrams.
* **Process:** We asked the AI for the best practices regarding Godot 4.x folder structures (separating `assets`, `scenes`, `scripts`, and `data`).
* **Result:** A clean, modular architecture that prevents cyclic dependencies and merge conflicts.
* *(Note: Mermaid diagrams for LLM communication will be added here as we implement the HTTPRequests).*

## 3. Code Generation (Godot 4.x & GDScript)
**Tools Used:** Gemini, Antigravity (Google DeepMind)

**All GDScript code in this project was written by AI.** No manual GDScript was authored; the developer's role was to direct, review, and approve AI-generated implementations. The following are notable examples:

* **Implementation Examples:**
  * **Save/Load System & Data Persistence:** AI architected a robust 3-slot save system using Godot's `FileAccess` and `DirAccess`. This included serializing/deserializing default game state (day, money, inventory, upgrades) into local `.json` files.
  * **Complex UI State Management:** AI consolidated multiple UI flows (New Game, Overwrite Save, Delete Save) into a single, dynamically updating pop-up module, maximizing code reuse (DRY principle) via state flags (`is_deleting`, `is_overwriting`).
  * **Input Validation & UX:** AI generated logic to validate user input for save file names, enforcing character limits and scanning existing `.json` files to prevent duplicate save names across slots.
  * **Algorithmic UI Debugging:** When encountering visual layout bugs (overlapping text labels in the Main Menu), AI wrote a custom node-tree scanning script ("Ghost Detector") that traversed the Godot UI hierarchy to identify hidden nodes, debug output states, and fix incorrect `Anchors Presets`.
  * **Dynamic Parallax Menu (`mouse_parallax.gd`):** AI generated the mathematical logic to create a 2.5D depth effect using mouse coordinates, applying `lerp()` for smooth layer movement and dynamically recalculating the screen center on window resize. Exports (`multipliers`, `lerp_speed`) allow per-instance tuning in the Godot Inspector.
  * **Cinematic Camera Transitions:** Instead of basic scene loading, AI wrote a parallel Tweening script (`create_tween().set_parallel(true)`) that smoothly moves and zooms a `Camera2D` into the shop counter before loading the first level.
  * **UI Juice (Hover Effects):** AI provided the code to dynamically scale buttons on `mouse_entered` and `mouse_exited` using `Tween.TRANS_QUAD`.
  * **Display Management:** AI generated the input handling logic to toggle Fullscreen mode using `DisplayServer` via the F11 key.
  * **Credits Menu (`credits_menu.gd`):** AI implemented a receipt-style slide-in/slide-out animation using `Tween.TRANS_BACK` with asymmetric easing (`EASE_OUT` in, `EASE_IN` out). Positions are derived from `get_viewport_rect().size` to be resolution-independent.
  * **Loading Screen (`loading_screen.gd`):** AI implemented a threaded async loading screen using `ResourceLoader.load_threaded_request` with a dual-condition gate (`_min_time_passed AND _scene_is_ready`) ensuring both UX polish and correctness. Includes a progress bar capped at 95% until real load completes, and a programmatic fade-to-black transition on scene switch.
  * **Modal Overlay Component (`modal_overlay.gd`):** AI authored a reusable `ColorRect`-based overlay with `fade_in`, `fade_out`, and `fade_to_full_black` methods, coroutine-safe tween handling (local tween capture to prevent signal loss on interruption), and `mouse_filter` toggling to block input during animations.
  * **Light Flicker Component (`light_flicker.gd`):** AI implemented noise-based light flickering using `FastNoiseLite.TYPE_SIMPLEX` with a per-instance random seed so lights flicker independently. Includes `fade_in`/`fade_out` methods that accept an external `Tween` so all lights animate in parallel from a single parent tween.
  * **Metal Shutter Component (`metal_shutter.gd`):** AI implemented a cinematic shop-closing effect driven by an `AnimationPlayer`, with a `shutter_closed` signal for the parent to `await`. Uses a `StringName` constant to eliminate magic string duplication.

## 4. AI-Assisted Code Review & Refactoring
**Tools Used:** Antigravity (Google DeepMind)

Beyond initial code generation, AI was used to conduct systematic code review sessions across all menu and component scripts. The AI identified issues, explained the rationale, and applied fixes upon approval. Examples of improvements made:

| File | Issue Found | Fix Applied |
|---|---|---|
| `credits_menu.gd` | Magic Y positions, dead `_ready()`, no double-press guard | Viewport-relative positions, removed no-op, disabled button on press |
| `loading_screen.gd` | `await` on killed tween, redundant polling, fake 100% bar | Local tween capture, skip poll when loaded, 95%→100% on real load |
| `modal_overlay.gd` | Coroutine leak on interrupted fade, duplicate `fade_to_full_black` | Local tween capture with identity guard, delegation to `fade_in` |
| `light_flicker.gd` | Magic `100.0` constant, unbounded float accumulation, hyphen filename | `@export noise_frequency`, `fmod` wrap, renamed to `light_flicker.gd` |
| `mouse_parallax.gd` | Index alignment risk, magic lerp `5.0`, silent array mismatch | `.filter()` to Control-only, `@export lerp_speed`, `push_warning` |
| `metal_shutter.gd` | Magic string `"close"` duplicated, no double-call guard | `const ANIM_CLOSE: StringName`, `is_playing()` guard |

## 5. Visuals, Shaders, and "Juice"
**Tools Used:** Gemini for GLSL Shaders, AI Image Generators (Canva/Midjourney)

To achieve a polished "2D that looks 3D" aesthetic without heavy performance costs, we utilized AI for advanced visual effects.
* **Glass Distortion Shader:** AI wrote a custom Godot CanvasItem Shader to simulate looking through a distorted shop window.
  * **AI Output snippet used:** The AI provided the math to manipulate `SCREEN_UV` using sine/cosine waves (`uv.x += sin(UV.y * wave_frequency) * distortion_strength;`) to deform the background dynamically.
* **2D Lighting Systems:** AI guided setup of `PointLight2D` with custom radial gradients and noise-based flicker effects via `FastNoiseLite` in `_process(delta)` to simulate neon shop lights.
* **Asset Generation:** Background layers (Sky, City, Shop, Counter) were generated and separated with transparent backgrounds to be compatible with our Parallax script.

## 6. In-Game AI Agents (Core Mechanics)
**Tools Used:** Ollama running Llama 3 locally

*(Work in Progress)* The core differentiator of our game is the integration of live AI agents.
* **Agent 1: The Loyal Customer (Contextual Memory)**
  * **Implementation:** We will pass a JSON array of the last 3 days' interactions into the system prompt.
* **Agent 2: The Influencer (JSON Structured Output)**
  * **Implementation:** We will use strict prompting to force the local LLM to output only valid JSON containing a review and a `trend_ingredient`.

## 7. DevOps & CI/CD Pipeline
**Tools Used:** Gemini

* **Version Control Setup:** AI generated our Godot 4 specific `.gitignore` file, ensuring massive cache folders (`.godot/`) are excluded from our repository.
* **CI/CD *(Upcoming)***: We will use AI to write the GitHub Actions `.yml` workflow file to automate testing and build generation on every push to the `main` branch.
