
local M = {
	term_bufnr = -1,
	term_chan = nil,
	last_edited_bufnr = -1,
	jobid = -1,
}

local listed_bufs = function()
	local bufs = vim.api.nvim_list_bufs()
	local listed_bufs = {}
	for _,bufnr in pairs(bufs) do
		if vim.api.nvim_buf_is_loaded(bufnr) then
			table.insert(listed_bufs, bufnr)
		end
	end

	return listed_bufs
end

local bufnr_is_term = function(bufnr) 
	return vim.bo[bufnr].buftype == "terminal"
end


local non_term_bufs = function()
	local bufs = listed_bufs()
	local non_term_bufs = {}
	for _,buf in pairs(bufs) do
		if not bufnr_is_term(buf) then
			table.insert(non_term_bufs, buf)
		end
	end
	return non_term_bufs
end

M._terminal_create = function()
	local bufnr = vim.api.nvim_create_buf(true, false)
	vim.api.nvim_set_current_buf(bufnr)
	vim.cmd("term")
	vim.bo[bufnr].modifiable = true

	return bufnr
end


M._terminal_job = function()
	local jobid = vim.fn.jobstart({"nvim", "-h"}, {"term" = true})
	M.jobid = jobid
	return jobid
end

M.toggle_terminal = function()
	local bufnr = vim.api.nvim_get_current_buf()
	local is_term = bufnr_is_term(bufnr)
	if is_term then
		if vim.api.nvim_buf_is_valid(M.last_edited_bufnr) then
			vim.api.nvim_set_current_buf(M.last_edited_bufnr)
		else
			local buffers = non_term_bufs()
			if #buffers >= 0 then
				vim.api.nvim_set_current_buf(buffers[1])
			end
		end
	else
		M.last_edited_bufnr = bufnr
		if vim.api.nvim_buf_is_valid(M.term_bufnr) then
			vim.api.nvim_set_current_buf(M.term_bufnr)
		else
			local term_buf = M._terminal_create()
			M.term_bufnr = term_buf
		end
	end
end
