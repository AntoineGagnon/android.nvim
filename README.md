# 󰀲 android.nvim

A lightweight, powerful Android development plugin for Neovim. It brings Gradle building, ADB device management, and a fully interactive Logcat directly into your editor, seamlessly integrating with modern Neovim UI components.

## ✨ Features

- **Smart Auto-Detection**: Automatically finds your app's package name (`applicationId`) and Main Activity by scanning your `build.gradle` and `AndroidManifest.xml`. Works with multi-module projects!
- **Interactive Logcat**: Opens a split terminal using `Snacks.terminal` with buffer-local keymaps to clear logs, change log levels, filter by regex, and isolate logs only to your app's PID.
- **Device Management**: Pick between connected physical devices or start Android Emulators directly from Neovim.
- **Gradle Integration**: Run builds, cleans, and install/launch your app with real-time output in a beautiful split window.
- **Which-Key Support**: Out-of-the-box integration with `which-key.nvim` providing beautiful icons and organized menus.

## 📦 Installation

Install using your favorite package manager.

### [Lazy.nvim](https://github.com/folke/lazy.nvim) (LazyVim)

```lua
return {
  "username/android.nvim",
  lazy = false, -- Load immediately to register which-key icons
  config = function()
    require("android").setup({
      -- Default options (optional)
      log_level = "D",         -- V, D, I, W, E, F
      filter_by_app = true,    -- Automatically filter logcat to the detected app
    })
  end,
}
```
*(Note: Replace `username` with your GitHub username once published!)*

## 🚀 Usage

The plugin automatically registers the following commands and keymaps (if `which-key` is installed):

| Keymap | Command | Description |
| :--- | :--- | :--- |
| `<leader>aa` | `:AndroidBuildAndRun` | Builds, installs, and launches the app on the selected device |
| `<leader>ab` | `:AndroidBuild` | Runs Gradle `assembleDebug` |
| `<leader>ac` | `:AndroidClean` | Runs Gradle `clean` |
| `<leader>ad` | `:AndroidSelectDevice` | Opens a UI to pick from connected ADB devices |
| `<leader>ae` | `:AndroidStartEmulator` | Opens a UI to pick and boot an Android Virtual Device (AVD) |
| `<leader>al` | `:AndroidLogcatToggle` | Toggles the Logcat split window |

### 📋 Interactive Logcat

When you open the Logcat window (`<leader>al`), the following keys are available in **both** Normal and Terminal mode:

- `q` / `<C-q>`: Close the Logcat window
- `c` / `<C-c>`: Clear the Logcat history (`adb logcat -c`)
- `f` / `<C-f>`: Filter logs by a specific text string or regex
- `l` / `<C-l>`: Change the minimum Log Level (Verbose, Debug, Info, Warn, Error)
- `a` / `<C-a>`: Toggle isolating logs to *only* your app's process (PID) vs all system logs

## ⚙️ Configuration

You can override the default settings by passing a table to `setup()`:

```lua
require("android").setup({
  -- The default log level for logcat
  log_level = "D",
  -- Arguments to pass to the build command
  build_args = { "assembleDebug" },
  -- Arguments to pass to the install command
  install_args = { "installDebug" },
  -- Should logcat be filtered to the app PID by default?
  filter_by_app = true,
  -- Any extra flags for Logcat
  logcat_flags = { "-v", "color" },
})
```

## 🛠️ Requirements

- Neovim >= 0.9.0
- [Snacks.nvim](https://github.com/folke/snacks.nvim) (Required for the UI components and terminal splits)
- Android SDK (`adb`, `emulator`, and `gradlew` available in your path/project)
