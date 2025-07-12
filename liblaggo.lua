function doWithContext(context, fn)
    local ok, err = false, nil

    for _ = 1, 1 do
        ok, err = fn()
        if ok then
            return ok, err
        end
    end

    io.write("failed to " .. context .. " (latest error: " .. err .. ")")
end

function initPathing(start_at, start_facing)
    standing = vector.new(start_at.x, start_at.y, start_at.z)
    facing = start_facing
end

CARDINALS = {
    east = vector.new(1, 0, 0),
    south = vector.new(0, 0, 1),
    west = vector.new(-1, 0, 0),
    north = vector.new(0, 0, -1),
    up = vector.new(0, 1, 0),
    down = vector.new(0, -1, 0),
}

FACE_RIGHT = {
    east = "south",
    south = "west",
    west = "north",
    north = "east",
}

FACE_LEFT = {
    east = "north",
    north = "west",
    west = "south",
    south = "east",
}

NUM_SLOTS = 16

function face(facingTo)
    if facing == "up" or facing == "down" then
        return
    end

    if facing == facingTo then
        return
    end

    if FACE_RIGHT[facing] == facingTo then
        turtle.turnRight()
        facing = FACE_RIGHT[facing]
    end

    while facing ~= facingTo do
        turtle.turnLeft()
        facing = FACE_LEFT[facing]
    end
end

function doAnyDir(fnName, direction, ...)
    local fn = turtle[fnName]
    if direction == "down" then
        fn = turtle[fnName .. "Down"]
    elseif direction == "up" then
        fn = turtle[fnName .. "Up"]
    else
        face(direction)
    end

    return fn(...)
end

function step(vec_offset)
    local ok, err

    if vec_offset:equals(CARDINALS["up"]) then
        ok, err = turtle.up()
        if ok then
            standing = standing:add(vec_offset)
        end

        return ok, err
    end

    if vec_offset:equals(CARDINALS["down"]) then
        ok, err = turtle.down()
        if ok then
            standing = standing:add(vec_offset)
        end

        return ok, err
    end


    if CARDINALS[facing]:equals(vec_offset) then
        ok, err = turtle.forward()
        if ok then
            standing = standing:add(vec_offset)
        end

        return ok, err
    end

    if CARDINALS[facing]:unm():equals(vec_offset) then
        ok, err = turtle.back()
        if ok then
            standing = standing:add(vec_offset)
        end

        return ok, err
    end


    for f, v in pairs(CARDINALS) do
        if v:equals(vec_offset) then
            face(f)
        end
    end

    ok, err = turtle.forward()
    if ok then
        standing = standing:add(vec_offset)
    end

    return ok, err
end

function naiveMove(vec_to)
    while standing.y < vec_to.y do
        doWithContext("naive move up", function() return turtle.up() end)
    end

    while standing.y > vec_to.y do
        doWithContext("naive move down", function() return turtle.down() end)
    end

    while standing.x < vec_to.x do
        doWithContext("naive step east", function() return step(CARDINALS["east"]) end)
    end

    while standing.x > vec_to.x do
        doWithContext("naive step west", function() return step(CARDINALS["west"]) end)
    end

    while standing.z < vec_to.z do
        doWithContext("naive step south", function() return step(CARDINALS["south"]) end)
    end

    while standing.z > vec_to.z do
        doWithContext("naive step north", function() return step(CARDINALS["north"]) end)
    end
end

function getStanding()
    return vector.new(standing.x, standing.y, standing.z)
end

function getFacing()
    return facing
end

function refuel(direction, toLevel, fuelValue)
    local toLevel = toLevel or turtle.getFuelLimit()

    -- assume charcoal
    local fuelValue = fuelValue or 80

    while toLevel - turtle.getFuelLevel() >= fuelValue do
        local oldLevel = turtle.getFuelLevel()

        doWithContext("refuel", function()
            local ok, err
            ok, err = turtle.select(1);
            if not ok then
                return ok, err
            end

            ok, err = doAnyDir("suck", direction, 1);
            if not ok then
                return ok, err
            end

            ok, err = turtle.refuel(1);
            if not ok then
                return ok, err
            end

            return true, nil
        end)

        fuelValue = turtle.getFuelLevel() - oldLevel
    end

    return fuelValue
end

function dump(direction)
    for slot = 1, NUM_SLOTS do
        if turtle.getItemCount(slot) > 0 then
            turtle.select(slot)
            doWithContext("drop from slot " .. slot, turtle.drop)
        end
    end
end

function isInventoryEmpty()
    for slot = 1, NUM_SLOTS do
        if turtle.getItemCount(slot) > 0 then
            return false
        end
    end
    return true
end

function selectOffset(off)
    local next = turtle.getSelectedSlot() + off
    while next > 16 do
        next = next - 16
    end

    while next < 1 do
        next = next + 16
    end

    turtle.select(next)
end