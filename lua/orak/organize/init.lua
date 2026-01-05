local Template = require'orak.common.template'
local Logger = require'orak.common.logger'
local File = require'orak.common.file'

local M = {}

local config = {
    path = "~/.organize/",
    template = {
        set = {
            yearly = Template.new({
                enclose = "+",
                eq = "="})
                :withHeader("creation_date", "{date:%d-%m-%Y}")
                :withBody("# {date:%Y}\n"),

            monthly = Template.new({
                enclose = "+",
                eq = "="})
                :withHeader("creation_date", "{date:%d-%m-%Y}")
                :withBody("# {date:%B} monthly goals\n"),
            weekly = Template.new({
                enclose = "+",
                eq = "="})
                :withHeader("creation_date", "{date:%d-%m-%Y}")
                :withBody("# Week {week}\n")
        },
        opts = {
            substitution = {
                week = function(obj, _)
                    local week_number = os.date('%V') % 4
                    return string.format("%s", week_number)
                end,
            }
        }
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

    config.template.set = vim.tbl_deep_extend('force', config.template.set, opts.template.set)

    -- Common classes
    P(opts.template.opts)
    config._template = Template.new(opts.template.opts or {})
    config._logger = Logger.new(opts.logger or {})
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
        template_preset:setOpts({ title = ""})
        File.writeFile(file_path, template_preset:build())
    end

    local cmd_open= string.format("e %s", file_path)
    vim.cmd(cmd_open)
end

M.open_year = function()
    local year = os.date('%Y')
    local year_folder = string.format("%s/%s", config.path, year)

    open_path(year_folder, config.index, "yearly")
end

M.open_month= function()
    local month = os.date('%Y/%B')
    local month_folder = string.format("%s/%s", config.path, month)

    open_path(month_folder, config.index, "monthly")
end

M.open_week = function()
    local week = os.date('%Y/%B')
    local num_week = os.date('%V') % 4
    local week_file = string.format("Week-%s.md", num_week)
    local week_folder = string.format("%s/%s", config.path, week)
    open_path(week_folder, week_file, "weekly")
end

M.open_inbox = function()
    local year = os.date('%Y')
    local inbox_path = string.format("%s/%s",config.path, year)
    open_path(inbox_path, config.inbox)
end

return M
