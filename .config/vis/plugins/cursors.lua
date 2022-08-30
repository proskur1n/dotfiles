-- Author:  https://github.com/erf/vis-cursors
-- License: MIT
-- Copyright (c) 2019-2020 Erlend Lind Madsen
local M = {}
local cursors = {}
local files = {}

-- default maxsize
M.maxsize = 1000

-- get the default system cache directory
local get_default_cache_path = function()
	local HOME = os.getenv('HOME')
	local XDG_CACHE_HOME = os.getenv('XDG_CACHE_HOME')
	local BASE = XDG_CACHE_HOME or HOME
	return BASE .. '/.vis-cursors'
end

-- default save path
M.path = get_default_cache_path()

function read_files()

	-- read file
	local file = io.open(M.path)
	if file == nil then
		return
	end

	files = {}

	-- read positions per file path
	for line in file:lines() do
		for path, pos in string.gmatch(line, '(.+)[,%s](%d+)') do
			cursors[path] = pos
			table.insert(files, path)
		end
	end

	file:close()
end

-- read cursors from file on init
local on_init = function()
	read_files()
end

-- apply cursor pos on win open
local on_win_open = function(win)

	if win.file == nil or win.file.path == nil then
		return
	end

	-- init cursor path if nil
	local pos = cursors[win.file.path]
	if pos == nil then
		cursors[win.file.path] = win.selection.pos
		return
	end

	-- set current cursor
	win.selection.pos = tonumber(pos)

	-- center view around cursor
	vis:feedkeys("zz")
end

-- set cursor pos on close
local on_win_close = function(win)

	if win.file == nil or win.file.path == nil then
		return
	end

	-- re-read files in case they've changed
	read_files()

	-- remove old occurences of current path
	for i, path in ipairs(files) do
		if path == win.file.path then
			table.remove(files, i)
		end
	end

	-- insert current path to top of files
	table.insert(files, 1, win.file.path)

	-- set cursor pos for current file path
	cursors[win.file.path] = win.selection.pos
end

-- write cursors to file on quit
local on_quit = function()

	local file = io.open(M.path, 'w+')
	if file == nil then
		return
	end

	-- buffer cursors string
	local buffer = {}
	for i, path in ipairs(files) do
		table.insert(buffer, string.format('%s,%d', path, cursors[path]))
		if M.maxsize and #buffer >= M.maxsize then
			break
		end
	end
	local output = table.concat(buffer, '\n')
	file:write(output)
	file:close()
end

vis.events.subscribe(vis.events.INIT, on_init)
vis.events.subscribe(vis.events.WIN_OPEN, on_win_open)
vis.events.subscribe(vis.events.WIN_CLOSE, on_win_close)
vis.events.subscribe(vis.events.QUIT, on_quit)

return M
