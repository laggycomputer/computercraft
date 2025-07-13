local startAt = vector.new(-168, 99, -20)
local startFacing = "east"

local takeBucketsAt = startAt
local takeBucketsFacing = "north"

local pushBucketsAt = startAt
local pushBucketsFacing = "west"

local moves = {
    "east",
    "east",
    "east",
    "south",
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
}

----------------------

local liblaggo = require("liblaggo")

-- assume we take lava from here too to refuel
liblaggo.initPathing(startAt, startFacing)

local app = liblaggo.headlessApp()

app.on("trigger", function(req, res)
    res.send("ok")

    -- steal lava from output, push buckets back to input
    liblaggo.refuel(pushBucketsFacing, nil, 100 * 10, takeBucketsFacing)

    liblaggo.naiveMove(takeBucketsAt)

    turtle.select(1)
    while true do
        local detail = turtle.getItemDetail()
        if detail then
            assert(detail.name == "minecraft:bucket", detail.name .. " is not a bucket, take this out of my inventory :(")
            liblaggo.doWithContext("remove excess bucket(s)",
                function() return liblaggo.doAnyDir("drop", takeBucketsFacing, detail.count - 1) end)

            -- can proceed without taking another bucket
            liblaggo.selectOffset(1)
            if turtle.getSelectedSlot() == 1 then
                break
            end
        else
            liblaggo.doAnyDir("suck", takeBucketsFacing, 1)
            local detail = turtle.getItemDetail()
            if detail then
                assert(detail.name == "minecraft:bucket", "sucked " .. detail.name .. ", which is not a bucket")
                assert(detail.count == 1, "didn't pull 1, pulled " .. detail.count)

                -- pulled a bucket, move on
                liblaggo.selectOffset(1)
                if turtle.getSelectedSlot() == 1 then
                    break
                end
            else
                -- no more buckets to pull
                break
            end
        end
    end

    turtle.select(1)
    for _, direction in pairs(moves) do
        local detail = turtle.getItemDetail()
        if not detail then
            -- no bucket
            goto nextStep
        end

        do
            local ok, data = turtle.inspectUp()

            if ok then
                if data.name == "minecraft:lava_cauldron" then
                    liblaggo.doWithContext("take lava at " .. liblaggo.getStanding():tostring(), function() return turtle.placeUp() end)
                    liblaggo.selectOffset(1)
                end
            end
        end

        liblaggo.step(liblaggo.CARDINALS[direction])
        ::nextStep::
    end

    -- push full buckets out
    liblaggo.naiveMove(pushBucketsAt)
    for slot = 1, liblaggo.NUM_SLOTS do
        local detail = turtle.getItemDetail(slot)
        if detail then
            if detail.name == "minecraft:lava_bucket" then
                turtle.select(slot)
                liblaggo.doWithContext("push out full buckets", function() return liblaggo.doAnyDir("drop", pushBucketsFacing) end)
            end
            -- empty buckets can stay
        end
    end

    io.write("returning to home base at " .. startAt:tostring() .. "\n")

    liblaggo.naiveMove(startAt)
    liblaggo.face(startFacing)
end)

app.run("lava", "lava")