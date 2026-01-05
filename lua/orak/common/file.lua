local M = {}

local uv = vim.uv

M.writeFile = function(path, data)
	local fd = assert(uv.fs_open(path, "w", 438))
	local written = assert(uv.fs_write(fd, data, -1))
	local res = assert(uv.fs_close(fd))
	return res
end

return M
