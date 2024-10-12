local mq = require('mq')
local imgui = require('ImGui')

-- Input variables
local itemQuantityInput = "0"
local coinTypeInput = "platinum"
local nameInput = ''
local itemNameInput = ''
local autoCompletePendingName = false
local autoCompletePendingItem = false
local autoCompleteTimerName = 0
local autoCompleteTimerItem = 0
local coinAmountInput = '0'

-- Define coin types for selection
local coinTypes = {"platinum", "gold", "silver", "copper"}
local selectedCoinType = 0 -- Default is 'platinum'
local WaitTime = 1000
local memberNames = {}
local showtradeitGUI = true  -- Flag to control the GUI visibility

-- Check if inventory is open
local function InventoryOpen()
    return mq.TLO.Window('InventoryWindow').Open() or false
end

-- Check if a target is selected
local function HaveTarget()
    return mq.TLO.Target.ID() ~= nil
end

-- Print method for standardized output
local function PRINTMETHOD(printMessage, ...)
    printf("[tradeit] " .. printMessage, ...)
end

-- Handle item clicks while GUI is hovered
local function handleGlobalItemClick()
    if mq.TLO.Cursor() ~= nil and ImGui.IsWindowHovered() and ImGui.IsMouseClicked(ImGuiMouseButton.Left) then
        local cursorItem = mq.TLO.Cursor.Name()  -- Get the item on the cursor
        if cursorItem then
            itemNameInput = cursorItem  -- Autofill item name in the field
            mq.cmd("/autoinv")  -- Return the item to inventory
            PRINTMETHOD("Item autofilled: " .. cursorItem)
        end
    end
end

-- Helper function to ensure input types are correct
local function CheckInputType(label, value, expectedType)
    if type(value) ~= expectedType then
        print(string.format("Warning: %s is not a %s! Value: %s", label, expectedType, tostring(value)))
        return tostring(value)  -- Convert to string if necessary
    end
    return value
end

-- Capitalization function for proper coin type formatting
local function capitalize(str)
    return str == "platinum" and "Platinum" or str:sub(1, 1):upper() .. str:sub(2):lower()
end

-- Populate raid or group member names
local function populateMemberNames()
    memberNames = {}  -- Clear previous entries

    if mq.TLO.Raid.Members() > 0 then
        for i = 1, mq.TLO.Raid.Members() do
            local raidMemberName = mq.TLO.Raid.Member(i).Name()
            if raidMemberName then
                table.insert(memberNames, raidMemberName)
            end
        end
    elseif mq.TLO.Me.Grouped() then
        for i = 1, mq.TLO.Group.Members() do
            local groupMemberName = mq.TLO.Group.Member(i).Name()
            if groupMemberName then
                table.insert(memberNames, groupMemberName)
            end
        end
    end
end

-- Check if a name belongs to a raid/group member
local function isRaidOrGroupMember(name)
    for _, member in ipairs(memberNames) do
        if member == name then
            return true
        end
    end
    return false
end

-- Auto-complete closest match for names (players, NPCs, etc.)
local function findClosestMatch(input)
    input = input:lower()
    local closestMatch = nil
    local potentialMatches = {}

    -- Match raid/group members
    for _, name in ipairs(memberNames) do
        if name:lower():find(input, 1, true) then
            table.insert(potentialMatches, name)
        end
    end

    -- Match NPCs within 200 units
    local npcCount = mq.TLO.SpawnCount("npc")() or 0
    for i = 1, npcCount do
        local npc = mq.TLO.NearestSpawn(i, "npc")
        if npc() and npc.Distance3D() <= 200 then
            local cleanName = npc.CleanName():lower()
            if cleanName:find(input, 1, true) then
                table.insert(potentialMatches, npc.CleanName())
            end
        end
    end

    -- Match nearby PCs (not in raid/group) within 200 units
    local playerCount = mq.TLO.SpawnCount("pc")() or 0
    for i = 1, playerCount do
        local pc = mq.TLO.NearestSpawn(i, "pc")
        if pc() and pc.Distance3D() <= 200 and not isRaidOrGroupMember(pc.Name()) then
            local cleanName = pc.CleanName():lower()
            if cleanName:find(input, 1, true) then
                table.insert(potentialMatches, pc.CleanName())
            end
        end
    end

    -- Return the closest match if found
    return #potentialMatches > 0 and potentialMatches[1] or nil
