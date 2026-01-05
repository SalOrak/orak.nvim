local Template = require''

local M = {}

local config = {
    path = "~/personal/notes/organize/",
    templates = {
        path = "templates/",
        week = "Weekly.md",
        monthly = "Monthly.md",
        yearly = "Yearly.md"
        opts = {
        }
    },
    index= "Index.md",
    inbox = "Inbox.md"
}

M.setup = function(opts)
    config = vim.tbl_deep_extend('force', config, opts)
end

local open_path = function(path, file, template_file)

    local norm_path = vim.fs.normalize(path)
    local real_path = vim.uv.fs_realpath(norm_path) -- Always resolve symlinks

    --- If path does not exists we create it. 
    --- Only the directory path, not the file
    if not real_path then 
        vim.fn.mkdir(real_path, "p")
    end

    local path_stat = vim.uv.fs_stat(real_path)

    --- If the path does not exists, we create it (again?)
    if not path_stat then
        vim.fn.mkdir(real_path, "p")
    end


    local file_path = string.format("{}/{}", real_path, file)

    local file_stat = vim.uv.fs_stat(file_path)
    --- If the file does not exist, we copy the template one
    if not file_stat then
        local template_file = string.format("{}/{}/{}", M.path, M.templates.path, template_file)
        local copied = vim.uv.fs_copyfile(template_file, file_path)
        if not copied then
            vim.notify(
                string.format("Error while copying template file {} to {}.", template_file, file_path), 
                vim.log.levels.ERROR)
        end

    end
 
    local cmd_open= string.format("e {}", file_path)
    vim.cmd(cmd_open)
end

M.open_year = function()
    local year = os.date('%Y')
    local year_folder = M.path .. year

    open_path(year_folder, M.index, M.templates.yearly)
end

M.open_month= function()
    local month = os.date('%Y/%B')
    local month_folder = M.path .. month

    open_path(month_folder, M.index, M.templates.monthly)
end

M.open_week = function()
    local week = os.date('%Y/%m')
    local num_week = os.date('%V') % 4
    local week_file = string.format("/Week-{}.md", num_week)
    local week_folder = M.path .. week 
    open_path(week_folder, week_file, M.templates.week)
end

M.open_inbox = function()
    local year = os.date('%Y')
    local inbox_path = string.format("{}/{}",M.path, year)
    open_path(inbox_path, M.inbox)
end
