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
* **Process:** We asked the AI for best practices regarding Godot 4.x folder structures (separating `assets`, `scenes`, `scripts`, and `data`).
* **Result:** A clean, modular architecture that prevents cyclic dependencies and merge conflicts. Four architectural diagrams were generated and stored in `docs/diagrams/`:
  * **Component Architecture UML** — Class relationships between Global, GameplayMaster, stations, and AI agents.
  * **Customer State Diagram** — State machine for customer lifecycle (waiting → ordering → being served → reviewing → leaving).
  * **LLM Communication Architecture** — Data flow between Godot's `HTTPRequest`, Ollama, and the game state.
  * **Gameplay Workflow** — Full day loop: Morning HUB → Start Day → Order → Cutting → Assembly → Wrapping → Evaluation → Night Summary.

## 3. Code Generation (Godot 4.x & GDScript)
**Tools Used:** Gemini, Antigravity (Google DeepMind)

**All GDScript code in this project was written by AI.** No manual GDScript was authored; the developer's role was to direct, review, and approve AI-generated implementations. Notable examples:

* **Implementation Examples:**
  * **Save/Load System & Data Persistence (`global.gd`):** AI architected a robust 3-slot save system using Godot's `FileAccess` and `DirAccess`. Includes serializing/deserializing default game state (day, money, inventory, upgrades) into local `.json` files. The `load_save_data()` function merges loaded data on top of defaults for forward-compatible saves (old saves missing new keys get sensible defaults).
  * **Money & Economy System (`global.gd`):** AI designed the dual-money architecture: `current_save["money"]` as the permanent bank, and `daily_earnings` as a session-scoped cash register. `add_money()` updates both and emits reactive signals (`money_changed`, `daily_earnings_changed`) so all UI components update in real-time without polling.
  * **Day/Night Cycle & Transitions (`day_transition.gd`):** AI implemented a state-machine-based day manager with `DayState.MORNING` and `DayState.NIGHT` enum, toggling visibility of morning and night containers. Integrates with a `Timer` in Global for configurable day durations (default: 180 seconds).
  * **Complete Gameplay Loop (`gameplay_master.gd`):** AI wrote the central orchestrator that manages all four stations (Order, Cutting, Assembly, Wrapping), camera transitions between them, pita state tracking (a Dictionary with scores for each station), perfect order detection, and tip accumulation. Includes a parallel camera tween system for smooth station transitions.
  * **Scoring System (`lipie.gd`):** AI designed a sophisticated multi-factor scoring algorithm for the assembly station: ingredient presence (−15 for missing), order correctness (−5 for wrong order), extras penalty (−10), combined with sauce mini-game scoring (ideal droplet count vs actual, with mess penalty). Final score: 60% ingredients + 40% sauce.
  * **Customer System (`customer.gd`):** AI generated a complete customer entity with: random order generation (meat type, 2-4 vegetables, 1-2 sauces, 1 drink), patience system with two decay rates (queue vs cooking), AI trend integration (70% chance to request `Global.trend_ingredient`), loyal customer patience reduction (−10% for bad history), and lobby/zoom sprite switching.
  * **Order Ticket Drag & Drop (`order_ticket.gd`):** AI implemented a visual drag-and-drop system with scaled preview generation, drink separation (drinks displayed via a dedicated `IconitaSuc` node), and animated ingredient reveal (0.5s delay between each icon).
  * **Complex UI State Management (`saves_menu.gd`):** AI consolidated multiple UI flows (New Game, Load Game, Delete Save) into a single, dynamically updating pop-up module. Slot buttons are dynamically styled via `theme_type_variation` ("FilledSlot" vs "EmptySlot") and labels are truncated at 17 characters.
  * **Quick Menu / Pause System (`quick_menu.gd`):** AI implemented a full pause menu with: drop-down animation (`TRANS_BACK`), modal overlay fading, game pause/resume via `get_tree().paused`, settings submenu integration with re-entry animation, and Escape key toggle with guard against double-press.
  * **Settings Menu (`settings_menu.gd`):** AI wrote fullscreen toggle (via `DisplayServer`), volume control (linear↔dB conversion), F11 shortcut, and a windowed mode helper that prevents OS auto-maximize bugs by forcing a specific resolution and centering the window.
  * **TopBar Dual-Mode UI (`top_bar.gd`):** AI designed a single component with two modes (`HUB` and `GAMEPLAY`) controlled via an `@export` enum. HUB mode shows Day + Total Money; Gameplay mode shows Customer Counter + Daily Profit. Each mode applies different `StyleBox` and `Texture2D` sets. Includes label scale-bounce animations via tween.
  * **AudioManager Autoload (`audio_manager.gd`):** AI implemented a scene-tree-aware audio manager that automatically attaches click sounds to every `BaseButton` via `node_added` signal. Music playback includes volume fade-in/out with configurable duration.
  * **Dynamic Parallax Menu (`mouse_parallax.gd`):** AI generated the mathematical logic to create a 2.5D depth effect using mouse coordinates, applying `lerp()` for smooth layer movement and dynamically recalculating the screen center on window resize.
  * **Cinematic Camera Transitions:** Instead of basic scene loading, AI wrote a parallel Tweening script (`create_tween().set_parallel(true)`) that smoothly moves and zooms a `Camera2D` into the shop counter before loading the first level.
  * **Loading Screen (`loading_screen.gd`):** AI implemented a threaded async loading screen using `ResourceLoader.load_threaded_request` with a dual-condition gate (`_min_time_passed AND _scene_is_ready`) ensuring both UX polish and correctness. Includes a progress bar capped at 95% until real load completes, and a programmatic fade-to-black transition.
  * **Modal Overlay Component (`modal_overlay.gd`):** AI authored a reusable `ColorRect`-based overlay with `fade_in`, `fade_out`, and `fade_to_full_black` methods, coroutine-safe tween handling, and `mouse_filter` toggling to block input during animations.
  * **Light Flicker Component (`light_flicker.gd`):** AI implemented noise-based light flickering using `FastNoiseLite.TYPE_SIMPLEX` with a per-instance random seed so lights flicker independently. Includes `fade_in`/`fade_out` methods that accept an external `Tween` for parallel animations.
  * **Metal Shutter Component (`metal_shutter.gd`):** AI implemented a cinematic shop-closing effect driven by an `AnimationPlayer`, with a `shutter_closed` signal for the parent to `await`.

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
| `global.gd` | Theme `.tres` not included in web export | Added 16 `preload()` constants for all `.tres` files to force inclusion |
| `godot-web-deploy.yml` | UID references breaking headless export | `sed` replacements to swap UIDs for `res://` paths before export |

