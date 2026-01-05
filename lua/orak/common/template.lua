---------------------------
------ Template -----------
---------------------------
--- A basic template system for generating templates with
--- runtime and extensible substitution

---@class Template
local Template = {}
Template.__index = Template

local default_opts = {
	data = {
		title = "",
		enclose = "-",
		eq = ":",
        --- substitution functions. fn(obj, opts) -> string
        --- The key of the function will be used as the substitution 
        --- pattern.
		substitution = {},
	},
	_header = "",
	_body = "",
	_pattern = "{([^:}]+):?(.-)}",
	_substitution = {
		title = function(obj, args)
			return obj.data.title
		end,
		date = function(obj, args)
			local format = "%d-%m-%Y"
			if type(opts) == "string" and args~= "" then
				format = args
			end
			return os.date(format)
		end,

		uuid = function(obj, _)
			local id, _ = vim.fn.system("uuidgen"):gsub("\n", "")
			return id
		end,
	},
}

function Template:performSubstitution(value)
	local result = value
	local res, d = string.gsub(result, self._pattern, function(t, data)
		if vim.list_contains(vim.tbl_keys(self._substitution), t) then
			return self._substitution[t](self, data)
		end
		return data
	end)
	return res
end

---@param key string Key parameter to add
---@param value string Value parameter to add that has template substitution
---@return template Template
function Template:withHeader(key, value)
	self._header = string.format("%s\n%s%s %s", self._header, key, self.data.eq, value)
	return self
end

---@param data string Any text to be sequentially added to the body
---@return template Template
function Template:withBody(data)
	self._body = string.format("%s\n%s", self._body, data)
	return self
end

---@param opts {title: string?}
---@return template Template
function Template:setOpts(opts)
	self.data = vim.tbl_deep_extend("force", self.data, opts or {})
	self._substitution = vim.tbl_deep_extend("keep", self._substitution, opts.substitution or {})
	return self
end

---@return templateData string The string substituted.
function Template:build()
	self._header = string.format("%s\n%s", self._header, string.rep(self.data.enclose, 3, ""))
	local result = string.format("%s\n%s", self._header, self._body)
	result = self:performSubstitution(result)
	return result
end

---@param opts {title: string?} options for the template (in Data)
function Template.new(opts)
	local data = vim.tbl_deep_extend("force", default_opts.data, opts)

	--- Deep copy to make sure we use a fresh instance
	--- of `default_opts` table.
	local class_data = vim.deepcopy(default_opts)
	class_data.data = data

	local template = setmetatable(class_data, Template)
	template._header = string.rep(template.data.enclose, 3, "")

	template.data = vim.tbl_deep_extend("force", template.data, opts or {})
	template._substitution = vim.tbl_deep_extend("force", template._substitution, opts.substitution or {})

	return template
end

Template.PRESET = {
	frontMatterTomlMarkdown = Template.new({ enclose = "+", eq = "=" })
		:withHeader("title", "{title}")
		:withHeader("date", "{date:%d-%m-%Y}")
		:withHeader("id", "{uuid}}")
		:withBody("# {title}"),
	frontMatterYamlMarkdown = Template.new({ enclose = "-", eq = ":" })
		:withHeader("title", "{title}")
		:withHeader("date", "{date:%d-%m-%Y}")
		:withHeader("id", "{uuid}}")
		:withBody("# {title}"),
}

return Template
