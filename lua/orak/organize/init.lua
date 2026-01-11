local Template = require'orak.common.template'
local Logger = require'orak.common.logger'
local File = require'orak.common.file'

local M = {}

local yearly = Template.new({ enclose = "+", eq = "="})
                :withHeader("creation-date", "{date:%d-%m-%Y}") 
                :withBody("# {date:%Y}\n")
local monthly = Template.new({ enclose = "+", eq = "="}) 
                :withHeader("creation-date", "{date:%d-%m-%Y}")
                :withBody("# {date:%B} monthly goals\n")
local weekly = Template.new({enclose = "+", eq = "="})
                :withHeader("creation-date", "{date:%d-%m-%Y}")
                :withBody("# Week {week}\n")

local inbox = Template.new({enclose = "+", eq = "="})
                :withHeader("creation-date", "{date:%d-%m-%Y}")
                :withBody("# Inbox \n")

local config = {
    path = "~/.organize/",
    template = {
        set = {
            yearly = yearly,
            monthly = monthly,
            weekly = weekly,
            inbox = inbox,
        },
        opts = {}
    },
    logger = {
        verbosity = vim.log.levels.WARN,
        prefix = "[Organize]: ",
    },
    index= "Index.md",
    inbox = "Inbox.md"
}

M.setup = function(opts)
    config = vim.tbl_deep_extend('force', config, opts)

    config.template.set = vim.tbl_deep_extend('force', config.template.set, opts.template.set or {})

    config.template.opts = vim.tbl_deep_extend('force', config.template.opts, opts.template.opts or {})

    -- Common classes
    config._logger = Logger.new(opts.logger or {})

    --- Metatable disappears when merging tables.
    --- We just re-insert the metatables for each set.
    for k,v in pairs(config.template.set) do
        config.template.set[k] = setmetatable(v, Template)
    end
end

M._get_config = function()
    return config
end


--- @return template Template template instance
M.get_template = function(template_type)
    local filename = config.template.set[template_type]

    if not filename then
        local msg = string.format("Template type %s not found. Possible keys are: '%s", template_type, vim.fn.join(vim.tbl_keys(config.template.set), "', '"))
        config._logger:error(msg)
        return nil
    end

    return filename
end

--- @param path string Path to create and use as base path.
--- @param file string Filename to open
--- @param template_type TEMPLATE_TYPES Template type to use
local open_path = function(path, file, template_type)

    local norm_path = vim.fs.normalize(path)
    local path_stat = vim.uv.fs_stat(norm_path)

    --- If path does not exists we create it. 
    --- Only the directory path, not the file
    if not path_stat then 
        vim.fn.mkdir(norm_path, "p")
    end


    local file_path = string.format("%s/%s", norm_path, file)

    local file_stat = vim.uv.fs_stat(file_path)

    --- If the file does not exist, we generate the template one
    if not file_stat then
        local template_preset = M.get_template(template_type)
        if not template_preset  then
            config._logger:error(string.format("No template found for %s", template_type))
            return
        end
        template_preset:setOpts(config.template.opts or {})
        File.writeFile(file_path, template_preset:build())
    end

    local cmd_open= string.format("e %s", file_path)
    vim.cmd(cmd_open)
end


---@return base_path string Returns the base path to the organization directory.
M.get_base_path = function()
	return config.path
end

M.get_year_path = function()
	local year = os.date('%Y')
    local year_folder = string.format("%s/%s", config.path, year)
	return year_folder
end

M.get_month_path = function()
	local year = M.get_year_path()
	local month = os.date('%B'):gsub("^%l", string.upper)
    local month_folder = year .. "/" .. month
	return month_folder
end

M.get_week_path = function()
	--- Because the Week files are in the same folder as the month file,
	--- it just returns the same thing
	return M.get_month_path()
end

M.get_week_number = function()
	--- Sunday as the first day of the week
	--- Add 1 because %U starts at Week 0.
    local num_week = (os.date('%U') + 1) % 4
	return num_week
end

M.get_week_file_path = function()
	local week_folder = M.get_week_path()
    local num_week = M.get_week_number()
	return string.format("%s/Week-%s.md", week_folder, num_week)
end

M.open_year = function()
    open_path(M.get_year_path(), config.index, "yearly")
end

M.open_month= function()
    open_path(M.get_month_path(), config.index, "monthly")
end

M.open_week = function()
    local num_week = M.get_week_number()
    local week_file = string.format("Week-%s.md", num_week)
    open_path(M.get_week_path(), week_file, "weekly")
end

---@param path string Path to the directory where the file lives relative to the
---configuration path `config.path`. Can be an empty string
---@param file string Name of the file to open
---@param type string Name of the type. Must exist in `config.template.set`. It
---is dynamically populated by the user.
M.open_custom = function(path, file, type)
	local p = string.format("%s/%s", config.path, path)
    open_path(p, file, type)
end

M.open_inbox = function()
    local year = os.date('%Y')
    local inbox_path = string.format("%s/%s",config.path, year)
    open_path(inbox_path, config.inbox, "inbox")
end

return M
