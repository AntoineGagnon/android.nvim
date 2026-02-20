# 🤖 Opencode Agents Documentation

This document explains the architecture and operational guidelines for AI agents (like Opencode) working on the `android.nvim` plugin.

## 🏗️ Architecture Overview

The plugin is structured modularly in `lua/android/`:

1.  **`init.lua`**: The main entry point. Registers Neovim User Commands and integrates with `which-key.nvim` (hooking into the `VeryLazy` event to ensure icons register properly).
2.  **`config.lua`**: Handles default options and user overrides via `setup(opts)`.
3.  **`detect.lua`**: The intelligence engine. Recursively scans the project (ignoring `build/` dirs) for `build.gradle` or `build.gradle.kts` files containing the `com.android.application` plugin or `applicationId`. If found, it extracts the package name. It also parses the corresponding `AndroidManifest.xml` to find the Activity with the `MAIN` action and `LAUNCHER` category.
4.  **`adb.lua`**: Wrappers around `adb` and `emulator` commands. Uses `vim.ui.select` (often hooked into Snacks picker) to present selection menus for connected devices or AVDs. It also resolves app PIDs (`pidof`) for log filtering.
5.  **`logcat.lua`**: Manages the interactive `Snacks.terminal` split window. Features dynamic window titles based on active filters and injects both Normal-mode and Terminal-mode keymaps (e.g., `<C-c>` to clear, `<C-a>` to toggle PID filtering) into the terminal buffer.
6.  **`gradle.lua`**: Executes Gradle wrapper commands (`./gradlew`) asynchronously inside a `Snacks.terminal` split for building, cleaning, and installing. If the install succeeds, it uses `adb shell am start` to launch the detected main activity.

## 🛠️ Development Guidelines for Agents

When making changes to this plugin, agents **MUST** adhere to the following rules:

### 1. UI Consistency (Snacks.nvim)
*   Do **not** introduce older UI dependencies like `toggleterm.nvim`, `fzf-lua`, or `telescope.nvim`.
*   This plugin relies natively on `vim.ui.select` (which LazyVim maps to Snacks picker) and uses `Snacks.terminal` for all split windows, build outputs, and Logcat streaming.
*   Maintain the interactive keymaps in `logcat.lua` using both Normal mode (`n`) and Terminal mode (`t`) mappings, ensuring users don't have to escape terminal mode manually to trigger commands.

### 2. File Path Operations
*   Always use `vim.fn.getcwd()` to evaluate paths dynamically against the user's currently open Android project.
*   Never hardcode `/app/` as the module name. Always use the detection logic in `detect.lua` (`M.get_app_module_path()`) to support multi-module projects (e.g., `wear`, `mobile`, `presentation`).

### 3. Asynchronous Execution
*   ADB commands that return instantly (like `adb devices` or `pidof`) can use `io.popen` or `vim.fn.system`.
*   Long-running tasks (like `gradlew assemble` or `adb logcat`) **must** use asynchronous execution via `Snacks.terminal` or `vim.fn.jobstart`. Never block the Neovim main UI thread.

### 4. Which-Key Integration
*   The plugin registers its icons by binding them to the underlying `<cmd>...<cr>` commands rather than specific `<leader>` keys. This allows users to remap the keys in their personal config while retaining the icons.
*   When adding new commands, ensure they are added to the `setup_which_key()` function in `init.lua` with an appropriate Nerd Font icon.

## 🚀 Common Agent Workflows

*   **Adding a new ADB Command:** Create the function in `adb.lua`, expose it via a User Command in `init.lua`, and add the Which-Key mapping.
*   **Improving Detection:** Modify the heuristics in `detect.lua` and ensure it handles edge cases like Kotlin script (`.kts`) vs Groovy (`.gradle`).
*   **Enhancing Logcat UI:** Modify the `Snacks.terminal` options or the buffer-local keymaps inside the `on_buf` callback in `logcat.lua`.