end

-- Validate the target name (NPC or PC)
local function ValidateTargetName(targetName)
    if not targetName or targetName == "" then
        PRINTMETHOD("No target name provided.")
        return false
    end

    local nearbySpawn = mq.TLO.Spawn(targetName)
    if nearbySpawn() then
        PRINTMETHOD("Found target: %s", nearbySpawn.Name())
        return true
    else
        PRINTMETHOD("Target '%s' not found nearby.", targetName)
        return false
    end
end

-- Render item icon button in the GUI
local function renderItemIconButton()
    local itemName = itemNameInput
    local itemIconID = mq.TLO.FindItem(itemName) and mq.TLO.FindItem(itemName).Icon() or nil

    -- Set icon button properties
    ImGui.SameLine()
    ImGui.BeginGroup()

    local x, y = ImGui.GetCursorPos()

    -- Button color styling
    ImGui.PushStyleColor(ImGuiCol.Button, ImVec4(0.2, 0.4, 0.6, 0.8))  -- Blueish
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered, ImVec4(0.3, 0.5, 0.7, 1.0))
    ImGui.PushStyleColor(ImGuiCol.ButtonActive, ImVec4(0.1, 0.3, 0.5, 0.9))

    ImGui.Button("##itemIconButton", ImVec2(32, 32))  -- Icon button

    ImGui.PopStyleColor(3)
    ImGui.SetCursorPosX(x)
    ImGui.SetCursorPosY(y)

    -- Display item icon if available
    if itemName and itemIconID then
        local animItems = mq.FindTextureAnimation('A_DragItem')
        animItems:SetTextureCell(itemIconID - 500)
        ImGui.DrawTextureAnimation(animItems, 32, 32)
    end

    ImGui.EndGroup()
end

-- Find closest item match in inventory (including bags)
local function findClosestItemMatch(input, debug)
    input = input:lower()
    local closestMatch = nil
    local potentialMatches = {}

    -- Search main inventory slots (0-32)
    for i = 0, 32 do
        local item = mq.TLO.Me.Inventory(i)
        if item() then
            local itemName = item.Name():lower()

            if itemName:find(input, 1, true) then
                table.insert(potentialMatches, item.Name())

                -- Check stackable items
                if item.Stackable() then
                    local stack = item.Stack() or 0
                    local stackSize = item.StackSize() or 0
                    if debug then
                        PRINTMETHOD(string.format("Found stackable item '%s' in Slot %d with %d items (Max StackSize: %d).", itemName, i, stack, stackSize))
                    end
                end
            end

            -- Search inside containers
            local slots = item.Container()
            if slots and slots > 0 then
                for j = 1, slots do
                    local containerItem = item.Item(j)
                    if containerItem() then
                        local containerItemName = containerItem.Name():lower()
                        if containerItemName:find(input, 1, true) then
                            table.insert(potentialMatches, containerItem.Name())

                            if containerItem.Stackable() then
                                local stack = containerItem.Stack() or 0
                                local stackSize = containerItem.StackSize() or 0
                                if debug then
                                    PRINTMETHOD(string.format("Found stackable item '%s' in Container Slot %d with %d items (Max StackSize: %d).", containerItemName, j, stack, stackSize))
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Return the closest match if found
    return #potentialMatches > 0 and potentialMatches[1] or nil
end

-- Find total quantity of an item (inventory and bags)
local function getItemQuantity(itemName)
    local totalQuantity = 0

    -- Check main inventory slots (0-32)
    for i = 0, 32 do
        local item = mq.TLO.Me.Inventory(i)
        if item() and item.Name():lower() == itemName:lower() then
            totalQuantity = totalQuantity + (item.Stackable() and item.Stack() or 1)
        end
    end

    -- Check bag slots (1-10, assuming max 10 bags)
    for i = 1, 10 do
        local bagItem = mq.TLO.InvSlot('pack' .. i).Item
        if bagItem() then
            local slots = bagItem.Container()
            if slots and slots > 0 then
                for j = 1, slots do
                    local containerItem = bagItem.Item(j)
                    if containerItem() and containerItem.Name():lower() == itemName:lower() then
                        totalQuantity = totalQuantity + (containerItem.Stackable() and containerItem.Stack() or 1)
                    end
                end
            end
        end
    end

    return totalQuantity
