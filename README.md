# FLASH

FLASH is an experimental synchronization tool for **Roblox Studio**, inspired by Rojo but built with a **different architecture and philosophy**.

The goal of this project is to explore an alternative way to sync external files with Roblox Studio using a **C# standalone executable** and a **Roblox Studio plugin**.

> ⚠️ This project is in early development and is primarily intended for learning, experimentation, and tooling research.

---

## ✨ Features (Current & Planned)

### Current
- External **C# `.exe` server** (Console-based)
- Communication with Roblox Studio via **HTTP (localhost)**
- JSON-based protocol
- Real-time logging in a dedicated terminal window
- Proof-of-concept script synchronization

### Planned
- File system watching (`.lua` files)
- Path-based mapping to Roblox Instances
- Hot-reload for Script / ModuleScript
- Hash-based diffing to prevent sync loops
- Config file support (`FLASH.json`)
- Multi-project support

---

## 🧠 Design Philosophy

Key differences:
- Focus on **clarity over completeness**
- Explicit JSON protocol instead of implicit filesystem mapping
- Minimal Roblox Plugin acting as a bridge
- Designed to be easy to understand, modify, and extend

This project prioritizes:
- Learning how professional developer tools are built
- Understanding synchronization, serialization, and tooling architecture
- Experimentation with alternative workflows

