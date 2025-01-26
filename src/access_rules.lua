-- forum/src/access_rules.lua
-- Define access rules and handle bit masks
-- Copyright (C) 2025  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

---All privileges
---@type { striing: integer }
---@enum forum.ACCESS_RULES_VALUES
forum.ACCESS_RULES = {
    READ = 0x0001,

    NEW_THREAD = 0x0002,
    NEW_THREAD_SKIP_REVIEW = 0x0004,
    NEW_THREAD_REVIEW = 0x0008,
    THREAD_EDIT_HIDE = 0x0010,

    NEW_COMMENT = 0x0020,
    NEW_COMMENT_SKIP_REVIEW = 0x0040,
    NEW_COMMENT_REVIEW = 0x0080,
    COMMENT_EDIT_HIDE = 0x0100,

    FORUM_CHANGE_SETTINGS = 0x0200,
    FORUM_ACCESS_RULES = 0x0400,
}

---@type { integer: forum.ACCESS_RULES_VALUES }
forum.ACCESS_VALUES_TO_RULES = table.key_value_swap(forum.ACCESS_RULES)

---Adds the given privilege to the given bitmask
---@param bitmask integer
---@param privileges forum.ACCESS_RULES_VALUES[]
---@return integer
---@overload fun(bitmask: integer, privilege: forum.ACCESS_RULES_VALUES): integer
function forum.add_privileges(bitmask, privileges)
    if type(privileges) == "number" then
        return forum.add_privileges(bitmask, { privileges })
    end
    for _, privilege in ipairs(privileges) do
        bitmask = bit.bor(bitmask, privilege)
    end
    return bitmask
end

---Removes the given privilege from the given bitmask
---@param bitmask integer
---@param privileges forum.ACCESS_RULES_VALUES[]
---@return integer
---@overload fun(bitmask: integer, privilege: forum.ACCESS_RULES_VALUES): integer
function forum.remove_privileges(bitmask, privileges)
    if type(privileges) == "number" then
        return forum.remove_privileges(bitmask, { privileges })
    end
    for _, privilege in ipairs(privileges) do
        bitmask = bit.band(bitmask, bit.bnot(privilege))
    end
    return bitmask
end

---Checks if the given bitmask has the given privileges
---@param bitmask integer
---@param privileges forum.ACCESS_RULES_VALUES[]
---@return boolean
---@return forum.ACCESS_RULES_VALUES[] missing_privileges
---@overload fun(bitmask: integer, privilege: forum.ACCESS_RULES_VALUES): boolean, forum.ACCESS_RULES_VALUES[]
function forum.has_privileges(bitmask, privileges)
    if type(privileges) == "number" then
        return forum.has_privileges(bitmask, { privileges })
    end
    local missing_privileges = {}
    for _, privilege in ipairs(privileges) do
        if bit.band(bitmask, privilege) == 0 then
            table.insert(missing_privileges, privilege)
        end
    end
    return #missing_privileges == 0, missing_privileges
end
