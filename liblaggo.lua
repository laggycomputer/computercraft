local liblaggo = {}

function liblaggo.doWithContext(context, fn)
    local ok, err = false, nil

    for _ = 1, 1 do
        ok, err = fn()
        if ok then
            return ok, err
        end
    end

    io.write("failed to " .. context .. " (latest error: " .. err .. ")")
end

function liblaggo.gpsAsVector()
    local x, y, z = gps.locate()
    if x then
        return vector.new(x, y, z)
    else
        return nil
    end
end

local function _tryFrontBack(initialLoc)
    local delta

    if turtle.forward() then
        delta = liblaggo.gpsAsVector() - initialLoc
        liblaggo.standing = liblaggo.standing + delta
    elseif turtle.back() then
        delta = liblaggo.gpsAsVector() - initialLoc
        liblaggo.standing = liblaggo.standing + delta

        -- because this is backwards
        delta = delta:unm()
    end

    if not delta then
        return nil
    end

    for dir, vec in pairs(liblaggo.CARDINALS) do
        if vec:equals(delta) then
            return dir
        end
    end
end

function liblaggo.deduceFacing()
    local loc = liblaggo.gpsAsVector()
    if not loc then
        return nil, "cannot deduce facing without gps"
    end

    local solved = _tryFrontBack(loc)
    if solved then
        return solved
    end

    turtle.turnLeft()
    solved = _tryFrontBack(loc)
    if not solved then
        return nil, "stuck in all horizontal directions"
    end

    return solved
end

function liblaggo.initPathing(startLocation, startFacing)
    liblaggo.standing = startLocation and vector.new(startLocation.x, startLocation.y, startLocation.z) or
        liblaggo.gpsAsVector()
    assert(liblaggo.standing, "cannot determine location and none passed!")

    liblaggo.facing = startFacing or liblaggo.deduceFacing()
    assert(liblaggo.facing, "cannot determine facing and none passed")
end

liblaggo.CARDINALS = {
    east = vector.new(1, 0, 0),
    south = vector.new(0, 0, 1),
    west = vector.new(-1, 0, 0),
    north = vector.new(0, 0, -1),
    up = vector.new(0, 1, 0),
    down = vector.new(0, -1, 0),
}

liblaggo.FACE_RIGHT = {
    east = "south",
    south = "west",
    west = "north",
    north = "east",
}

liblaggo.FACE_LEFT = {
    east = "north",
    north = "west",
    west = "south",
    south = "east",
}

liblaggo.INVERT = {
    east = "west",
    west = "east",
    north = "south",
    south = "north",
    up = "down",
    down = "up"
}

liblaggo.NUM_SLOTS = 16

function liblaggo.isTableEmpty(obj)
    for _, _ in pairs(obj) do
        return false
    end
    return true
end

function liblaggo.face(facingTo)
    if liblaggo.facing == "up" or liblaggo.facing == "down" then
        return
    end

    if liblaggo.facing == facingTo then
        return
    end

    if liblaggo.FACE_RIGHT[liblaggo.facing] == facingTo then
        turtle.turnRight()
        liblaggo.facing = liblaggo.FACE_RIGHT[liblaggo.facing]
    end

    while liblaggo.facing ~= facingTo do
        turtle.turnLeft()
        liblaggo.facing = liblaggo.FACE_LEFT[liblaggo.facing]
    end
end

function liblaggo.doAnyDir(fnName, direction, ...)
    local fn = turtle[fnName]
    if direction == "down" then
        fn = turtle[fnName .. "Down"]
    elseif direction == "up" then
        fn = turtle[fnName .. "Up"]
    else
        liblaggo.face(direction)
    end

    return fn(...)
end

function liblaggo.step(vecOffset)
    local ok, err

    if vecOffset:equals(liblaggo.CARDINALS["up"]) then
        ok, err = turtle.up()
        if ok then
            liblaggo.standing = liblaggo.standing:add(vecOffset)
        end

        return ok, err
    end

    if vecOffset:equals(liblaggo.CARDINALS["down"]) then
        ok, err = turtle.down()
        if ok then
            liblaggo.standing = liblaggo.standing:add(vecOffset)
        end

        return ok, err
    end


    if liblaggo.CARDINALS[liblaggo.facing]:equals(vecOffset) then
        ok, err = turtle.forward()
        if ok then
            liblaggo.standing = liblaggo.standing:add(vecOffset)
        end

        return ok, err
    end

    if liblaggo.CARDINALS[liblaggo.facing]:unm():equals(vecOffset) then
        ok, err = turtle.back()
        if ok then
            liblaggo.standing = liblaggo.standing:add(vecOffset)
        end

        return ok, err
    end


    for f, v in pairs(liblaggo.CARDINALS) do
        if v:equals(vecOffset) then
            liblaggo.face(f)
        end
    end

    ok, err = turtle.forward()
    if ok then
        liblaggo.standing = liblaggo.standing:add(vecOffset)
    end

    return ok, err
