local startAt = vector.new(-255, 76, 25)
local startFacing = "north"

local suckItemsAt = startAt
local suckItemsFacing = "east"

local numFurnaces = 9
local furnacesDirection = "west"

-- non-64 fuels are not supported, sorry ethan

----------------------

require "liblaggo"

initPathing(startAt, startFacing)

refuel()

naiveMove(suckItemsAt)

local itemsTaken = 0
for slot = 1, NUM_SLOTS do
    turtle.select(slot)
    doAnyDir("suck", suckItemsFacing)
    itemsTaken = itemsTaken + turtle.getItemCount(slot)
end

if itemsTaken == 0 then
    io.write("nothing to do\n")
    goto gohome
end

local numPerFurnace = math.floor(itemsTaken / numFurnaces)

for furnace = 1, numFurnaces do
    step(CARDINALS[furnacesDirection])
    local toDropNow = (furnace == numFurnaces) and numPerFurnace or (numPerFurnace + itemsTaken % numFurnaces)
    while toDropNow > 0 do
        local countBefore = turtle.getItemCount()
        turtle.dropDown(toDropNow)
        if turtle.getItemCount() == 0 then
            turtle.select((turtle.getSelectedSlot() + 1) % NUM_SLOTS)
        end

        toDropNow = toDropNow - (countBefore - turtle.getItemCount())
    end
end

::gohome::
io.write("returning to home base at " .. startAt:tostring() .. "\n")

naiveMove(startAt)
face(startFacing)
