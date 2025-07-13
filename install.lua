local filename = arg[1] or os.getComputerLabel()

local fp = fs.open("/startup", "w+")
fp.write('runfile("/computercraft/' .. filename .. '")')
