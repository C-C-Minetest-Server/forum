-- forum/init.lua
-- In-game structured discussions
-- Copyright (C) 2025  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

forum = {}

local internal = {}
internal.logger = logging.logger("forum")

---@type _G
internal.insecure = internal.logger:assert(core.request_insecure_environment(),
    "Please add forum into secure.trusted_mods.")

local insecure = internal.insecure

---@generic T
---@param func fun(...): T
---@param ... any
---@return T
function internal.func_with_IE_env(func, ...)
    -- be sure that there is no hook, otherwise one could get IE via getfenv
	insecure.debug.sethook()

	local old_thread_env = insecure.getfenv(0)
	local old_string_metatable = insecure.debug.getmetatable("")

	-- set env of thread
	-- (the loader used by insecure.require will probably use the thread env for
	-- the loaded functions)
	insecure.setfenv(0, insecure)

	-- also set the string metatable because the lib might use it while loading
	-- (actually, we probably have to do this every time we call a `require()`d
	-- function, but for performance reasons we only do it if the function
	-- uses the string metatable)
	-- (Maybe it would make sense to set the string metatable __index field
	-- to a function that grabs the string table from the thread env.)
	insecure.debug.setmetatable("", { __index = insecure.string })

	-- (insecure.require's env is neither _G, nor insecure. we need to leave it like this,
	-- otherwise it won't find the loaders (it uses the global `loaders`, not
	-- `package.loaders` btw. (see luajit/src/lib_package.c)))

	-- we might be pcall()ed, so we need to pcall to make sure that we reset
	-- the thread env afterwards
	local ok, ret = insecure.pcall(func, ...)

	-- reset env of thread
	insecure.setfenv(0, old_thread_env)

	-- also reset the string metatable
	insecure.debug.setmetatable("", old_string_metatable)

	if not ok then
		insecure.error(ret)
	end
	return ret
end

-- luacheck: ignore 211
local ngx = nil

---@module 'pgmoon'
internal.pgmoon = internal.logger:assert(internal.func_with_IE_env(insecure.require, "pgmoon"),
    "pgmoon not found. Please install it.")

local MP = core.get_modpath("forum")

for _, name in ipairs({
    "database",
	"access_rules",
	"api",
}) do
    assert(loadfile(MP .. DIR_DELIM .. "src" .. DIR_DELIM .. name .. ".lua"))(internal)
end

