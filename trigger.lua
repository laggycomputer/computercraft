local args = {...}

local protocol = args[1]
local host = args[2]
local route = args[3] or "trigger"
local payload = ""
do
    local i = 4
    while args[i] do
        payload = payload .. " " .. args[i]
        i = i + 1
    end
end

if payload == "" then
    payload = "{}"
end

peripheral.find("modem", rednet.open)
local recipient = rednet.lookup(protocol, host)
assert(recipient, "no host found")

local payload = textutils.unserializeJSON(payload)
assert(payload, "could not parse")

assert(rednet.send(recipient, {
    route = route,
    body = textutils.unserializeJSON(payload),
}, protocol), "message not sent")

local sender, msg, protocol = rednet.receive(protocol, 10)
assert(sender, "warning: nothing recieved back")
io.write("recieved response: " .. msg .. "\n")
