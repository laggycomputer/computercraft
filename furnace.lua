local startAt = vector.new(-255, 76, 25)
local startFacing = "north"

local suckItemsAt = startAt
local suckItemsFacing = "east"

local numFurnaces = 9
local furnacesDirection = "west"

-- non-64 fuels are not supported, sorry ethan

----------------------

require "liblaggo"

liblaggo.initPathing(startAt, startFacing)

liblaggo.refuel(suckItemsFacing)

liblaggo.naiveMove(suckItemsAt)
do
    local totalToSmelt = 0
    for slot = 1, liblaggo.NUM_SLOTS do
        turtle.select(slot)
        liblaggo.doAnyDir("suck", suckItemsFacing)
        totalToSmelt = totalToSmelt + turtle.getItemCount(slot)
    end

    if totalToSmelt == 0 then
        io.write("nothing to do\n")
        assert(false)
    end

    -- todo: don't waste fuel
    local numPerFurnace = math.floor(totalToSmelt / numFurnaces)

    for furnace = 1, numFurnaces do
        local toDropNow = math.min((furnace == numFurnaces) and numPerFurnace or (numPerFurnace + totalToSmelt % numFurnaces), 64)
        while toDropNow > 0 and totalToSmelt > 0 do
            local countBefore = turtle.getItemCount()
            liblaggo.doWithContext("push items into furnace", function() return turtle.dropDown(math.min(toDropNow, countBefore)) end)
            local dropped = countBefore - turtle.getItemCount()
            if turtle.getItemCount() == 0 then
                liblaggo.selectOffset(1)
            end

            toDropNow = toDropNow - dropped
            totalToSmelt = totalToSmelt - dropped
        end
        liblaggo.step(liblaggo.CARDINALS[furnacesDirection])
    end
end

if not liblaggo.isInventoryEmpty() then
    liblaggo.naiveMove(suckItemsAt)
    liblaggo.dump(suckItemsFacing)
end

io.write("returning to home base at " .. startAt:tostring() .. "\n")

liblaggo.naiveMove(startAt)
liblaggo.face(startFacing)
