local args = {...}

local protocol = args[1]
local host = args[2]
local route = args[3]

peripheral.find("modem", rednet.open)
local recipient = rednet.lookup(protocol, host)
assert(recipient, "no host found")

assert(rednet.send(recipient, {
    route = route,
    params = nil,
}, protocol), "message not sent")

local sender, msg, protocol = rednet.receive(protocol, 10)
assert(sender, "warning: nothing recieved back")
io.write("recieved response: " .. msg .. "\n")
