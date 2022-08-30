require("vis")
require("plugins/cursors")
require("plugins/commentary")

vis.events.subscribe(vis.events.INIT, function()
	-- Global configuration
	vis:command("set autoindent")
	vis:command("set ignorecase")
	vis:command("set tabwidth 4")
end)

vis.events.subscribe(vis.events.WIN_OPEN, function(win)
	-- Per window configuration
	vis:command("set number")
end)

local help = "Save file with doas / sudo"
vis:command_register("wsudo", function(...) write_as_root("sudo", ...) end, help)
vis:command_register("wdoas", function(...) write_as_root("doas", ...) end, help)

function write_as_root(program, argv, force, win, selection, range)
	if #argv == 0 then
		local file = vis.win.file
		if file.path ~= nil then
			write_as_root_single(program, file, file.path)
		else
			vis:info("Filename expected")
		end
	end
	for _, path in ipairs(argv) do
		local file = vis.win.file
		local abs = get_absolute_path(path)
		if abs ~= "" then
			write_as_root_single(program, file, abs)
		end
	end
end

function write_as_root_single(program, file, abs)
	if vis.events.emit(vis.events.FILE_SAVE_PRE, file, abs) ~= false then
		local cmd = ("%s tee %s"):format(program, abs)
		local range = {start = 0; finish = file.size}
		local status, out, err = vis:pipe(file, range, cmd)
		if status ~= 0 then
			vis:info(err)
		else
			file.modified = false
			vis.events.emit(vis.events.FILE_SAVE_POST, file, abs)
			vis:info("Write "..abs.." as root")
		end
	end
end

function get_absolute_path(path)
	local abs = io.popen("realpath "..path):read("a"):gsub("%s+$", "")
	if abs == "" then
		vis:info("Could not get absolute path: "..path)
		return ""
	end
	return abs
end
