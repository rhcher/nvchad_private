local overrides = require("core.hooks").createOverrides "lsp"
local util = require "vim.lsp.util"

local function on_attach(client, bufnr)
  local function buf_set_keymap(...)
    vim.api.nvim_buf_set_keymap(bufnr, ...)
  end
  local function buf_set_option(...)
    vim.api.nvim_buf_set_option(bufnr, ...)
  end

  -- Enable completion triggered by <c-x><c-o>
  buf_set_option("omnifunc", "v:lua.vim.lsp.omnifunc")

  -- Mappings.
  local opts = { noremap = true, silent = true }

  -- See `:help vim.lsp.*` for documentation on any of the below functions
  buf_set_keymap("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", opts)
  buf_set_keymap("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
  if vim.api.nvim_buf_get_option(0, "filetype") ~= "racket" then
    buf_set_keymap("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
  end
  buf_set_keymap("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", opts)
  buf_set_keymap("n", "gk", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
  buf_set_keymap(
    "n",
    "<space>wa",
    "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>",
    opts
  )
  buf_set_keymap(
    "n",
    "<space>wr",
    "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>",
    opts
  )
  buf_set_keymap(
    "n",
    "<space>wl",
    "<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>",
    opts
  )
  buf_set_keymap(
    "n",
    "<space>D",
    "<cmd>lua vim.lsp.buf.type_definition()<CR>",
    opts
  )
  buf_set_keymap("n", "<space>lr", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
  buf_set_keymap(
    "n",
    "<space>la",
    "<cmd>lua vim.lsp.buf.code_action()<CR>",
    opts
  )
  buf_set_keymap(
    "n",
    "gr",
    "<cmd>lua vim.lsp.buf.references({includeDeclaration = false})<CR>",
    opts
  )
  buf_set_keymap(
    "n",
    "<space>lf",
    "<cmd>lua vim.lsp.buf.formatting()<CR>",
    opts
  )
  buf_set_keymap(
    "v",
    "<space>la",
    "<cmd>lua vim.lsp.buf.range_code_action()<CR>",
    opts
  )
  if vim.lsp.codelens and client.resolved_capabilities["code_lens"] then
    vim.cmd [[
      augroup lsp_document_highlight
        autocmd! * <buffer>
        autocmd BufEnter,CursorHold,InsertLeave <buffer> lua vim.lsp.codelens.refresh()
      augroup END
    ]]
    buf_set_keymap(
      "n",
      "<leader>ll",
      "<cmd>lua vim.lsp.codelens.run()<CR>",
      opts
    )
  end

  vim.api.nvim_command [[autocmd CursorHold  <buffer> lua vim.lsp.buf.document_highlight()]]
  -- vim.api.nvim_command [[autocmd CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()]]
  vim.api.nvim_command [[autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()]]
  vim.api.nvim_command [[autocmd InsertEnter <buffer> lua vim.lsp.buf.clear_references()]]
  vim.api.nvim_command [[autocmd WinLeave <buffer> lua vim.lsp.buf.clear_references()]]
end

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.documentationFormat = {
  "markdown",
  "plaintext",
}
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.textDocument.completion.completionItem.preselectSupport = true
capabilities.textDocument.completion.completionItem.insertReplaceSupport = true
capabilities.textDocument.completion.completionItem.labelDetailsSupport = true
capabilities.textDocument.completion.completionItem.deprecatedSupport = true
capabilities.textDocument.completion.completionItem.commitCharactersSupport =
  true
capabilities.textDocument.completion.completionItem.tagSupport = {
  valueSet = { 1 },
}
capabilities.textDocument.completion.completionItem.resolveSupport = {
  properties = {
    "documentation",
    "detail",
    "additionalTextEdits",
  },
}

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
  border = "single",
})

vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
  vim.lsp.handlers.signature_help,
  {
    border = "single",
  }
)

local function location_handler(_, result, ctx, _)
  if result == nil or vim.tbl_isempty(result) then
    return nil
  end

  -- textDocument/definition can return Location or Location[]
  -- https://microsoft.github.io/language-server-protocol/specifications/specification-current/#textDocument_definition

  if vim.tbl_islist(result) then
    util.jump_to_location(result[1])

    if #result > 1 then
      util.set_qflist(util.locations_to_items(result))
      vim.api.nvim_command "botright copen"
    end
  else
    util.jump_to_location(result)
  end
end

vim.lsp.handlers["textDocument/definition"] = location_handler

-- suppress error messages from lang servers
vim.notify = function(msg, log_level, _opts)
  if msg:match "exit code" then
    return
  end
  if log_level == vim.log.levels.ERROR then
    vim.api.nvim_err_writeln(msg)
  else
    vim.api.nvim_echo({ { msg } }, true, {})
  end
end

-- requires a file containing user's lspconfigs

local addlsp_confs =
  require("core.utils").load_config().plugins.options.lspconfig.setup_lspconf

if string.len(addlsp_confs) ~= 0 then
  require(addlsp_confs).setup_lsp(on_attach, capabilities)
end
