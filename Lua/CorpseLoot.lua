local mq = require('mq')

-- Function to get the spawn count
local function getSpawnCount(searchString)
    local count = mq.TLO.SpawnCount(searchString)()
    return tonumber(count) or 0
end

-- Function to close the loot window if it's open
local function closeWindow(windowName)
    local window = mq.TLO.Window(windowName)
    if window.Open() then
        window.DoClose()
        print(windowName .. " window closed.")
    else
        print(windowName .. " window is not open.")
    end
end

-- Function to target player's own corpse more reliably
local function targetOwnCorpse(playerName)
    local corpse = mq.TLO.Spawn(string.format('corpse %s', playerName))
    if not corpse() or not corpse.ID() then
        print("No corpse found.")
        return false
    end

    local currentTargetID = mq.TLO.Target.ID()
    if currentTargetID ~= corpse.ID() then
        -- Attempt to target the corpse by ID
        mq.cmdf('/target id %d', corpse.ID())
        
        -- Check if the target was successfully acquired
        mq.delay(100) -- Small delay to give the game time to target the corpse
        return mq.TLO.Target.ID() == corpse.ID()
    end
    return true -- Already correctly targeted
end

-- Function to loot the corpse
local function lootCorpse(playerName)
    local searchString30 = string.format('corpse %s radius 30', playerName)
    local closeCorpseCount = getSpawnCount(searchString30)
    
    if closeCorpseCount > 0 then
        mq.cmd("/loot")
        
        -- Wait for looting to complete
        mq.delay(1000)
        
        -- Close the loot window directly without /keypress esc
        closeWindow("LootWnd")

        -- Delay for 1 second after closing the loot window
        mq.delay(1000)
    end
end

-- Main loop
while true do
    -- Check if there are corpses within 150 radius
    local playerName = tostring(mq.TLO.Me.Name())
    local searchString150 = string.format('corpse %s radius 150', playerName)
    local spawnCount150 = getSpawnCount(searchString150)

    if spawnCount150 > 0 then
        if targetOwnCorpse(playerName) then
            -- Drag the corpse
            mq.cmd("/corpse")
            
            -- Wait until a corpse is within 30 radius after dragging
            mq.delay(1000)  -- Small delay before rechecking for the corpse

            -- Loot the corpse if close enough
            lootCorpse(playerName)
        else
            print("Failed to target the corpse.")
        end
    end

    -- Delay before the next iteration of the loop
    mq.delay(1000)
end
