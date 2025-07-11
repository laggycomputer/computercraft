function doWithContext(context, fn)
    local ok, err = false, nil

    for _ = 1, 5 do
        ok, err = fn()
        if ok then
            return ok, err
        end
    end

    io.write("5 unsuccessful attempts to " .. context .. " (latest error: " .. err .. ")")
end

function initPathing(start_at, start_facing)
    standing = vector.new(start_at.x, start_at.y, start_at.z)
    facing = start_facing
end

cardinals = {
    east = vector.new(1, 0, 0),
    south = vector.new(0, 0, 1),
    west = vector.new(-1, 0, 0),
    north = vector.new(0, 0, -1),
    up = vector.new(0, 1, 0),
    down = vector.new(0, -1, 0),
}

facingNextRight = {
    east = "south",
    south = "west",
    west = "north",
    north = "east",
}

facingNextLeft = {
    east = "north",
    north = "west",
    west = "south",
    south = "east",
}

function face (facing_to)
    if facing == facing_to then
        return
    end

    if facingNextRight[facing] == facing_to then
        turtle.turnRight()
        facing = facingNextRight[facing]
    end

    while facing ~= facing_to do
        turtle.turnLeft()
        facing = facingNextLeft[facing]
    end
end

function step (vec_offset)
    local ok, err

    if vec_offset:equals(cardinals["up"]) then
        ok, err = turtle.up()
        if ok then
            standing = standing:add(vec_offset)
        end

        return ok, err
    end

    if vec_offset:equals(cardinals["down"]) then
        ok, err = turtle.down()
        if ok then
            standing = standing:add(vec_offset)
        end

        return ok, err
    end


    if cardinals[facing]:equals(vec_offset) then
        ok, err = turtle.forward()
        if ok then
            standing = standing:add(vec_offset)
        end

        return ok, err
    end

    if cardinals[facing]:unm():equals(vec_offset) then
        ok, err = turtle.back()
        if ok then
            standing = standing:add(vec_offset)
        end

        return ok, err
    end


    for f, v in pairs(cardinals) do
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

function naiveMove (vec_to)
    while standing.y < vec_to.y do
        doWithContext("naive move up", function() return turtle.up() end)
    end

    while standing.y > vec_to.y do
        doWithContext("naive move down", function() return turtle.down() end)
    end

    while standing.x < vec_to.x do
        doWithContext("naive step east", function() return step(cardinals["east"]) end)
    end

    while standing.x > vec_to.x do
        doWithContext("naive step west", function() return step(cardinals["west"]) end)
    end

    while standing.z < vec_to.z do
        doWithContext("naive step south", function() return step(cardinals["south"]) end)
    end

    while standing.z > vec_to.z do
        doWithContext("naive step north", function() return step(cardinals["north"]) end)
    end
end