end

function liblaggo.naiveMove(vecTo)
    while liblaggo.standing.y < vecTo.y do
        liblaggo.doWithContext("naive move up", function() return turtle.up() end)
    end

    while liblaggo.standing.y > vecTo.y do
        liblaggo.doWithContext("naive move down", function() return turtle.down() end)
    end

    while liblaggo.standing.x < vecTo.x do
        liblaggo.doWithContext("naive step east", function() return liblaggo.step(liblaggo.CARDINALS["east"]) end)
    end

    while liblaggo.standing.x > vecTo.x do
        liblaggo.doWithContext("naive step west", function() return liblaggo.step(liblaggo.CARDINALS["west"]) end)
    end

    while liblaggo.standing.z < vecTo.z do
        liblaggo.doWithContext("naive step south", function() return liblaggo.step(liblaggo.CARDINALS["south"]) end)
    end

    while liblaggo.standing.z > vecTo.z do
        liblaggo.doWithContext("naive step north", function() return liblaggo.step(liblaggo.CARDINALS["north"]) end)
    end
end

function liblaggo.sgn(x)
    if x < 0 then
        return -1
    elseif x > 0 then
        return 1
    else
        return 0
    end
end

function liblaggo.bruteMove(vecTo)
    local canMove = {
        x = true,
        y = true,
        z = true,
    }

    local lastFail

    local displacement = vecTo - liblaggo.standing

    while displacement:length() ~= 0 do
        if not canMove.x and not canMove.y and not canMove.z then
            return false, lastFail
        end

        while canMove.x and displacement.x ~= 0 do
            canMove.x, lastFail = liblaggo.step(vector.new(liblaggo.sgn(displacement.x), 0, 0))
            if canMove.x then
                canMove.y = true
                canMove.z = true
            end
            displacement = vecTo - liblaggo.standing
        end

        while canMove.y and displacement.y ~= 0 do
            canMove.y, lastFail = liblaggo.step(vector.new(0, liblaggo.sgn(displacement.y), 0))
            if canMove.y then
                canMove.x = true
                canMove.z = true
            end
            displacement = vecTo - liblaggo.standing
        end

        while canMove.z and displacement.z ~= 0 do
            canMove.z, lastFail = liblaggo.step(vector.new(0, 0, liblaggo.sgn(displacement.z)))
            if canMove.z then
                canMove.x = true
                canMove.y = true
            end
            displacement = vecTo - liblaggo.standing
        end
    end

    return true
end

function liblaggo.getStanding()
    return vector.new(liblaggo.standing.x, liblaggo.standing.y, liblaggo.standing.z)
end

function liblaggo.getFacing()
    return liblaggo.facing
end

function liblaggo.refuel(direction, toLevel, fuelValue, pushBuckets)
    if turtle.getFuelLimit() == "unlimited" then
        return
    end

    local toLevel = toLevel or turtle.getFuelLimit()

    -- assume charcoal
    local fuelValue = fuelValue or 80

    while toLevel - turtle.getFuelLevel() >= fuelValue do
        local oldLevel = turtle.getFuelLevel()

        liblaggo.doWithContext("refuel", function()
            local ok, err
            ok, err = turtle.select(1);
            if not ok then
                return ok, err
            end

            ok, err = liblaggo.doAnyDir("suck", direction, 1);
            if not ok then
                return ok, err
            end

            ok, err = turtle.refuel(1);
            if not ok then
                return ok, err
            end

            local detail = turtle.getItemDetail()
            if detail and detail.name == "minecraft:bucket" then
                liblaggo.doWithContext("return refueling bucket",
                    function() return liblaggo.doAnyDir("drop", pushBuckets or direction) end)
            end

            return true, nil
        end)

        fuelValue = turtle.getFuelLevel() - oldLevel
    end

    return fuelValue
end

function liblaggo.dump(direction)
    for slot = 1, liblaggo.NUM_SLOTS do
        if turtle.getItemCount(slot) > 0 then
            turtle.select(slot)
            liblaggo.doWithContext("drop from slot " .. slot, function() return liblaggo.doAnyDir("drop", direction) end)
        end
    end
