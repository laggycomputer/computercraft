local args = {...}

local filename = args[1] or os.getComputerLabel()

os.setComputerLabel(filename)
settings.set("list.show_hidden", true)
settings.save()

local fp = fs.open("/startup", "w+")
fp.write('shell.run("/computercraft/' .. filename .. '")')

io.write("ok, " .. filename .. " installed\n")