-- forum/src/api.lua
-- The real APIs
-- Copyright (C) 2025  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

local _int = ...
local _db = _int.database
local logger = _int.logger:sublogger("api")

local function assert_type(name, value, expected_type)
    if type(value) ~= expected_type then
        logger:raise("Invalid type of %s (expected %s, got %s)",
            name, expected_type, type(value))
    end
    return value
end

local function assert_nil_or_type(name, value, expected_type)
    if value ~= nil then
        return assert_type(name, value, expected_type)
    end
end

---Obtain forum group metadata by its ID.
---@param id integer
---@return table? metadata

---Creates a forum group, and return its ID.
---@param name string
---@param description string
---@param parent_id integer?
---@return integer? id
function forum.create_forum_group(name, description, parent_id)
    assert_type("argument name", name, "string")
    assert_type("argument description", description, "string")
    assert_nil_or_type("argument parent_id", parent_id, "number")
    local id, err = _db.create_forum_group(name, description, parent_id)
    if not id then
        logger:error("Error while creating forum group: %s", err)
        return false
    end
    return id
end

---Modifies a forum group.
---@param id integer
---@param updates table
---@return boolean success
function forum.modify_forum_group(id, updates)
    assert_type("argument id", id, "number")
    assert_type("argument updates", updates, "table")
    assert_nil_or_type("field updates.name", updates.name, "string")
    assert_nil_or_type("field updates.description", updates.description, "string")
    local success, err = _db.modify_forum_group(id, updates)
    if not success then
        logger:error("Error while modifying forum group: %s", err)
        return false
    end
    return true
end

---Deletes a forum group.
---@param id integer
---@return boolean success
function forum.delete_forum_group(id)
    assert_type("argument id", id, "number")
    local success, err = _db.delete_forum_group(id)
    if not success then
        logger:error("Error while deleting forum group: %s", err)
        return false
    end
    return true
end

---Creates a forum, and return its ID.
---@param group_id integer
---@param name string
---@param description string
---@param forum_owner string
---@param forum_access_rules_default integer
---@return integer? id
function forum.create_forum(group_id, name, description, forum_owner, forum_access_rules_default)
    assert_type("argument group_id", group_id, "number")
    assert_type("argument name", name, "string")
    assert_type("argument description", description, "string")
    assert_type("argument forum_owner", forum_owner, "string")
    assert_type("argument forum_access_rules_default", forum_access_rules_default, "number")
    local id, err = _db.create_forum(group_id, name, description, forum_owner, forum_access_rules_default)
    if not id then
        logger:error("Error while creating forum: %s", err)
        return false
    end
    return id
end

---Modifies a forum.
---@param id integer
---@param updates table
---@return boolean success
function forum.modify_forum(id, updates)
    assert_type("argument id", id, "number")
    assert_type("argument updates", updates, "table")
    assert_nil_or_type("field updates.name", updates.name, "string")
    assert_nil_or_type("field updates.description", updates.description, "string")
    assert_nil_or_type("field updates.forum_owner", updates.forum_owner, "string")
    assert_nil_or_type("field updates.forum_access_rules_default", updates.forum_access_rules_default, "number")
    local success, err = _db.modify_forum(id, updates)
    if not success then
        logger:error("Error while modifying forum: %s", err)
        return false
    end
    return true
end

---Hides a forum.
---@param id integer
---@return boolean success
function forum.hide_forum(id)
    assert_type("argument id", id, "number")
    local success, err = _db.hide_forum(id)
    if not success then
        logger:error("Error while hiding forum: %s", err)
        return false
    end
    return true
end

---Get a user's access 

---Set a user's access rules on a forum.
---Overrides existing rules if any.

