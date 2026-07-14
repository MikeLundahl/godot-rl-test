# AGENTS.md

## Project Overview

Godot 4.4 game project (C#) that uses the [Godot RL Agents](https://github.com/edbeeching/godot_rl_agents) addon for reinforcement learning. A character navigates to a goal in a 3D arena; training is driven by an external Python server.

## Key Files

- `project.godot` — Godot project config. Enables the `godot_rl_agents` plugin.
- `scenes/character/character.gd` — Main agent logic (movement, reward calculation, reset).
- `scenes/arena/` — Arena scene and wall/collision scripts.
- `addons/godot_rl_agents/sync.gd` — Central coordinator: connects to Python server on `127.0.0.1:11008`, orchestrates obs/action exchange.
- `addons/godot_rl_agents/controller/ai_controller_3d.gd` — AIController3D with `get_obs()`, `get_reward()`, `get_action_space()`, `set_action()` (must be overridden by extending scripts).
- `script_templates/AIController/controller_template.gd` — Template for new AI controllers.
- `addons/godot_rl_agents/onnx/wrapper/ONNX_wrapper.gd` — GDScript wrapper around C# ONNX inference.
- `addons/godot_rl_agents/onnx/csharp/ONNXInference.cs` — C# ONNX runtime inference.

## Build & Run

- **Open in Godot Editor:** Open `project.godot` in Godot 4.4+ (must have .NET/Mono support for C# build).
- **Run game:** F5 in Godot Editor. Starts in `HUMAN` control mode by default (no Python server needed).
- **Run for training:** Launch Python training server first, then run Godot with `--control_mode=1` (TRAINING). The `Sync` node connects to `127.0.0.1:11008`.
- **C# build:** Triggered automatically by Godot when opening the project or running. Uses `Godot.NET.Sdk/4.4.1` targeting `net8.0`. No standalone `dotnet build` command needed outside the editor.
- **No lint, typecheck, test, or CI commands exist.** This is a Godot game project with no test framework configured.

## Architecture Notes

- **Two `.csproj` files:** `Godot_RL_test.csproj` (main, net8.0) and `Godot RL Agents.csproj` (addon, net6.0). The addon csproj is a legacy artifact; only the main csproj matters for builds.
- **Sync node is the entrypoint** for all training/inference flows. It discovers agents via the `"AGENT"` group, collects obs/spaces, and drives the training loop via TCP messages.
- **Control modes:** `HUMAN` (keyboard), `TRAINING` (Python server), `ONNX_INFERENCE` (local model file), `RECORD_EXPERT_DEMOS`. Agents inherit from Sync or override via `control_mode` export.
- **ONNX inference** requires `.onnx` model files. The path is set on the `Sync` node or per `AIController3D` node. The `model.onnx` in the project root is the trained model.
- **Reward:** Defined in `character.gd` — distance-based shaping toward goal. Episode terminates via `game_over()` or `reset_after` step limit.

## Conventions

- GDScript for game logic, C# only for ONNX runtime interop.
- `.gitattributes` enforces LF line endings. Do not add Windows line endings.
- Addon code lives under `addons/godot_rl_agents/`. Game-specific code lives under `scenes/`.
- AI controllers must be in the `"AGENT"` group to be discovered by Sync.
- New AI controllers should extend the template at `script_templates/AIController/controller_template.gd`.
