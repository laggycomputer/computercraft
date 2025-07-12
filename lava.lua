local startAt = vector.new(-168, 99, -21)
local startFacing = "east"

local refuelAt = startAt
local refuelFacing = "up"

local takeBucketsAt = startAt
local takeBucketsFacing = "north"

local moves = {
    "south",
    "east",
    "east",
    "east",
    "south",
    "south",
    "west",
    "west",
    "west",
    "north",
    "east",
    "east",
    "north",
    "west",
    "west",
    "north",
    "north",
}

----------------------

require "liblaggo"

initPathing(startAt, startFacing)

naiveMove(refuelAt)
refuel(refuelFacing)

naiveMove(takeBucketsAt)
for slot = 1, NUM_SLOTS do
    turtle.select(slot)
    local detail = turtle.getItemDetail()
    if detail then
        assert(detail.name == "minecraft:bucket", detail.name .. " is not a bucket, take this out of my inventory :(")
        doWithContext("remove excess bucket(s)", function() return doAnyDir("drop", takeBucketsFacing, detail.count - 1) end)
    else
        doAnyDir("suck", takeBucketsFacing, 1)
        assert(detail.name == "minecraft:bucket", "sucked " .. detail.name .. ", which is not a bucket")
        assert(detail.count == 1, "didn't pull 1, pulled " .. detail.count)
    end
end

turtle.select(1)

for _, direction in pairs(moves) do
    step(CARDINALS[direction])

    local ok, data = turtle.inspectUp()

    if ok then
        if data.name == "minecraft:lava_cauldron" then
            doWithContext("take lava at " .. getStanding():tostring(), function() return turtle.placeUp() end)
            selectOffset(1)
        end
    end
end

io.write("returning to home base at " .. startAt:tostring() .. "\n")

naiveMove(startAt)
face(startFacing)