end

function liblaggo.isInventoryEmpty()
    for slot = 1, liblaggo.NUM_SLOTS do
        if turtle.getItemCount(slot) > 0 then
            return false
        end
    end
    return true
end

function liblaggo.selectOffset(off)
    local next = turtle.getSelectedSlot() + off
    while next > 16 do
        next = next - 16
    end

    while next < 1 do
        next = next + 16
    end

    turtle.select(next)
end

function liblaggo.facingToPeripheral(direction)
    if direction == "up" then
        return "top"
    elseif direction == "down" then
        return "bottom"
    elseif direction == liblaggo.facing then
        return "front"
    elseif direction == liblaggo.FACE_LEFT[liblaggo.facing] then
        return "left"
    elseif direction == liblaggo.FACE_RIGHT[liblaggo.facing] then
        return "right"
    else
        return "back"
    end
end

function liblaggo.parseBlockPos(obj)
    if not obj then
        return nil
    end

    if type(obj.x) ~= "number" or math.floor(obj.x) ~= obj.x then
        return nil
    end
    if type(obj.y) ~= "number" or math.floor(obj.y) ~= obj.y then
        return nil
    end
    if type(obj.z) ~= "number" or math.floor(obj.z) ~= obj.z then
        return nil
    end

    return vector.new(obj.x, obj.y, obj.z)
end

-- requests have {route, body}

function liblaggo.networkApp()
    local routes = {}

    local ret = {}

    -- ret.protocol = nil
    -- ret.hostname = nil

    ret.halt = false

    ret.on = function(route, cb)
        routes[route] = cb
    end

    ret.run = function(protocol, hostname)
        ret.protocol = protocol
        ret.hostname = hostname

        peripheral.find("modem", rednet.open)
        rednet.host(protocol, hostname)

        io.write("listening as " .. hostname .. " on protocol " .. protocol .. "\n")

        while not ret.halt do
            local event, sender, message, protocolGot = os.pullEvent("rednet_message")
            if protocol == protocolGot then
                local req = {
                    sender = sender,
                    body = message.body,
                    textual = function()
                        return textutils.unserialize(message.body)
                    end,
                    json = function()
                        return textutils.unserializeJSON(message.body)
                    end,
                    app = ret,
                }
                local res = {
                    send = function(payload)
                        rednet.send(sender, payload, protocolGot)
                    end,
                    textual = function(payload)
                        rednet.send(sender, textutils.serialize(payload), protocolGot)
                    end,
                    json = function(payload)
                        rednet.send(sender, textutils.serializeJSON(payload), protocolGot)
                    end
                }

                local cb = routes[message.route]
                if cb then
                    local ok, err = pcall(routes[message.route], req, res)
                    if not ok then
                        io.write("error in route " .. message.route .. ": " .. textutils.serialize(err) .. "\n")
                    end
                else
                    io.write("warning: no such route " .. message.route .. "\n")
                end
            end
        end
    end

    ret.stop = function()
        ret.halt = true
    end

    return ret
end

function liblaggo.headlessApp()
    local app = liblaggo.networkApp()

    app.on("ping", function(req, res)
        res.send("hi! i'm " .. os.getComputerLabel() .. " (ID " .. os.getComputerID() .. ")")
    end)

    app.on("reload", function(req, res)
        fs.delete("/computercraft")
        shell.run("/clone https://github.com/laggycomputer/computercraft")
        local program = os.getComputerLabel()

        local fp = fs.open("/startup", "w+")
        fp.write('shell.run("/computercraft/' .. program .. '")')

        res.send("ok, restarting")
        os.reboot()
    end)

    return app
end

function liblaggo.fetch(protocol, host, route, payload)
    if liblaggo.isTableEmpty(peripheral.find("modem", rednet.open)) then
        return false, "no modem"
    end

    local recipient = rednet.lookup(protocol, host)

    if not recipient then
        return false, "no host found"
    end

    payloadSer = textUtils.serialize(payload)

    if not payloadSer then
        return false, "could not serialize"
    end

    if not rednet.send(recipient, {
            route = route,
            body = payloadSer,
        }, protocol) then
        return false, "message not sent"
    end

    local sender, msg, protocol = rednet.receive(protocol, 5)
    if not sender then
        return false, "no ack"
    end

    return true, sender, msg
end

return liblaggo