## 5. Visuals, Shaders, and "Juice"
**Tools Used:** Gemini for GLSL Shaders, AI Image Generators (Canva/Midjourney)

To achieve a polished "2D that looks 3D" aesthetic without heavy performance costs, we utilized AI for advanced visual effects.
* **Glass Distortion Shader:** AI wrote a custom Godot CanvasItem Shader to simulate looking through a distorted shop window using sine/cosine waves on `SCREEN_UV`.
* **2D Lighting Systems:** AI guided setup of `PointLight2D` with custom radial gradients and noise-based flicker effects via `FastNoiseLite` to simulate neon shop lights. Lights can be batch-toggled via the `shop_lights` global group.
* **Asset Generation:** Background layers (Sky, City, Shop, Counter) were generated and separated with transparent backgrounds to be compatible with our Parallax script.

## 6. In-Game AI Agents (Core Mechanics)
**Tools Used:** Ollama running Llama 3.2 locally

All three AI agents are **fully implemented** and integrated into the gameplay loop:

### Agent 1: The Loyal Customer (`loyal_customer_agent.gd` + `customer_history.gd`)
* **LLM Integration:** Sends a structured prompt to `http://localhost:11434/api/generate` containing the current order, the hidden memory (last 3 interactions as JSON), and whether history exists.
* **Memory System:** `customer_history.gd` provides static methods: `load_history()`, `save_interaction()`, `last_order_was_wrong()` (score < 70), and `has_any_history()`. History is persisted to `user://loyal_customer_history.json` with a max of 3 entries.
* **Fallback Logic:** If the LLM is unavailable or returns invalid data, the `_fallback_dialogue()` method generates deterministic responses based on history state: intro text for first visits, negative feedback for bad scores (< 70), positive feedback for good scores.
* **Gameplay Impact:** Bad previous orders reduce customer patience by 10% (`rabdare_initiala *= 0.9`).