end

-- Function to validate the item quantity 
local function ValidateItemQuantity(quantity, itemName)
    local availableItemQuantity = getItemQuantity(itemName)  -- Use getItemQuantity for consistency

    if not quantity or quantity == "" then
        PRINTMETHOD("Item quantity is missing.")
        return false
    end
    if tonumber(quantity) == nil or tonumber(quantity) <= 0 then
        PRINTMETHOD("Item quantity '" .. quantity .. "' is invalid. It must be a positive number.")
        return false
    end
    if tonumber(quantity) > availableItemQuantity then
        PRINTMETHOD("Item quantity '" .. quantity .. "' exceeds available quantity (" .. availableItemQuantity .. ").")
        return false
    end
    return true
end

-- Function to validate the item name
local function ValidateItemName(itemName)
    if not itemName or itemName == "" then
        PRINTMETHOD("Item name is missing.")
        return false
    end

    -- Use mq.TLO.FindItem to check if the item exists in the inventory
    if not mq.TLO.FindItem(itemName)() then
        PRINTMETHOD("Item name '" .. itemName .. "' is invalid or not found in your inventory.")
        return false
    end

    return true
end

local function tradeit(itemName, qty)
    -- Validate the item using the new logic
    if not ValidateItemName(itemName) then
        PRINTMETHOD("Item '" .. itemName .. "' is invalid or not found in inventory!")
        return
    end

    -- Get the available quantity using getItemQuantity
    local availableItemQuantity = getItemQuantity(itemName)

    -- Ensure qty is valid and convert it to a number
    if qty == nil or qty == "" then
        PRINTMETHOD("Item quantity is missing.")
        return
    end
    qty = tonumber(qty)  -- Convert qty to a number

    -- Check if qty is a valid number
    if qty == nil or qty <= 0 then
        PRINTMETHOD("Invalid item quantity '" .. tostring(qty) .. "'. It must be a positive number.")
        return
    end

    -- If quantity exceeds available item quantity
    if qty > availableItemQuantity then
        PRINTMETHOD("Requested quantity '" .. qty .. "' exceeds available quantity (" .. availableItemQuantity .. ").")
        return
    end

    -- Proceed with item finding and pickup logic
    if mq.TLO.FindItem(itemName).ID() ~= nil then
        local itemSlot = mq.TLO.FindItem('=' .. itemName).ItemSlot()
        local itemSlot2 = mq.TLO.FindItem('=' .. itemName).ItemSlot2()

        -- Determine if the item is in the main inventory or a bag
        if itemSlot >= 0 and itemSlot <= 22 then
            -- For main inventory slots (0-22)
            mq.cmd('/itemnotify ' .. itemSlot .. ' leftmouseup')
        else
            -- For bag slots (1-10)
            local pickup1 = itemSlot - 22  -- Adjust for bag slot calculation
            mq.cmd('/itemnotify in pack' .. pickup1 .. ' ' .. (itemSlot2 + 1) .. ' leftmouseup')
        end

        -- If it's stackable, adjust quantity in the trade window
        if qty ~= 'all' and mq.TLO.FindItem('=' .. itemName).Stackable() then
            mq.delay(5000, function() return mq.TLO.Window("QuantityWnd").Open() end)
            while mq.TLO.Window("QuantityWnd").Child("QTYW_SliderInput").Text() ~= tostring(qty) do
                mq.TLO.Window("QuantityWnd").Child("QTYW_SliderInput").SetText(tostring(qty))
                mq.delay(500)
            end
        end

        while mq.TLO.Window("QuantityWnd").Open() do
            mq.TLO.Window("QuantityWnd").Child("QTYW_Accept_Button").LeftMouseUp()
            mq.delay(10)
        end

        -- Perform the trade
        mq.delay(5000, function() return mq.TLO.Cursor() ~= nil end)
        mq.cmd('/click left target')
        mq.delay(5000, function() return mq.TLO.Cursor() == nil end)
    else
        PRINTMETHOD(string.format("Item '%s' not found in inventory!", itemName))  -- Output message when the item is not found
    end
