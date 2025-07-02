local M = {}

local default_config = {
	-- Keymaps (set to false to disable default keymaps)
	keymaps = {
		indent = "<Tab>", -- Key to indent headers
		unindent = "<S-Tab>", -- Key to unindent headers
	},

	-- Maximum header level (markdown standard is 6)
	max_header_level = 6,

	-- File types to activate on
	filetypes = { "markdown", "md" },

	-- Whether to include subheadings when indenting
	include_subheadings = true,

	-- Fallback behavior when not on a header
	fallback_behavior = "indent", -- "indent" | "tab" | "none"
}

local config = vim.deepcopy(default_config)

-- ============================================================================
-- PLUGIN LOGIC
-- ============================================================================

-- Function to get the header level from a line
local function get_header_level(line)
	local header_match = line:match("^(#+)%s")
	return header_match and #header_match or 0
end

-- Function to indent a single header line
local function indent_header_line(line)
	local header_prefix = line:match("^(#+)%s")
	if header_prefix and #header_prefix < config.max_header_level then
		return "#" .. line
	end
	return line
end

-- Function to unindent a single header line
local function unindent_header_line(line)
	local header_match = line:match("^(#+)%s")
	if header_match and #header_match > 1 then
		return line:sub(2) -- Remove one #
	end
	return line
end

-- Function to find all lines that should be indented
local function find_lines_to_indent(buf, start_line)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local current_level = get_header_level(lines[start_line])

	if current_level == 0 then
		return {} -- Not a header line
	end

	local lines_to_indent = { start_line }

	-- If subheadings are disabled, only indent current line
	if not config.include_subheadings then
		return lines_to_indent
	end

	-- Look for subheadings (headers with level > current_level)
	for i = start_line + 1, #lines do
		local line = lines[i]
		local level = get_header_level(line)

		if level == 0 then
			-- Skip non-header lines
			goto continue
		elseif level <= current_level then
			-- Found a header at same or higher level, stop here
			break
		else
			-- Found a subheading, add it to the list
			table.insert(lines_to_indent, i)
		end

		::continue::
	end

	return lines_to_indent
end

-- Main function to indent markdown headers
local function indent_markdown_header()
	local buf = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local current_line = cursor[1] -- 1-indexed

	-- Get lines to indent
	local lines_to_indent = find_lines_to_indent(buf, current_line)

	if #lines_to_indent == 0 then
		-- Not on a header line, handle fallback
		if config.fallback_behavior == "tab" then
			vim.api.nvim_feedkeys("\t", "n", false)
		elseif config.fallback_behavior == "indent" then
			local pos = vim.api.nvim_win_get_cursor(0)
			vim.cmd("normal! >>")
			vim.api.nvim_win_set_cursor(0, { pos[1], pos[2] + vim.o.shiftwidth })
		end
		return
	end

	-- Get all lines from buffer
	local all_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

	-- Indent the selected lines
	for _, line_num in ipairs(lines_to_indent) do
		local line = all_lines[line_num]
		local indented_line = indent_header_line(line)
		vim.api.nvim_buf_set_lines(buf, line_num - 1, line_num, false, { indented_line })
	end
end

-- Function to unindent markdown headers
local function unindent_markdown_header()
	local buf = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local current_line = cursor[1]

	local lines_to_unindent = find_lines_to_indent(buf, current_line)

	if #lines_to_unindent == 0 then
		-- Not on a header line, handle fallback
		if config.fallback_behavior == "indent" then
			local pos = vim.api.nvim_win_get_cursor(0)
			local line = vim.api.nvim_get_current_line()
			local indent_before = vim.fn.indent(".")

			vim.cmd("normal! <<")

			local indent_after = vim.fn.indent(".")
			if indent_after < indent_before then
				-- Only adjust cursor if indentation actually changed
				vim.api.nvim_win_set_cursor(0, { pos[1], math.max(0, pos[2] - (indent_before - indent_after)) })
			else
				-- No change in indentation, restore original position
				vim.api.nvim_win_set_cursor(0, pos)
			end
		end
		return
	end

	local all_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

	for _, line_num in ipairs(lines_to_unindent) do
		local line = all_lines[line_num]
		local unindented_line = unindent_header_line(line)
		vim.api.nvim_buf_set_lines(buf, line_num - 1, line_num, false, { unindented_line })
	end
end

-- Function to set up keymaps for markdown files
local function setup_keymaps()
	if not config.keymaps then
		return
	end

	local buf = vim.api.nvim_get_current_buf()

	-- Tab to indent
	if config.keymaps.indent then
		vim.keymap.set({ "i", "n" }, config.keymaps.indent, function()
			indent_markdown_header()
		end, {
			buffer = buf,
			desc = "Indent markdown header or line",
			silent = true,
		})

		-- Also handle visual mode for consistency
		vim.keymap.set("v", config.keymaps.indent, ">gv", {
			buffer = buf,
			desc = "Indent lines",
			silent = true,
		})
	end

	-- Shift+Tab to unindent
	if config.keymaps.unindent then
		vim.keymap.set({ "n", "i" }, config.keymaps.unindent, function()
			unindent_markdown_header()
		end, {
			buffer = buf,
			desc = "Unindent markdown header or line",
			silent = true,
		})

		-- Also handle visual mode and insert mode for consistency
		vim.keymap.set("v", config.keymaps.unindent, "<gv", {
			buffer = buf,
			desc = "Unindent lines",
			silent = true,
		})
	end
end

-- ============================================================================
-- SETUP AND INITIALIZATION
-- ============================================================================

local augroup = nil

function M.setup(user_config)
	config = vim.tbl_deep_extend("force", default_config, user_config or {})
	
	-- Clear existing autocommands if they exist
	if augroup then
		vim.api.nvim_del_augroup_by_id(augroup)
	end
	
	-- Create autocommand group
	augroup = vim.api.nvim_create_augroup("MarkdownIndent", { clear = true })

	-- Set up keymaps only for specified file types
	vim.api.nvim_create_autocmd("FileType", {
		group = augroup,
		pattern = config.filetypes,
		callback = setup_keymaps,
	})
end

-- Expose functions for manual use
M.indent = indent_markdown_header
M.unindent = unindent_markdown_header
M.config = config

return M
