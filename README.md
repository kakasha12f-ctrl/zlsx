# ⚡ zlsx — Fast & Customizable LS Clone written in Zig

[![Zig Version](https://img.shields.io/badge/Zig-0.17.0--dev-orange.svg?style=flat-square)](https://ziglang.org/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux-lightgrey.svg?style=flat-square)](#)

**zlsx** is a lightweight, high-performance clone of the core `ls` system utility, written from scratch in the **Zig** programming language. The project is heavily optimized for execution speed, featuring custom low-strain color palettes (Catppuccin Mocha/Nord) and reliable POSIX-compliant argument parsing.

---

## ✨ Core Features (Supported Flags)

The utility supports flexible combinations of CLI flags to completely control your terminal output:

| Flag | Description |
| :--- | :--- |
| `-a` | Show hidden files and directories (those starting with a dot `.`). |
| `-1` | List one file per line. |
| `-m` | Stream output as a comma-separated list. |
| `-l` | Use a long listing format (displays file sizes and metadata). |
| `-h` | Print human-readable sizes (`Kb`, `Mb`) when used with `-l` or `-s`. |
| `-s` | Display the allocated size of each file next to its name. |
| `-T` | Display the last modification time (`mtime`). |
| `-F` | Append indicators to entries (e.g., `/` for directories, `@` for symlinks). |
| `-t` | Sort files by modification time (newest first). |
| `-S` | Sort files by size (largest first). |
| `-r` | Reverse the sorting order. |
| `--` | POSIX double-dash delimiter. Everything passed after `--` is strictly treated as a path. |

---

## 🎨 Color Palette (Customization)

To drastically reduce eye strain during long terminal sessions, standard high-saturation ANSI colors have been replaced with modern, softer pastel shades:

* **Directories:** `#89b4fa` (Sky blue from the **Catppuccin Mocha** palette) — `RGB (137, 180, 250)`.
* **Symbolic Links:** Soft muted aquamarine from the **Nord** theme (`256-color: 116`).
* **Regular Files:** Default terminal text color for optimal contrast.

---

## 🚀 Build & Run

### Requirements
* An installed **Zig** compiler (tested on version `0.17.0-dev`).

### Quick Start (Compile & Run instantly)
```bash
# View the current working directory
zig run zlsx.zig

# View a specific directory with custom options
zig run zlsx.zig -- -l -h -S /home/user/Downloads
