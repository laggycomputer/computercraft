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

function liblaggo.initPathing(startLocation, startFacing)
    liblaggo.standing = startLocation and vector.new(startLocation.x, startLocation.y, startLocation.z) or
    assert(gps.locate(), "cannot determine location and none passed!")
    liblaggo.facing = startFacing
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

liblaggo.NUM_SLOTS = 16

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
        x = false,
        y = false,
        z = false,
    }

    local lastFail

    local displacement = vecTo:sub(liblaggo.standing)

    while displacement:length() ~= 0 do
        if not canMove.x and not canMove.y and not canMove.z then
            return false, lastFail
        end

        while not canMove.x do
            canMove.x, lastFail = liblaggo.step(vector.new(liblaggo.sgn(displacement.x), 0, 0))
        end

        while not canMove.y do
            canMove.y, lastFail = liblaggo.step(vector.new(0, liblaggo.sgn(displacement.y), 0))
        end

        while not canMove.z do
            canMove.z, lastFail = liblaggo.step(vector.new(0, 0, liblaggo.sgn(displacement.z)))
        end

        displacement = vecTo:sub(liblaggo.standing):length()
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

-- requests have {route, params}

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
                    params = message.params,
                    app = ret,
                }
                local res = {
                    send = function(payload)
                        rednet.send(sender, payload, protocolGot)
                    end
                }

                routes[message.route](req, res)
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

return liblaggo
