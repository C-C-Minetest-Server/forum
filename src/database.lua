-- forum/src/database.lua
-- Internal database codes
-- Copyright (C) 2025  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

local _int = ...
local logger = _int.logger:sublogger("database")
local pgmoon = _int.pgmoon

local conn_options = {}
do
    local raw_conn_options = core.settings:get("forum.pg_connection")
    for key, value in string.gmatch(raw_conn_options, "(%w+)=([^%s]+)") do
        conn_options[key] = value
    end
end

local postgres = _int.func_with_IE_env(pgmoon.new, conn_options)
_int.postgres = postgres

do
    local success, err = _int.func_with_IE_env(postgres.connect, postgres)
    if not success then
        logger:raise("Connect to database failed: %s", err)
    end
end

function _int.query(...)
    return _int.func_with_IE_env(postgres.query, postgres, ...)
end

do
    -- Load initial schema
    local file = assert(io.open(core.get_modpath("travelnet_redo") .. "/init.sql"))
    local q = file:read("*a")
    file:close()

    local res, err = _int.query(q)
    if not res then
        logger:raise("Load initial schema failed: %s", err)
    end
end

postgres:settimeout(2000) -- 2 seconds

-- Methods that directly read/write the database
local _db = {}
_int.database = _db

-- Helpers
local f = string.format
local esc = function(...)
    return postgres:escape_literal(...)
end

-- Read functions

function _db.get_forum_group_by_id(group_id)
    local q = f([[
        SELECT * FROM forum_groups WHERE group_id = %d
    ]], group_id)
    return _int.query(q)
end

function _db.get_forum_groups_by_parent(parent_id)
    local q = f([[
        SELECT * FROM forum_groups WHERE parent_id = %d
    ]], parent_id)
    return _int.query(q)
end

function _db.get_forums_by_group(group_id)
    local q = f([[
        SELECT * FROM forums WHERE group_id = %d
    ]], group_id)
    return _int.query(q)
end

function _db.get_user_access_rules(forum_id, player_name)
    local q = f([[
        SELECT * FROM user_access_rules WHERE forum_id = %d AND player_name = %s
    ]], forum_id, esc(player_name))
    return _int.query(q)
end

function _db.get_threads_by_forum(forum_id)
    local q = f([[
        SELECT * FROM threads WHERE forum_id = %d
    ]], forum_id)
    return _int.query(q)
end

function _db.get_posts_by_thread(thread_id)
    local q = f([[
        SELECT * FROM posts WHERE thread_id = %d
    ]], thread_id)
    return _int.query(q)
end

-- Write functions

function _db.create_forum_group(name, description, parent_id)
    if parent_id == nil then
        parent_id = 0
    end
    local q = f([[
        INSERT INTO forum_groups (parent_id, name, description)
        VALUES (%d, %s, %s) RETURNING group_id
    ]], parent_id, esc(name), esc(description))
    local res, err = _int.query(q)
    if not res then
        return nil, err
    end
    return res[1].group_id
end

function _db.modify_forum_group(group_id, updates)
    local update_clauses = {}
    if updates.name ~= nil then
        table.insert(update_clauses, f("name = %s", esc(updates.name)))
    end
    if updates.description ~= nil then
        table.insert(update_clauses, f("description = %s", esc(updates.description)))
    end
    if #update_clauses == 0 then
        return nil, "No fields to update"
    end
    local q = f([[
        UPDATE forum_groups SET %s
        WHERE group_id = %d
    ]], table.concat(update_clauses, ", "), group_id)
    return _int.query(q)
end

function _db.delete_forum_group(group_id)
    local q = f([[
        DELETE FROM forum_groups WHERE group_id = %d
    ]], group_id)
    return _int.query(q)
end

function _db.create_forum(group_id, name, description, forum_owner, forum_access_rules_default)
    local q = f([[
        INSERT INTO forums (group_id, name, description, forum_owner, forum_access_rules_default)
        VALUES (%d, %s, %s, %s, %d) RETURNING forum_id
    ]], group_id, esc(name), esc(description), esc(forum_owner), forum_access_rules_default)
    local res, err = _int.query(q)
    if not res then
        return nil, err
    end
    return res[1].forum_id
end

function _db.modify_forum(forum_id, updates)
    local update_clauses = {}
    if updates.name ~= nil then
        table.insert(update_clauses, f("name = %s", esc(updates.name)))
    end
    if updates.description ~= nil then
        table.insert(update_clauses, f("description = %s", esc(updates.description)))
    end
    if updates.forum_owner ~= nil then
        table.insert(update_clauses, f("forum_owner = %s", esc(updates.forum_owner)))
    end
    if updates.forum_access_rules_default ~= nil then
        table.insert(update_clauses, f("forum_access_rules_default = %d", updates.forum_access_rules_default))
    end
    if #update_clauses == 0 then
        return nil, "No fields to update"
    end
    local q = f([[
        UPDATE forums SET %s
        WHERE forum_id = %d
    ]], table.concat(update_clauses, ", "), forum_id)
    return _int.query(q)
