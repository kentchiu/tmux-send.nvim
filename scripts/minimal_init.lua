-- Minimal init.lua for testing
local plenary_path = vim.fn.stdpath("data") .. "/site/pack/packer/start/plenary.nvim"
local is_not_a_directory = vim.fn.isdirectory(plenary_path) == 0

if is_not_a_directory then
  vim.fn.system({
    "git",
    "clone",
    "--depth=1",
    "https://github.com/nvim-lua/plenary.nvim",
    plenary_path,
  })
end

vim.opt.rtp:append(".")
vim.opt.rtp:append(plenary_path)

vim.cmd("runtime plugin/plenary.vim")
require("plenary.busted")