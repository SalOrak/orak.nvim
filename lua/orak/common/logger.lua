--- Common Logger class. 

---@class Logger
local Logger = {}
Logger.__index = Logger

Logger.verbosity = vim.log.levels.WARN
Logger.prefix = "[Log]: "


--- Creates a new Logger. 
--- @param opts table Options for the logger.
    --- @param verbosity vim.log.levels Minimum verbosity
    --- @param prefix string Prefix string. Defaults to "[Log]: ".
function Logger.new(opts)
    local logger = setmetatable({
        verbosity = opts.verbosity or Logger.verbosity,
        prefix = opts.prefix or Logger.prefix
    }, Logger)
    return logger
end

--- Logging using `vim.notify` and `vim.log.levels` but all logs
--- are tied to the Whaler instance. 
--- It only executes when the level param is higher or equal than
--- then verbosity set to the logger.
--- @param msg string? The message to display
--- @param level vim.log.levels The level of the message. 
--- See `vim.log.levels`.
function Logger:log(msg, level)
    --- Don't execute if level is below expected
    if self.verbosity > level then
        return
    end

    local message = string.format("%s%s", self.prefix, msg)

    --- TODO: Should it be `vim.notify_once` instead?
    vim.notify(message, level)
end


--- Execute log() with level set to TRACE
--- @param msg string? The message to display
function Logger:trace(msg)
    self:log(msg, vim.log.levels.TRACE)
end

--- Execute log() with level set to DEBUG
--- @param msg string? The message to display
function Logger:debug(msg)
    self:log(msg, vim.log.levels.DEBUG)
end

--- Execute log() with level set to INFO
--- @param msg string? The message to display
function Logger:info(msg)
    self:log(msg, vim.log.levels.INFO)
end

--- Execute log() with level set to WARN
--- @param msg string? The message to display
function Logger:warn(msg)
    self:log(msg, vim.log.levels.WARN)
end

--- Execute log() with level set to ERROR
--- @param msg string? The message to display
function Logger:error(msg)
    self:log(msg, vim.log.levels.ERROR)
end

--- Changes the verbosity of the logger instance. 
---@param level vim.log.levels The new verbosity level
function Logger:set_verbosity(level)
    if not vim.tbl_contains(vim.log.levels, level) then
        self:err(string.format(
            "Could not change verbosity."
            .. "Level %s is not a valid level"
            .. "See `vim.log.levels`.", level))
        return
    end

    self.verbosity = level
end

return Logger
