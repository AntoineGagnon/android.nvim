local M = {}

M.options = {
  -- The default log level for logcat (V, D, I, W, E, F, S)
  log_level = "D",
  -- Arguments to pass to the build command
  build_args = { "assembleDebug" },
  install_args = { "installDebug" },
  -- Should logcat be filtered to the app PID by default?
  filter_by_app = true,
  -- Any extra flags for Logcat (e.g., "-v color")
  logcat_flags = { "-v", "color" },
}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.options, opts or {})
end

return M
