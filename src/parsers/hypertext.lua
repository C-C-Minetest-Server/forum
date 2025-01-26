-- forum/parsers/hypertext.lua
-- hypertext escape and parser
-- Copyright (C) 2025  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

local S = core.get_translator("forum")

local p = {}

local disallowed_tags = {
    "global", -- Global styles
    "tag", -- define default styles
    "action", -- action button
    "img", -- image
    "item", -- item image
}

function p.validate(text)
    for _, tag in ipairs(disallowed_tags) do
        local start = string.find(text, "<" .. tag, nil, true)
        if start and start > 1 and string.sub(text, start - 1, start - 1) ~= "\\" then
            return false, S("Disallowed tag found at @1: @2", start, "<" .. tag .. ">")
        end
    end
end

forum.parsers.hypertext = p
