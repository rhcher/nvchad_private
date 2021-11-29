local ok, treesitter = pcall(require, "nvim-treesitter.configs")
if not ok then
  return
end

-- vim.api.nvim_command "set foldmethod=expr"
-- vim.api.nvim_command "set foldexpr=nvim_treesitter#foldexpr()"
treesitter.setup {
  ensure_installed = {
    "c",
    "cpp",
    "rust",
    "lua",
    "python",
    "cmake",
    "haskell",
    "vim",
    "fennel",
  },
  autopairs = { enable = true },
  matchup = { enable = true },
  highlight = {
    enable = true,
    disable = { "racket", "haskell" },
  },
  textsubjects = {
    enable = true,
    keymaps = {
      ["<CR>"] = "textsubjects-smart",
      ["<Tab>"] = "textsubjects-container-outer",
    },
  },
}
