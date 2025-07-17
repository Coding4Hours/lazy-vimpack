local M = {}

local augroup = vim.api.nvim_create_augroup('lazy-vimpack', {})

local function value_or_func(val, ...)
	if type(val) ~= 'function' then
		return val
	end

	return val(...)
end

local function do_add(plugin)
	if value_or_func(plugin.enabled) == false then
		return
	end

	if value_or_func(plugin.cond, plugin) == false then
		return
	end

	if type(plugin.init) == 'function' then
		plugin.init(plugin)
	end

	for _, plug in ipairs(plugin.dependencies or {}) do
		do_add(plug)
	end

	if plugin.dir ~= nil then
		vim.opt.rtp:append(plugin.dir)
	else
		---@type vim.pack.Spec
		local spec = {
			src = plugin.src,
			name = plugin.name,
			version = plugin.version,
		}
		vim.pack.add({ spec })
	end

	if plugin.config == true and plugin.opts == nil then
		plugin.opts = {}
	end

	local opts = value_or_func(plugin.opts, plugin)
	if type(opts) == 'table' then
		if not plugin.main then
			error('opts requires main to be set')
		end
		require(plugin.main).setup(opts)
	elseif type(plugin.config) == 'function' then
		plugin.config()
	end
end

local function setup_autocmd(plugin, event, pattern)
	vim.api.nvim_create_autocmd(event, {
		once = true,
		pattern = pattern,
		group = augroup,
		desc = 'lazy-load plugins',
		callback = function()
			do_add(plugin)
		end,
	})
end

function M.add(plugins)
	if type(plugins) == 'string' then
		-- require that dir and load plugins
	end
	for _, plugin in ipairs(plugins) do
		if type(plugin) == 'string' then
			plugin = { src = plugin }
		end
		if plugin[1] then
			plugin.src = plugin[1]
		end

		if plugin.event ~= nil then
			setup_autocmd(plugin, plugin.event)
		end
		if plugin.ft ~= nil then
			setup_autocmd(plugin, 'FileType', plugin.ft)
		end
		if vim.F.if_nil(plugin.event, plugin.ft, plugin.lazy) == nil then
			do_add(plugin)
		end
	end
end

local function gh(repo)
	return 'https://github.com/' .. repo
end

M.add({
	{ dir = '/Users/yochem/Documents/chime.nvim' },
	gh 'yochem/jq-playground.nvim',
	{ src = gh 'yochem/prolog.vim',              ft = 'prolog' },
	{
		src = gh 'luukvbaal/statuscol.nvim',
		main = 'statuscol',
		config = function()
			local builtin = require("statuscol.builtin")
			vim.o.number = true
			vim.o.relativenumber = true
			require("statuscol").setup({
				relculright = true,
				ft_ignore = { "qf" },
				segments = {
					{
						sign = {
							namespace = { "jumpsigns", "diagnostic.signs" },
							maxwidth = 1,
							colwidth = 1,
						},
						click = "v:lua.ScSa",
					},
					{ text = { builtin.foldfunc, " " }, click = "v:lua.ScFa" },
					{ text = { builtin.lnumfunc },      click = "v:lua.ScLa" },
					{
						sign = {
							namespace = { "gitsign" },
							maxwidth = 1,
							colwidth = 1,
							fillchar = "│",
							fillcharhl = "@comment",
						},
						click = "v:lua.ScSa",
					},
				},
			})
		end
	},
	gh 'folke/trouble.nvim',
	{ gh 'mcauley-penney/visual-whitespace.nvim', event = 'InsertEnter' },
	{ src = gh 'nvim-treesitter/nvim-treesitter',       version = 'master' },
})



return M
