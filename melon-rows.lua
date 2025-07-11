local corners = {
    vector.new(-188, 78, 34),
    vector.new(-224, 78, 10),
}

local start_at = vector.new(-224, 78, 8)
local start_facing = "east"

local dump_outputs_direction = "north"

-- coal/charcoal
local fuel_value = 80

----------------------

function do_with_context(context, fn)
    local ok, err = false, nil

    for _ = 1, 5 do
        ok, err = fn()
        if ok then
            return ok, err
        end
    end

    io.write("5 unsuccessful attempts to " .. context .. " (latest error: " .. err .. ")")
end

local standing = vector.new(start_at.x, start_at.y, start_at.z)
local facing = start_facing

local cardinals = {
    east = vector.new(1, 0, 0),
    south = vector.new(0, 0, 1),
    west = vector.new(-1, 0, 0),
    north = vector.new(0, 0, -1),
    up = vector.new(0, 1, 0),
    down = vector.new(0, -1, 0),
}

local facing_next_right = {
    east = "south",
    south = "west",
    west = "north",
    north = "east",
}

local facing_next_left = {
    east = "north",
    north = "west",
    west = "south",
    south = "east",
}

function face (facing_to)
    if facing == facing_to then
        return
    end

    if facing_next_right[facing] == facing_to then
        turtle.turnRight()
        facing = facing_next_right[facing]
    end

    while facing ~= facing_to do
        turtle.turnLeft()
        facing = facing_next_left[facing]
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
        do_with_context("naive move up", function() return turtle.up() end)
    end

    while standing.y > vec_to.y do
        do_with_context("naive move down", function() return turtle.down() end)
    end

    while standing.x < vec_to.x do
        do_with_context("naive step east", function() return step(cardinals["east"]) end)
    end

    while standing.x > vec_to.x do
        do_with_context("naive step west", function() return step(cardinals["west"]) end)
    end

    while standing.z < vec_to.z do
        do_with_context("naive step south", function() return step(cardinals["south"]) end)
    end

    while standing.z > vec_to.z do
        do_with_context("naive step north", function() return step(cardinals["north"]) end)
    end
end

local stems = {
    "minecraft:pumpkin_stem",
    "minecraft:attached_pumpkin_stem",
    "minecraft:melon_stem",
    "minecraft:attached_melon_stem"
}

function is_skip_row (data)
    for i = 1, #stems do
        if data.name == stems[i] then
        return true
    end

    end
    return data.name == "minecraft:torch"
end

local corners_aligned = {
    vector.new(math.min(corners[1].x, corners[2].x), math.min(corners[1].y, corners[2].y), math.min(corners[1].z, corners[2].z)),
    vector.new(math.max(corners[1].x, corners[2].x), math.max(corners[1].y, corners[2].y), math.max(corners[1].z, corners[2].z)),
}

while true do
    while turtle.getFuelLimit() - turtle.getFuelLevel() >= fuel_value do
        do_with_context("refuel", function ()
            local ok, err
            ok, err = turtle.select(1);
            if not ok then
                return ok, err
            end

            ok, err = turtle.suckUp(1);
            if not ok then
                return ok, err
            end

            ok, err = turtle.refuel(1);
            if not ok then
                return ok, err
            end

            return true, nil
        end)
    end

    io.write("moving to start pos " .. corners_aligned[1]:tostring() .. "\n")
    naiveMove(corners_aligned[1])

    -- Y, Z, X major order
    for y = corners_aligned[1].y, corners_aligned[2].y do
        local zDir = standing.z == corners_aligned[1].z and 1 or -1
        local zStart = zDir == 1 and corners_aligned[1].z or corners_aligned[2].z
        local zEnd   = zDir == 1 and corners_aligned[2].z or corners_aligned[1].z

        for z = zStart, zEnd, zDir do
            local xDir = standing.x == corners_aligned[1].x and 1 or -1
            local xStart = xDir == 1 and corners_aligned[1].x or corners_aligned[2].x
            local xEnd   = xDir == 1 and corners_aligned[2].x or corners_aligned[1].x

            naiveMove(vector.new(standing.x, standing.y, z))

            local ok, data = turtle.inspectDown()
            if ok and is_skip_row(data) then
                goto next_z
            end

            if ok then
                if data.name == "minecraft:pumpkin" or data.name == "minecraft:melon" then
                    turtle.digDown()
                end
            end

            for x = xStart + xDir, xEnd, xDir do
                local goal = vector.new(x, y, z)
                naiveMove(goal)

                ok, data = turtle.inspectDown()

                if ok then
                    if data.name == "minecraft:pumpkin" or data.name == "minecraft:melon" then
                        turtle.digDown()
                    end
                end
            end

            ::next_z::
        end
    end

    io.write("returning to home base at " .. start_at:tostring() .. "\n")
    naiveMove(start_at)
    face(dump_outputs_direction)
    for slot = 1, 16 do
        if turtle.getItemCount(slot) > 0 then
            turtle.select(slot)
            do_with_context("drop from slot " .. slot, turtle.drop)
        end
    end

    face(start_facing)

    assert(false)

    io.write("sleeping\n")
    sleep(240)
end
