local filename = arg[1] or os.getComputerLabel()

os.setComputerLabel(filename)

local fp = fs.open("/startup", "w+")
fp.write('shell.run("/computercraft/' .. filename .. '")')

io.write("ok, " .. filename .. " installed\n")