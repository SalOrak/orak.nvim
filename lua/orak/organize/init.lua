local Template = require'orak.common.template'
local Logger = require'orak.common.logger'

local M = {}

local config = {
    path = "~/.organize/",
    template = {
        path = "templates/",
        files = {
            yearly = "yearly.md",
            monthly = "monthly.md",
            weekly = "weekly.md",
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

    config.template.files = vim.tbl_deep_extend('force', config.template.files, opts.template.files)


    -- Common classes
    config._template = Template.new(opts.template.opts or {})
    config._logger = Logger.new(opts.logger or {})
end


M.get_template_filename = function(template_type)
    local filename = config.template[template_type]

    if not filename then
        local msg = string.format("Template type %s not found. Possible keys are: '%s", template_type, vim.fn.join(vim.tbl_keys(config.template), "',"))
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
    local real_path = vim.uv.fs_realpath(norm_path) -- Always resolve symlinks

    --- If path does not exists we create it. 
    --- Only the directory path, not the file
    if not real_path then 
        vim.fn.mkdir(real_path, "p")
    end

    local path_stat = vim.uv.fs_stat(norm_path)

    local file_path = string.format("%s/%s", norm_path, file)

    local file_stat = vim.uv.fs_stat(file_path)
    --- If the file does not exist, we copy the template one
    if not file_stat then
        local template_filename = M.get_template_filename(template_type)
        local template_file = string.format("%s/%s/%s", config.path, config.template.path, template_filename)
        local copied = vim.uv.fs_copyfile(template_file, file_path)
        if not copied then
            config._logger:warn(string.format("Error while copying template file %s to %s.", template_file, file_path)) 
        end

    end
 
    local cmd_open= string.format("e %s", file_path)
    vim.cmd(cmd_open)
end

M.open_year = function()
    local year = os.date('%Y')
    local year_folder = config.path .. year

    open_path(year_folder, config.index, "yearly")
end

M.open_month= function()
    local month = os.date('%Y/%B')
    local month_folder = config.path .. month

    open_path(month_folder, config.index, "monthly")
end

M.open_week = function()
    local week = os.date('%Y/%m')
    local num_week = os.date('%V') % 4
    local week_file = string.format("/Week-%s.md", num_week)
    local week_folder = config.path .. week 
    open_path(week_folder, week_file, "weekly")
end

M.open_inbox = function()
    local year = os.date('%Y')
    local inbox_path = string.format("%s/%s",config.path, year)
    open_path(inbox_path, config.inbox)
end

return M
