local args = {...}

local protocol = args[1]
local host = args[2]

peripheral.find("modem", rednet.open)
local recipient = rednet.lookup(protocol, host)
assert(recipient, "no host found")

assert(rednet.send(recipient, nil, protocol), "message not sent")