end

-- Function to validate the coin amount
local function ValidateCoinAmount(coinAmount)
    if not coinAmount or coinAmount == "" then
        PRINTMETHOD("Coin amount is missing.")
        return false
    end
    if tonumber(coinAmount) == nil or tonumber(coinAmount) <= 0 then
        PRINTMETHOD("Coin amount '" .. coinAmount .. "' is invalid. It must be a positive number.")
        return false
    end
    return true
end

local function tradeitCoin(itemName, amt)
    local coinWindowIndex = {
        platinum = 0,
        gold = 1,
        silver = 2,
        copper = 3
    }

    -- If the amount is "all", set amt to nil so it bypasses amount checks
    local isAll = (amt == 'all')

    -- Helper function to handle coin transfer
    local function handleCoinTransfer(coinType, availableCoinAmount)
        local coinIndex = coinWindowIndex[coinType]
        if availableCoinAmount >= 1 then
            if isAll or tonumber(amt) <= availableCoinAmount then
                -- Click the appropriate coin slot to transfer to the cursor
                mq.TLO.Window("InventoryWindow").Child("IW_Money" .. coinIndex).LeftMouseUp()

                -- Wait for the Quantity Window to open if not transferring all
                if not isAll then
                    mq.delay(5000, function() return mq.TLO.Window("QuantityWnd").Open() end)

                    -- Adjust quantity in the Quantity Window
                    while mq.TLO.Window("QuantityWnd").Child("QTYW_SliderInput").Text() ~= amt do
                        mq.TLO.Window("QuantityWnd").Child("QTYW_SliderInput").SetText(amt)
                        mq.delay(10)  -- Small delay between checks
                    end
                end

                -- Click accept to confirm the transaction
                while mq.TLO.Window("QuantityWnd").Open() do
                    mq.TLO.Window("QuantityWnd").Child("QTYW_Accept_Button").LeftMouseUp()
                    mq.delay(10)
                end

                -- Finalize the coin transfer by clicking on the target
                mq.delay(500)
                mq.cmd('/click left target')
                mq.delay(500)
            else
                PRINTMETHOD("Not enough %s! Available: %d, Requested: %s", coinType, availableCoinAmount, amt)
            end
        else
            PRINTMETHOD("No %s available in inventory!", coinType)
        end
    end

    -- Check and transfer coins based on coin type
    if itemName == 'platinum' then
        local availablePlatinum = mq.TLO.Me.Platinum()
        handleCoinTransfer('platinum', availablePlatinum)

    elseif itemName == 'gold' then
        local availableGold = mq.TLO.Me.Gold()
        handleCoinTransfer('gold', availableGold)

    elseif itemName == 'silver' then
        local availableSilver = mq.TLO.Me.Silver()
        handleCoinTransfer('silver', availableSilver)

    elseif itemName == 'copper' then
        local availableCopper = mq.TLO.Me.Copper()
        handleCoinTransfer('copper', availableCopper)

    else
        PRINTMETHOD("Invalid coin type: %s", itemName)
    end
end

local function OpenInventory()
    PRINTMETHOD('Opening Inventory')
    mq.TLO.Window('InventoryWindow').DoOpen()
    mq.delay(1500, InventoryOpen)
end

local function ClickTrade()
    mq.delay(WaitTime)
    mq.TLO.Window("TradeWnd").Child("TRDW_Trade_Button").LeftMouseUp()
    mq.delay(WaitTime)
end