end

function _db.hide_forum(forum_id)
    local q = f([[
        UPDATE forums SET hidden = TRUE WHERE forum_id = %d
    ]], forum_id)
    return _int.query(q)
end

function _db.get_user_acccess_rules(forum_id, player_name)
    local q = f([[
        SELECT * FROM user_access_rules WHERE forum_id = %d AND player_name = %s
    ]], forum_id, esc(player_name))
    return _int.query(q)
end

function _db.set_user_access_rule(forum_id, player_name, access_rules)
    local q = f([[
        INSERT INTO user_access_rules (forum_id, player_name, access_rules)
        VALUES (%d, %s, %d)
        ON CONFLICT (forum_id, player_name) DO UPDATE SET access_rules = EXCLUDED.access_rules
    ]], forum_id, esc(player_name), access_rules)
    return _int.query(q)
end

function _db.delete_user_access_rule(forum_id, player_name)
    local q = f([[
        DELETE FROM user_access_rules WHERE forum_id = %d AND player_name = %s
    ]], forum_id, esc(player_name))
    return _int.query(q)
end

function _db.create_thread(forum_id, thread_title, thread_time, thread_first_post_poster, thread_pending_review)
    local q = f([[
        INSERT INTO threads (
            forum_id, thread_title, thread_time, thread_first_post_poster, thread_pending_review
        )
        VALUES (%d, %s, %d, %s, %s) RETURNING thread_id
    ]], forum_id, esc(thread_title), thread_time, esc(thread_first_post_poster), esc(thread_pending_review))
    local res, err = _int.query(q)
    if not res then
        return nil, err
    end
    return res[1].thread_id
end

function _db.modify_thread(thread_id, updates)
    local update_clauses = {}
    if updates.thread_first_post_id ~= nil then
        table.insert(update_clauses, f("thread_first_post_id = %d", updates.thread_first_post_id))
    end
    if updates.thread_title ~= nil then
        table.insert(update_clauses, f("thread_title = %s", esc(updates.thread_title)))
    end
    if updates.thread_time ~= nil then
        table.insert(update_clauses, f("thread_time = %d", updates.thread_time))
    end
    if updates.thread_pending_review ~= nil then
        table.insert(update_clauses, f("thread_pending_review = %s", esc(updates.thread_pending_review)))
    end
    if #update_clauses == 0 then
        return nil, "No fields to update"
    end
    local q = f([[
        UPDATE threads SET %s
        WHERE thread_id = %d
    ]], table.concat(update_clauses, ", "), thread_id)
    return _int.query(q)
end

function _db.hide_thread(thread_id)
    local q = f([[
        UPDATE threads SET hidden = TRUE WHERE thread_id = %d
    ]], thread_id)
    return _int.query(q)
end

function _db.create_post(thread_id, post_poster_name, post_time, post_text, post_parser, post_pending_review)
    local q = f([[
        INSERT INTO posts (
            thread_id, post_poster_name, post_time, post_text,
            post_parser, post_pending_review
        )
        VALUES (%d, %s, %d, %s, %s, %s) RETURNING post_id
    ]], thread_id, esc(post_poster_name), post_time, esc(post_text), esc(post_parser), esc(post_pending_review))
    local res, err = _int.query(q)
    if not res then
        return nil, err
    end
    return res[1].post_id
end

function _db.modify_post(post_id, updates)
    local update_clauses = {}
    if updates.post_text ~= nil then
        table.insert(update_clauses, f("post_text = %s", esc(updates.post_text)))
    end
    if updates.post_parser ~= nil then
        table.insert(update_clauses, f("post_parser = %s", esc(updates.post_parser)))
    end
    if updates.post_pending_review ~= nil then
        table.insert(update_clauses, f("post_pending_review = %s", esc(updates.post_pending_review)))
    end
    if #update_clauses == 0 then
        return nil, "No fields to update"
    end
    local q = f([[
        UPDATE posts SET %s
        WHERE post_id = %d
    ]], table.concat(update_clauses, ", "), post_id)
    return _int.query(q)
end

function _db.hide_post(post_id)
    local q = f([[
        UPDATE posts SET hidden = TRUE WHERE post_id = %d
    ]], post_id)
    return _int.query(q)
end
