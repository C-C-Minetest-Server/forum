-- forum/parsers/init.lua
-- forum content parsers
-- Copyright (C) 2025  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

forum.parsers = {}

local basepath = core.get_modpath("forum") .. "/forum/parser/"

dofile(basepath .. "hypertext.lua")