local function NavToTradeTargetByID(targetID)
    -- Target the specified spawn by ID
    PRINTMETHOD('Targeting ID %s.', targetID)
    mq.cmd('/target id ' .. targetID)
    mq.delay(2000, HaveTarget)  -- Wait until the target is acquired
    mq.cmd('/face')  -- Face the target

    -- Check the distance to the target and navigate if necessary
    if mq.TLO.Spawn("id " .. targetID).Distance3D() > 20 then
        PRINTMETHOD('Moving to ID %s.', targetID)
        mq.cmd('/nav id ' .. targetID)  -- Start navigation to the target by ID
        -- Wait until either the navigation is complete or the target is within 20 units
        while mq.TLO.Navigation.Active() and mq.TLO.Spawn("id " .. targetID).Distance3D() > 20 do
            mq.delay(50)  -- Delay in between checks
        end
        mq.cmd('/nav stop')  -- Stop navigation once the target is reached
    end
end

local function bind_tradeit(...)
    local args = { ..., }
    local cmd, name, itemName, amt = args[1], args[2], args[3], args[4]

    -- usage
    if not cmd or not name then return end

    -- Get the target's ID by name
    local targetID = mq.TLO.Spawn('"' .. name .. '"').ID()

    if cmd == 'item' and targetID and itemName then
        local quantity = amt or 'all'
        OpenInventory()
        NavToTradeTargetByID(targetID)
        tradeit(itemName, quantity)
        ClickTrade()
    elseif cmd == 'coin' and targetID and itemName and amt then
        OpenInventory()
        NavToTradeTargetByID(targetID)
        tradeitCoin(itemName, amt)
        ClickTrade()
    elseif cmd == 'group' and itemName and amt then
        OpenInventory()
        local groupMemberCount = mq.TLO.Group.Members()
        for i = 1, groupMemberCount do
            local memberID = mq.TLO.Group.Member(i).ID()
            if memberID and mq.TLO.Me.CleanName() ~= mq.TLO.Group.Member(i).CleanName() then
                NavToTradeTargetByID(memberID)
                tradeitCoin(itemName, amt)
                ClickTrade()
            end
        end
    elseif cmd == 'raid' and itemName and amt then
        OpenInventory()
        local raidMemberCount = mq.TLO.Raid.Members()
        for i = 1, raidMemberCount do
            local memberID = mq.TLO.Raid.Member(i).ID()
            if memberID and mq.TLO.Me.CleanName() ~= mq.TLO.Raid.Member(i).CleanName() then
                NavToTradeTargetByID(memberID)
                tradeitCoin(itemName, amt)
                ClickTrade()
            end
        end
    end
end

local function isTargetInRange(maxDistance)
    -- Check if a valid target is selected
    if mq.TLO.Target() then
        local distance = mq.TLO.Target.Distance3D()  -- Get the 3D distance to the target
        -- Check if the distance is within the maximum allowed distance
        if distance and distance <= maxDistance then
            return true  -- Target is in range
        else
            PRINTMETHOD(string.format("Error: Target is out of range (%.2f units away, max %d units).", distance, maxDistance))
        end
    else
        PRINTMETHOD("Error: No target selected.")
    end
    return false  -- Target is out of range or not selected
end