### Agent 2: The Culinary Influencer (`culinary_influencer_agent.gd`)
* **LLM Integration:** Sends a filtered ingredient list (drinks excluded) with strict JSON format instructions.
* **Output Schema:** `{"review": "...", "trend_ingredient": "exact_name_from_list"}`.
* **Post-Processing:** Response is double-parsed (Ollama wrapper → inner JSON). The `trend_ingredient` is stored in `Global.trend_ingredient` and influences next-day customer order generation.
* **Fallback:** Returns `"falafel"` as default trend and a generic review on any failure.

### Agent 3: Daily Fusion Menu (`daily_menu_agent.gd`)
* **LLM Integration:** Sends available ingredients and asks for a creative fusion recipe using strict JSON format.
* **Output Schema:** `{"fusion_recipe": ["ingredient1", "ingredient2", ...]}`.
* **Gameplay Impact:** Completing the daily fusion recipe awards double tips. Stored in `Global.daily_fusion_recipe`.
* **Fallback:** Returns `["carne_pui", "cartofi", "varza", "maioneza_usturoi"]` on any failure.

## 7. Automated Testing
**Tools Used:** GUT (Godot Unit Test) Framework, Antigravity (Google DeepMind)

AI generated a comprehensive test suite with **~50 unit tests** covering:

| Test File | Script Under Test | Tests | What Is Covered |
|---|---|---|---|
| `test_global.gd` | `global.gd` | 22 | Default save data, add_money signals, daily stats reset, save merging, day advancement, end-of-day earnings |
| `test_gameplay_master.gd` | `gameplay_master.gd` | 14 | Pita state structure, score accumulation, perfect order detection, multi-save tracking, tip accumulation |
| `test_loyal_customer_agent.gd` | `loyal_customer_agent.gd` | 6 | Fallback dialogue branching, boundary scores (69/70), history ordering |
| `test_culinary_influencer_agent.gd` | `culinary_influencer_agent.gd` | 5 | Drink filtering, empty/full ingredient lists, edge cases |
| `test_day_transition.gd` | `day_transition.gd` | 3 | Constants, enum values, scene path validity |

## 8. DevOps & CI/CD Pipeline
**Tools Used:** Gemini, Antigravity (Google DeepMind)

The CI/CD pipeline is **fully operational** in `.github/workflows/godot-web-deploy.yml`:

* **Trigger:** Every push to `main`.
* **Container:** `barichello/godot-ci:4.3` (matches project's Godot version).
* **Pipeline Steps:**
  1. Checkout repository.
  2. Setup export templates (`4.3.stable`).
  3. Create `build/web/` directory.
  4. Apply headless export fixes via `sed` (replace UID references with `res://` paths, set theme path).
  5. Export Web build: `godot --headless --verbose --export-release "Web"`.
  6. Inject `coi-serviceworker.js` into the HTML `<head>` for `SharedArrayBuffer` support.
  7. Debug step: log PCK file size and list all exported files.
  8. Upload artifact and deploy to GitHub Pages.
* **Version Control Setup:** AI generated our Godot 4–specific `.gitignore` file, ensuring massive cache folders (`.godot/`) are excluded.
* **Export Configuration:** `export_presets.cfg` uses `export_filter="all_resources"` with an explicit `include_filter` for `res://assets/*` to guarantee all theme and font resources are packaged.
