require "liblaggo"

local corners = {
    vector.new(-188, 78, 34),
    vector.new(-224, 78, 10),
}

local startAt = vector.new(-224, 78, 8)
local startFacing = "east"

local dumpOutputsDirection = "north"

-- coal/charcoal
local fuel_value = 80

----------------------

initPathing(startAt, startFacing)

local stems = {
    "minecraft:pumpkin_stem",
    "minecraft:attached_pumpkin_stem",
    "minecraft:melon_stem",
    "minecraft:attached_melon_stem"
}

function isSkipRow (data)
    for i = 1, #stems do
        if data.name == stems[i] then
        return true
    end

    end
    return data.name == "minecraft:torch"
end

local cornersAligned = {
    vector.new(math.min(corners[1].x, corners[2].x), math.min(corners[1].y, corners[2].y), math.min(corners[1].z, corners[2].z)),
    vector.new(math.max(corners[1].x, corners[2].x), math.max(corners[1].y, corners[2].y), math.max(corners[1].z, corners[2].z)),
}

while true do
    while turtle.getFuelLimit() - turtle.getFuelLevel() >= fuel_value do
        doWithContext("refuel", function ()
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

    io.write("moving to start pos " .. cornersAligned[1]:tostring() .. "\n")
    naiveMove(cornersAligned[1])

    -- Y, Z, X major order
    for y = cornersAligned[1].y, cornersAligned[2].y do
        local zDir = standing.z == cornersAligned[1].z and 1 or -1
        local zStart = zDir == 1 and cornersAligned[1].z or cornersAligned[2].z
        local zEnd   = zDir == 1 and cornersAligned[2].z or cornersAligned[1].z

        for z = zStart, zEnd, zDir do
            local xDir = standing.x == cornersAligned[1].x and 1 or -1
            local xStart = xDir == 1 and cornersAligned[1].x or cornersAligned[2].x
            local xEnd   = xDir == 1 and cornersAligned[2].x or cornersAligned[1].x

            naiveMove(vector.new(standing.x, standing.y, z))

            local ok, data = turtle.inspectDown()
            if ok and isSkipRow(data) then
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

    io.write("returning to home base at " .. startAt:tostring() .. "\n")
    naiveMove(startAt)
    face(dumpOutputsDirection)
    for slot = 1, 16 do
        if turtle.getItemCount(slot) > 0 then
            turtle.select(slot)
            doWithContext("drop from slot " .. slot, turtle.drop)
        end
    end

    face(startFacing)

    assert(false)

    io.write("sleeping\n")
    sleep(240)
end
