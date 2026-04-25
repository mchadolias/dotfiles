-- Rafi's lazy.nvim initialization
-- https://github.com/rafi/vim-config

-- Clone lazy.nvim if not already installed.
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
vim.uv = vim.uv or vim.loop
if not vim.uv.fs_stat(lazypath) then
	print('Installing lazy.nvim…')
	-- stylua: ignore
	vim.fn.system({ 'git', 'clone', '--filter=blob:none', 'https://github.com/folke/lazy.nvim.git', '--branch=stable', lazypath })
end
vim.opt.rtp:prepend(vim.env.LAZY or lazypath)

-- Load user options from lua/config/setup.lua
local user_lazy_opts = {}
local ok, user_setup = pcall(require, 'config.setup')
if ok and user_setup.lazy_opts then
	user_lazy_opts = user_setup.lazy_opts() or {}
end

-- Validate if lua/plugins/ or lua/plugins.lua exist.
local user_path = vim.fn.stdpath('config') .. '/lua'
local has_user_plugins = vim.uv.fs_stat(user_path .. '/plugins') ~= nil
	or vim.uv.fs_stat(user_path .. '/plugins.lua') ~= nil

-- Load rafi.config.* after lazyvim's base files:
-- $XDG_DATA_HOME/nvim/lazy/LazyVim/lua/lazyvim/config/options.lua
-- $XDG_DATA_HOME/nvim/lazy/LazyVim/lua/lazyvim/config/autocmds.lua
-- $XDG_DATA_HOME/nvim/lazy/LazyVim/lua/lazyvim/config/keymaps.lua
for _, name in pairs({ 'options', 'autocmds', 'keymaps' }) do
	vim.api.nvim_create_autocmd('User', {
		group = vim.api.nvim_create_augroup('rafi.' .. name, { clear = true }),
		pattern = 'LazyVim' .. name:sub(1, 1):upper() .. name:sub(2) .. 'Defaults',
		once = true,
		callback = function()
			local mod = 'rafi.config.' .. name
			if require('lazy.core.cache').find(mod)[1] then
				LazyVim.try(function()
					require(mod)
				end, { msg = 'Failed loading ' .. mod })
			end
			if name == 'options' then
				require('rafi.config').setup()
			end
		end,
	})
end

local has_git = vim.fn.executable('git') == 1

-- Start lazy.nvim plugin manager.
require('lazy').setup(vim.tbl_extend('keep', user_lazy_opts, {
	spec = {
		-- LazyVim framework.
		{
			'LazyVim/LazyVim',
			version = '*',
			priority = 10000,
			lazy = false,
			cond = true,
			import = 'lazyvim.plugins',
			---@type LazyVimOptions
			opts = {
				colorscheme = function() end,
				news = { lazyvim = false },

				-- stylua: ignore
				icons = {
					misc = {
						git = ' ',
					},
					status = {
						git = {
							added    = '₊', --  ₊
							modified = '∗', --  ∗
							removed  = '₋', --  ₋
						},
						diagnostics = {
							error = ' ',
							warn  = ' ',
							info  = ' ',
							hint  = ' ',
						},
						filename = {
							modified = '+',
							readonly = '🔒',
							zoomed   = '🔎',
						},
					},
				},
			},
		},
		{ import = 'rafi.plugins' },
		has_user_plugins and { import = 'plugins' } or nil,
	},
	defaults = { lazy = true, version = false },
	dev = { path = vim.fn.stdpath('config') .. '/dev' },
	install = { missing = has_git, colorscheme = {} },
	checker = { enabled = has_git, notify = false },
	change_detection = { notify = false },
	ui = {
		size = { width = 0.8, height = 0.85 },
		border = 'rounded',
		wrap = false,
	},
	diff = { cmd = 'terminal_git' },
	performance = {
		rtp = {
			disabled_plugins = {
				'gzip',
				'vimballPlugin',
				'matchit',
				'matchparen',
				'2html_plugin',
				'tohtml',
				'tarPlugin',
				'netrwPlugin',
				'tutor',
				'zipPlugin',
			},
		},
	},
}))

-- Enjoy!
