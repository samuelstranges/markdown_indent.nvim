if vim.g.loaded_markdown_indent == 1 then
  return
end
vim.g.loaded_markdown_indent = 1

vim.api.nvim_create_user_command('MarkdownIndentSetup', function(opts)
  local config = {}
  if opts.args and opts.args ~= '' then
    config = vim.fn.json_decode(opts.args)
  end
  require('markdown-indent').setup(config)
end, {
  nargs = '?',
  desc = 'Setup markdown-indent plugin with optional config'
})