local function tradeitGUI()

    if not showtradeitGUI then return end

    ImGui.SetNextWindowSize(375, 475)

    if ImGui.Begin('TRADEIT') then

        ImGui.Separator()

        handleGlobalItemClick()

        -- Render Target Name Input (Auto-complete with Tab)
        ImGui.Text("Target Name:")
        nameInput = ImGui.InputText('##name', nameInput, 256)
        ImGui.SetNextItemWidth(100)

        -- Custom Button for "Use Current Target"
        ImGui.SameLine()
        ImGui.PushStyleColor(ImGuiCol.Button, 0.3, 0.0, 0.0, 1.0)  -- Button background color (dark red)
        ImGui.PushStyleColor(ImGuiCol.ButtonHovered, 0.5, 0.0, 0.0, 1.0)  -- Button hover color
        ImGui.PushStyleColor(ImGuiCol.ButtonActive, 1.0, 0.0, 0.0, 1.0)  -- Button active color
        if ImGui.Button("T", 20, 20) then
            nameInput = mq.TLO.Target.CleanName() or ""
        end
        ImGui.PopStyleColor(3)

        local closestMatch = nameInput ~= "" and findClosestMatch(nameInput) or nil
        if nameInput ~= "" and closestMatch and closestMatch:lower() ~= nameInput:lower() then
            ImGui.TextColored(0.5, 0.5, 0.5, 1.0, "Did you mean: " .. closestMatch)
        end

        if nameInput ~= "" and ImGui.IsKeyPressed(ImGuiKey.Tab) and closestMatch then
            autoCompletePendingName = true
            autoCompleteTimerName = os.clock() + 0.05
        end

        if autoCompletePendingName and os.clock() > autoCompleteTimerName then
            if closestMatch then
                nameInput = closestMatch
            end
            autoCompletePendingName = false
        end

        ImGui.Separator()

        -- Item Name Input (Auto-complete with Tab)
        ImGui.Text("Item Name:")
        itemNameInput = ImGui.InputText('##itemName', itemNameInput, 256)
        ImGui.SetNextItemWidth(100)
        renderItemIconButton()

        local closestItemMatch = itemNameInput ~= "" and findClosestItemMatch(itemNameInput) or nil
        if itemNameInput ~= "" and closestItemMatch and closestItemMatch:lower() ~= itemNameInput:lower() then
            ImGui.TextColored(0.5, 0.5, 0.5, 1.0, "Did you mean: " .. closestItemMatch)
        end

        if itemNameInput ~= "" and ImGui.IsKeyPressed(ImGuiKey.Tab) and closestItemMatch then
            autoCompletePendingItem = true
            autoCompleteTimerItem = os.clock() + 0.05
        end

        if autoCompletePendingItem and os.clock() > autoCompleteTimerItem then
            if closestItemMatch then
                itemNameInput = closestItemMatch
            end
            autoCompletePendingItem = false
        end

        -- Check if the item is non-stackable and set quantity accordingly
        if itemNameInput ~= "" and closestItemMatch then
            local item = mq.TLO.FindItem(closestItemMatch)
            if item and not item.Stackable() then
                itemQuantityInput = "1"  -- Set quantity to 1 for non-stackable items
            end
        end

        -- Item Quantity Input in the GUI
        ImGui.Text("Item Quantity:")
        itemQuantityInput = ImGui.InputText('##itemQuantity', CheckInputType('itemQuantityInput', itemQuantityInput, 'string'))

        -- Retrieve the available item quantity using getItemQuantity
        local availableItemQuantity = getItemQuantity(itemNameInput)
        if tonumber(itemQuantityInput) and tonumber(itemQuantityInput) > availableItemQuantity then
            itemQuantityInput = tostring(availableItemQuantity)
        end

        -- Button for setting the item quantity to the max available
        ImGui.SameLine()
        if ImGui.Button("All Item") then
            itemQuantityInput = tostring(availableItemQuantity)
        end

        -- Trade Item Button logic
        if ImGui.Button('Trade Item') then
            if not isTargetInRange(200) then
            elseif not ValidateTargetName(nameInput) then
                -- Handle invalid target name
            elseif not ValidateItemName(itemNameInput) then
                -- Handle invalid item name
            elseif not ValidateItemQuantity(itemQuantityInput, itemNameInput) then
                -- Handle invalid item quantity
            elseif tonumber(itemQuantityInput) == 0 then
                PRINTMETHOD("Item quantity cannot be 0.")
            else
                -- If all validations pass, proceed with the trade
                PRINTMETHOD("Giving item: " .. itemNameInput)
                mq.cmdf('/tradeit item "%s" "%s" %s', nameInput, itemNameInput, itemQuantityInput)
                PRINTMETHOD("Item successfully traded.")
            end
        end

        ImGui.Separator()

        -- Coin Quantity Section
        ImGui.Text("Coin Type:")
        if ImGui.RadioButton('Platinum', selectedCoinType == 0) then
            selectedCoinType = 0
            coinAmountInput = tostring(mq.TLO.Me.Platinum())  -- Automatically populate max coins
        end
        ImGui.SameLine()
        if ImGui.RadioButton('Gold', selectedCoinType == 1) then
            selectedCoinType = 1
            coinAmountInput = tostring(mq.TLO.Me.Gold())  -- Automatically populate max coins
        end
        ImGui.SameLine()
        if ImGui.RadioButton('Silver', selectedCoinType == 2) then
            selectedCoinType = 2
            coinAmountInput = tostring(mq.TLO.Me.Silver())  -- Automatically populate max coins
        end
        ImGui.SameLine()
        if ImGui.RadioButton('Copper', selectedCoinType == 3) then
            selectedCoinType = 3
            coinAmountInput = tostring(mq.TLO.Me.Copper())  -- Automatically populate max coins
        end

        coinTypeInput = coinTypes[selectedCoinType + 1]

        -- Coin Amount Input
        ImGui.Text("Coin Amount:")
        coinAmountInput = ImGui.InputText('##coinAmount', CheckInputType('coinAmountInput', coinAmountInput, 'string'))

        local availableCoinAmount = mq.TLO.Me[capitalize(coinTypeInput)]()
        if tonumber(coinAmountInput) and tonumber(coinAmountInput) > availableCoinAmount then
            coinAmountInput = tostring(availableCoinAmount)
        end

        ImGui.SameLine()
        if ImGui.Button("All Coin") then
            coinAmountInput = tostring(availableCoinAmount)
        end

        if ImGui.Button('Trade Coin') then
            if not isTargetInRange(200) then
            elseif not ValidateTargetName(nameInput) then
            elseif not ValidateCoinAmount(coinAmountInput) then
            else
                PRINTMETHOD("Checking available %s: %s", capitalize(coinTypeInput), availableCoinAmount or "nil")

                if availableCoinAmount == nil then
                    PRINTMETHOD("No %s available, please check the coin type.", capitalize(coinTypeInput))
                elseif availableCoinAmount < tonumber(coinAmountInput) then
                    PRINTMETHOD("Not enough %s available. You have %d, but need %s.", coinTypeInput, availableCoinAmount, coinAmountInput)
                else
                    mq.cmdf('/tradeit coin "%s" %s %s', nameInput, coinTypeInput, coinAmountInput)
                end
            end
        end

        ImGui.Separator()

        -- Group Distribution
        if ImGui.Button('Distribute to Group') then
            local isInGroup = mq.TLO.Me.Grouped()

            if isInGroup then
                if not isTargetInRange(200) then
                elseif ValidateCoinAmount(coinAmountInput) and availableCoinAmount >= tonumber(coinAmountInput) then
                    mq.cmdf('/tradeit group coin %s %s', coinTypeInput, coinAmountInput)
                else
                    PRINTMETHOD("Not enough coins or invalid input.")
                end
            else
                PRINTMETHOD("You are not in a group.")
            end
        end

        -- Raid Distribution
        if ImGui.Button('Distribute to Raid') then
            local isInRaid = mq.TLO.Raid.Members() > 0

            if isInRaid then
                if not isTargetInRange(200) then
                elseif ValidateCoinAmount(coinAmountInput) and availableCoinAmount >= tonumber(coinAmountInput) then
                    mq.cmdf('/tradeit raid coin %s %s', coinTypeInput, coinAmountInput)
                else
                    PRINTMETHOD("Not enough coins or invalid input.")
                end
            else
                PRINTMETHOD("You are not in a raid.")
            end
        end

        ImGui.Separator()

        -- END Button to stop the Lua script
        if ImGui.Button('END') then
            mq.cmd('/lua stop tradeit')
        end

    end

    ImGui.End()
end

-- Initialize ImGui and render the GUI
mq.imgui.init('TRADEIT', tradeitGUI)

local function setup()
    -- Register binds
    mq.bind('/tradeit', bind_tradeit)

    -- Populate member names initially
    populateMemberNames()
end

local function in_game()
    return mq.TLO.MacroQuest.GameState() == 'INGAME'
end

local function main()
    local last_time = os.time()
    while true do
        -- Run your game-related logic
        if in_game() then
            -- Populate member names every second to keep it updated
            if os.difftime(os.time(), last_time) >= 1 then
                last_time = os.time()
                populateMemberNames()  -- Refresh the member list
            end

            mq.doevents()
        end

        -- Delay before the next iteration of the loop
        mq.delay(100)
    end
end

setup()
main()