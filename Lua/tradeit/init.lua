local mq = require('mq')
local imgui = require('ImGui')
local ffi = require('ffi')

local isOpen = true  -- Tracks whether the window is open

local coinTypes = {
    { name = "platinum", animation = "A_PlatinumCoinLarge" },
    { name = "gold", animation = "A_GoldCoinLarge" },
    { name = "silver", animation = "A_SilverCoinLarge" },
    { name = "copper", animation = "A_CopperCoinLarge" }
}

local autoCompletePendingName = false
local autoCompletePendingItem = false
local autoCompleteTimerName = 0
local autoCompleteTimerItem = 0

local selectedCoinTypeName = "Platinum"  -- Default to "Platinum" on startup
local selectedCoinTypeIndex = 0  -- Default index to 0 for "Platinum"
local coinTypeInput = "Platinum"  -- Default coinTypeInput to "Platinum"

local memberNames = {}
local showtradeitGUI = true  -- Flag to control the GUI visibility
local restrictToInventory = false
local allItemsProcessed = false

-- Define the state for the checkboxes
local filterRaidMembers = true
local filterGroupMembers = true
local filterNPCs = true
local filterPCs = true

-- Declare local variables
local prevItemName1, prevItemName2, prevItemName3, prevItemName4, prevItemName5, prevItemName6, prevItemName7, prevItemName8, prevItemName9 = "", "", "", "", "", "", "", "", ""
local prevItemNameQuantity1, prevItemNameQuantity2, prevItemNameQuantity3, prevItemNameQuantity4, prevItemNameQuantity5, prevItemNameQuantity6, prevItemNameQuantity7, prevItemNameQuantity8, prevItemNameQuantity9 = "", "", "", "", "", "", "", "", ""
local prevTargetName = ""

local suggestionList = {}      -- Hold suggestions
local showSuggestions = false   -- Control whether suggestions are shown

-- Initialize itemName and itemQuantity variables at the top (global scope)
local nameInput, itemName1, itemName2, itemName3, itemName4, itemName5, itemName6, itemName7, itemName8, itemName9 = "", "", "", "", "", "", "", "", "", ""
local coinAmountInput, itemQuantity1, itemQuantity2, itemQuantity3, itemQuantity4, itemQuantity5, itemQuantity6, itemQuantity7, itemQuantity8, itemQuantity9 = "0", "0", "0", "0", "0", "0", "0", "0", "0", "0"

-- Command to hide the tradeit GUI
local function hideTradeitGUI()
    showtradeitGUI = false
    printf("Tradeit GUI hidden.")
end

-- Command to show the tradeit GUI
local function showTradeitGUI()
    showtradeitGUI = true
    printf("Tradeit GUI shown.")
end

-- Function to capitalize the first letter of a string
local function capitalizeFirstLetter(str)
    return (str:gsub("^%l", string.upper))  -- Capitalizes the first letter
end

-- Function to center text in ImGui
function CenterText(text)
    local windowWidth = ImGui.GetWindowSize()
    local textWidth = ImGui.CalcTextSize(text)

    -- Calculate the starting horizontal position
    local centeredPosition = (windowWidth - textWidth) / 2

    -- Set the cursor position for the centered text
    ImGui.SetCursorPosX(centeredPosition)

    -- Render the text
    ImGui.Text(text)
end

-- Function to center and color text in ImGui
function CenterColoredText(text, color)
    local windowWidth = ImGui.GetWindowSize()
    local textWidth = ImGui.CalcTextSize(text)

    -- Calculate the starting horizontal position to center the text
    local centeredPosition = (windowWidth - textWidth) / 2

    -- Set the cursor position for the centered text
    ImGui.SetCursorPosX(centeredPosition)

    -- Render the colored text
    ImGui.TextColored(color[1], color[2], color[3], color[4], text)
end

-- Function to center text with part of it colored
function CenterTextWithColoredSection(leftText, coloredText, rightText, color)
    local windowWidth = ImGui.GetWindowSize()
    local fullText = leftText .. coloredText .. rightText
    local fullTextWidth = ImGui.CalcTextSize(fullText)
    
    -- Calculate the starting horizontal position to center the full text
    local centeredPosition = (windowWidth - fullTextWidth) / 2
    ImGui.SetCursorPosX(centeredPosition)

    -- Render the left part of the text (default color)
    ImGui.Text(leftText)
    
    -- Same line to keep the text on the same horizontal line
    ImGui.SameLine()

    -- Render the colored text (e.g., "Coins")
    ImGui.TextColored(color[1], color[2], color[3], color[4], coloredText)
    
    -- Same line again to continue on the same horizontal line
    ImGui.SameLine()

    -- Render the right part of the text (default color)
    ImGui.Text(rightText)
end


-- Handle item clicks while GUI is hovered
local function handleGlobalItemClick()
    if mq.TLO.Cursor() ~= nil and ImGui.IsWindowHovered() and ImGui.IsMouseClicked(ImGuiMouseButton.Left) then
        local cursorItem = mq.TLO.Cursor.Name()  -- Get the item on the cursor
        if cursorItem then
            -- Check if the item is NO-DROP
            if mq.TLO.Cursor.NoDrop() then
                printf("NO-DROP item cannot be placed in a trade field: " .. cursorItem)
                return  -- Do not allow the NO-DROP item to be placed in the field
            else
                itemName1 = cursorItem
                printf("Item autofilled: " .. cursorItem)
                mq.cmd("/autoinv")  -- Return the item to inventory
            end
        end
    end
end

-- Handle item clicks and autofill or clear fields
local function handleGlobalItemClickForList()
    if ImGui.IsWindowHovered() and ImGui.IsMouseClicked(ImGuiMouseButton.Left) then
        local cursorItem = mq.TLO.Cursor.Name()  -- Get the item on the cursor
       
        if cursorItem then
            -- Check if the item is NO-DROP
            if mq.TLO.Cursor.NoDrop() then
                printf("NO-DROP item cannot be placed in a trade field: " .. cursorItem)
                return  -- Do not allow the NO-DROP item to be placed in the field
            end
            -- Autofill the next available empty field with the item on the cursor
            if itemName1 == "" or itemName1 == nil then
                itemName1 = cursorItem
                printf("Item autofilled in field 1: " .. cursorItem)
            elseif itemName2 == "" or itemName2 == nil then
                itemName2 = cursorItem
                printf("Item autofilled in field 2: " .. cursorItem)
            elseif itemName3 == "" or itemName3 == nil then
                itemName3 = cursorItem
                printf("Item autofilled in field 3: " .. cursorItem)
            elseif itemName4 == "" or itemName4 == nil then
                itemName4 = cursorItem
                printf("Item autofilled in field 4: " .. cursorItem)
            elseif itemName5 == "" or itemName5 == nil then
                itemName5 = cursorItem
                printf("Item autofilled in field 5: " .. cursorItem)
            elseif itemName6 == "" or itemName6 == nil then
                itemName6 = cursorItem
                printf("Item autofilled in field 6: " .. cursorItem)
            elseif itemName7 == "" or itemName7 == nil then
                itemName7 = cursorItem
                printf("Item autofilled in field 7: " .. cursorItem)
            elseif itemName8 == "" or itemName8 == nil then
                itemName8 = cursorItem
                printf("Item autofilled in field 8: " .. cursorItem)
            else
                printf("No empty field available.")
            end

            mq.cmd("/autoinv")  -- Return the item to inventory after filling the field
        else
            -- Clear the clicked field if the cursor is empty
            if ImGui.IsItemHovered() and itemName1 ~= "" then
                itemName1 = ""
                printf("Field 1 cleared.")
            elseif ImGui.IsItemHovered() and itemName2 ~= "" then
                itemName2 = ""
                printf("Field 2 cleared.")
            elseif ImGui.IsItemHovered() and itemName3 ~= "" then
                itemName3 = ""
                printf("Field 3 cleared.")
            elseif ImGui.IsItemHovered() and itemName4 ~= "" then
                itemName4 = ""
                printf("Field 4 cleared.")
            elseif ImGui.IsItemHovered() and itemName5 ~= "" then
                itemName5 = ""
                printf("Field 5 cleared.")
            elseif ImGui.IsItemHovered() and itemName6 ~= "" then
                itemName6 = ""
                printf("Field 6 cleared.")
            elseif ImGui.IsItemHovered() and itemName7 ~= "" then
                itemName7 = ""
                printf("Field 7 cleared.")
            elseif ImGui.IsItemHovered() and itemName8 ~= "" then
                itemName8 = ""
                printf("Field 8 cleared.")
            end
        end
    end
end

local function restrictToInventoryCheck(itemName)
    -- Check if restrictToInventory is enabled and validate item location
    if restrictToInventory then
        -- Find the item by exact name in the player's inventory (checking all slots)
        local inventoryItem = mq.TLO.FindItem("=" .. itemName)

        if inventoryItem and inventoryItem() then
            local itemSlot = inventoryItem.ItemSlot()  -- Get the item slot number

            -- Check if the item is in the bag slots (slots 23 to 32)
            if itemSlot < 23 or itemSlot > 32 then
                printf("Item '" .. itemName .. "' is not in a bag (restricted to bags).")
                return false  -- Skip the trade if the item is not found in a bag
            end
        else
            printf("Item '" .. itemName .. "' not found in inventory.")
            return false  -- Skip if item is not found
        end
    end
    return true  -- Item is valid for trade if checks pass
end

local function isItemAugmented(item)
    if item.Augs() > 0 then  -- Check if the item has any augment slots used
        for augSlot = 1, item.Augs() do
            if item.AugSlot(augSlot)() then
                return true  -- Return true if any augment slot is occupied
            end
        end
    end
    return false  -- Return false if no augment slots are occupied
end

local function findUnslottedItem(itemName)
    -- Adjust slot range based on restrictToInventory flag
    local startSlot, endSlot
    if restrictToInventory then
        startSlot, endSlot = 23, 32  -- Only check bag slots (23-32)
    else
        startSlot, endSlot = 0, 32  -- Check all inventory and bag slots (0-32)
    end

    -- Check all main inventory slots (and bag slots if not restricted)
    for invSlot = startSlot, endSlot do
        local item = mq.TLO.Me.Inventory(invSlot)
        if item() and item.Name():lower() == itemName:lower() and not isItemAugmented(item) then
            return item  -- Return the unslotted item if found
        end

        -- If the slot contains a bag, check the items inside the bag
        if item() and item.Container() > 0 then  -- This is a bag
            -- Check each item inside the container
            for bagSlot = 1, item.Container() do
                local bagItem = item.Item(bagSlot)  -- Get the item inside the container
                if bagItem() and bagItem.Name():lower() == itemName:lower() and not isItemAugmented(bagItem) then
                    return bagItem  -- Return the item found inside the container
                end
            end
        end
    end

    return nil  -- Return nil if no unslotted item is found
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

-- Function to check if a given name is a raid member
local function isRaidMember(name)
    local raidMemberCount = mq.TLO.Raid.Members() or 0
    for i = 1, raidMemberCount do
        local raidMember = mq.TLO.Raid.Member(i).Name()
        if raidMember and raidMember:lower() == name:lower() then
            return true
        end
    end
    return false
end

-- Function to check if a given name is a group member
local function isGroupMember(name)
    local groupMemberCount = mq.TLO.Group.Members() or 0
    for i = 1, groupMemberCount do
        local groupMember = mq.TLO.Group.Member(i).Name()
        if groupMember and groupMember:lower() == name:lower() then
            return true
        end
    end
    return false
end

local function findClosestMatches(input, includeRaidMembers, includeGroupMembers, includeNPCs, includePCs)
    input = input:lower()
    local potentialNameMatches = {}

    -- Match raid/group members if the respective filter is enabled
    if includeRaidMembers or includeGroupMembers then
        for _, name in ipairs(memberNames) do
            if name:lower():find(input, 1, true) then
                -- Check if it's a raid member or group member depending on the filter
                if includeRaidMembers and isRaidMember(name) then
                    table.insert(potentialNameMatches, name)
                elseif includeGroupMembers and isGroupMember(name) then
                    table.insert(potentialNameMatches, name)
                end
            end
        end
    end

    -- Match NPCs within 200 units if the NPC filter is enabled
    if includeNPCs then
        local npcCount = mq.TLO.SpawnCount("npc")() or 0
        for i = 1, npcCount do
            local npc = mq.TLO.NearestSpawn(i, "npc")
            if npc() and npc.Distance3D() <= 200 then
                local cleanName = npc.CleanName():lower()
                if cleanName:find(input, 1, true) then
                    table.insert(potentialNameMatches, npc.CleanName())
                end
            end
        end
    end

    -- Match nearby PCs (not in raid/group) within 200 units if the PC filter is enabled
    if includePCs then
        local playerCount = mq.TLO.SpawnCount("pc")() or 0
        for i = 1, playerCount do
            local pc = mq.TLO.NearestSpawn(i, "pc")
            if pc() and pc.Distance3D() <= 200 and not isRaidOrGroupMember(pc.Name()) then
                local cleanName = pc.CleanName():lower()
                if cleanName:find(input, 1, true) then
                    table.insert(potentialNameMatches, pc.CleanName())
                end
            end
        end
    end

    -- Return the list of all potential matches
    return potentialNameMatches
end

-- Validate the target name (NPC or PC)
local function ValidateTargetID(targetID)
    if not targetID or targetID == "" then
        printf("No target ID provided.")
        return false
    end

    local nearbySpawn = mq.TLO.Spawn(targetID)
    if nearbySpawn() then
        printf('Targeting ID %s.', targetID)
        mq.cmd('/target id ' .. targetID)
        mq.delay(200)  -- Short delay for target acquisition
        return true
    else
        printf("TargetID '%s' not found nearby.", targetID)
        return false
    end
end


-- Render item icon button in the GUI for a specific item field
local function renderItemIconButton(itemName)
    local itemIconID = mq.TLO.FindItem(itemName) and mq.TLO.FindItem(itemName).Icon() or nil

    -- Set icon button properties
    ImGui.SameLine()
    ImGui.BeginGroup()

    local x, y = ImGui.GetCursorPos()

    -- Button color styling
    ImGui.PushStyleColor(ImGuiCol.Button, ImVec4(0, 0, 0, 0.1)) 
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

-- Function to render the coin icon button with animation and handle input
local function renderCoinIconButton(coin, index)
    ImGui.SameLine()
    ImGui.BeginGroup()

    local x, y = ImGui.GetCursorPos()

    ImGui.PushStyleColor(ImGuiCol.Button, ImVec4(0, 0, 0, 0))
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered, ImVec4(1, 1, 1, 0.05))
    ImGui.PushStyleColor(ImGuiCol.ButtonActive, ImVec4(1, 1, 1, 0.15))

    if ImGui.Button("##coinIconButton" .. index, ImVec2(32, 32)) then
        -- If the button is clicked, update the selected coin type
        selectedCoinTypeName = coin.name or ""
        coinTypeInput = selectedCoinTypeName
    end

    -- Reset the cursor position to draw the texture over the invisible button
    ImGui.SetCursorPosX(x)
    ImGui.SetCursorPosY(y)

    local animItems = mq.FindTextureAnimation(coin.animation)
  
    if animItems then
        animItems:SetTextureCell(0)
        ImGui.DrawTextureAnimation(animItems, 32, 32)
    else
        print("Failed to find texture animation for:", coin.animation)
    end

    -- Pop the color styling back to the previous state
    ImGui.PopStyleColor(3)

    -- End ImGui group (ensure BeginGroup/EndGroup are balanced)
    ImGui.EndGroup()
end

local function isItemInAugSlot(item)
    -- Check if the item is an augment in another item
    for augSlot = 1, 6 do  -- Check all possible augment slots (up to 6 slots)
        local augment = item.AugSlot(augSlot)
        if augment() and not augment.Empty() then
            return true  -- The item is slotted inside another item
        end
    end
    return false  -- The item is not an augment in another item
end

local function findClosestItemMatch(input)
    input = input:lower()
    local closestMatch = nil
    local potentialItemMatches = {}

    -- Check main inventory slots (0-32)
    for i = 0, 32 do
        local item = mq.TLO.Me.Inventory(i)
        if item() then
            local itemNameLower = item.Name():lower()
            -- Check if the item name contains the input as a substring
            if itemNameLower:find(input, 1, true) then
                table.insert(potentialItemMatches, itemNameLower)  -- Store potential match
            end
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
                    if containerItem() then
                        local containerItemNameLower = containerItem.Name():lower()
                        -- Check if the container item's name contains the input as a substring
                        if containerItemNameLower:find(input, 1, true) then
                            table.insert(potentialItemMatches, containerItemNameLower)  -- Store potential match
                        end
                    end
                end
            end
        end
    end

    -- Return the potential matches found
    return potentialItemMatches
end


-- Find the total available quantity of an item (inventory and bags)
local function getItemQuantity(itemName)
    local totalQuantity = 0

    -- Check main inventory slots (0-32)
    for i = 0, 32 do
        local item = mq.TLO.Me.Inventory(i)
        if item() then
            local itemNameLower = item.Name():lower()
            if itemNameLower == itemName:lower() then
                local stackSize = item.Stack() or 1
                totalQuantity = totalQuantity + (item.Stackable() and stackSize or 1)
            end
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
                    if containerItem() then
                        local containerItemNameLower = containerItem.Name():lower()
                        if containerItemNameLower == itemName:lower() then
                            local stackSize = containerItem.Stack() or 1
                             totalQuantity = totalQuantity + (containerItem.Stackable() and stackSize or 1)
                        end
                    end
                end
            end
        end
    end

    print(string.format("Total quantity for %s: %d", itemName, totalQuantity))  -- Final total output
    return totalQuantity
end

-- Function to validate the item quantity 
local function ValidateItemQuantity(quantity, itemName)
    local availableItemQuantity = getItemQuantity(itemName)  -- Use getItemQuantity for consistency

    if not quantity or quantity == "" then
        printf("Item quantity is missing.")
        return false
    end
    if tonumber(quantity) == nil or tonumber(quantity) <= 0 then
        printf("Item quantity '" .. quantity .. "' is invalid. It must be a positive number.")
        return false
    end
    if tonumber(quantity) > availableItemQuantity then
        printf("Item quantity '" .. quantity .. "' exceeds available quantity (" .. availableItemQuantity .. ").")
        return false
    end
    return true
end

-- Function to validate the item name
local function ValidateItemName(itemName)
    if not itemName or itemName == "" then
        printf("Item name is missing.")
        return false
    end

    -- Use mq.TLO.FindItem to check if the item exists in the inventory
    if not mq.TLO.FindItem(itemName)() then
        printf("Item name '" .. itemName .. "' is invalid or not found in your inventory.")
        return false
    end

    return true
end

-- Function to handle max quantity button (set to maximum available)
local function itemMaxQuantity(itemNameInput)
    -- Get the item object using its name
    local item = mq.TLO.FindItem(itemNameInput)
    
    -- Check if the item exists
    if item and item() then
        -- Check if the item is non-stackable
        if not item.Stackable() then
            print("Item '" .. itemNameInput .. "' is NOT stackable. Setting max quantity to 1.")
            return "1"  -- Return 1 for non-stackable items
        else
            -- If stackable, retrieve the available quantity
            local availableItemQuantity = getItemQuantity(itemNameInput)
            return tostring(availableItemQuantity)  -- Return available quantity as string
        end
    else
        print("Error: Could not find item '" .. itemNameInput .. "' in inventory.")
        return "0"  -- Return 0 if the item is not found
    end
end


local function tradeit(itemName, qty)
    -- Validate the item using the new logic
    if not ValidateItemName(itemName) then
        printf("Item '" .. itemName .. "' is invalid or not found in inventory!")
        return
    end

    -- Get the available quantity using getItemQuantity
    local availableItemQuantity = getItemQuantity(itemName)

    -- Ensure qty is valid and convert it to a number
    if qty == nil or qty == "" then
        printf("Item quantity is missing.")
        return
    end
    qty = tonumber(qty)

    -- Check if qty is a valid number
    if not qty or qty <= 0 then
        printf("Invalid item quantity '" .. tostring(qty) .. "'. It must be a positive number.")
        return
    end

    -- If quantity exceeds available item quantity
    if qty > availableItemQuantity then
        printf("Requested quantity '" .. qty .. "' exceeds available quantity (" .. availableItemQuantity .. ").")
        return
    end

    -- Find an unslotted item instance in inventory (and bags if necessary)
    local item = findUnslottedItem(itemName)

    -- If no unslotted item is found, output an error
    if not item then
        printf("No unslotted instance of '" .. itemName .. "' found in inventory or bags.")
        return
    end

    -- Proceed with item finding and pickup logic
    local itemSlot = item.ItemSlot()
    local itemSlot2 = item.ItemSlot2()

    -- Determine if the item is in a bag or the main inventory
    if itemSlot >= 23 and itemSlot <= 32 then
        -- For bag slots (23-32)
        local bagSlot = itemSlot - 22
        mq.cmd('/itemnotify in pack' .. bagSlot .. ' ' .. (itemSlot2 + 1) .. ' leftmouseup')
    elseif itemSlot >= 0 and itemSlot <= 22 then
        -- For main inventory slots (0-22)
        mq.cmd('/itemnotify ' .. itemSlot .. ' leftmouseup')
    else
        return
    end

    -- If it's stackable, adjust quantity in the trade window
    if qty ~= 'all' and item.Stackable() then
        mq.delay(5000, function() return mq.TLO.Window("QuantityWnd").Open() end)
        while mq.TLO.Window("QuantityWnd").Child("QTYW_SliderInput").Text() ~= tostring(qty) do
            mq.TLO.Window("QuantityWnd").Child("QTYW_SliderInput").SetText(tostring(qty))
            mq.delay(500)
        end
    end

    -- Finalize the trade
    while mq.TLO.Window("QuantityWnd").Open() do
        mq.TLO.Window("QuantityWnd").Child("QTYW_Accept_Button").LeftMouseUp()
        mq.delay(10)
    end

    -- Perform the trade
    mq.delay(5000, function() return mq.TLO.Cursor() ~= nil end)
    mq.cmd('/click left target')
    mq.delay(5000, function() return mq.TLO.Cursor() == nil end)
end


-- Function to validate the coin amount
local function ValidateCoinAmount(coinAmount)
    if not coinAmount or coinAmount == "" then
        printf("Coin amount is missing.")
        return false
    end
    if tonumber(coinAmount) == nil or tonumber(coinAmount) <= 0 then
        printf("Coin amount '" .. coinAmount .. "' is invalid. It must be a positive number.")
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

    -- Normalize coin name to lowercase
    local normalizedCoinName = itemName:lower()

    -- If the amount is "all", set amt to nil so it bypasses amount checks
    local isAll = (amt == 'all')

    -- Helper function to handle coin transfer
    local function handleCoinTransfer(coinType, availableCoinAmount)
        local coinIndex = coinWindowIndex[coinType]
        if availableCoinAmount >= 1 then
            if isAll or (tonumber(amt) and tonumber(amt) <= availableCoinAmount) then
                -- Click the appropriate coin slot to transfer to the cursor
                mq.TLO.Window("InventoryWindow").Child("IW_Money" .. coinIndex).LeftMouseUp()

                -- Wait for the Quantity Window to open if not transferring all
                if not isAll then
                    mq.delay(5000, function() return mq.TLO.Window("QuantityWnd").Open() end)

                    -- Adjust quantity in the Quantity Window with a timeout fail-safe
                    local timeout = mq.gettime() + 5000  -- 5-second timeout
                    while mq.TLO.Window("QuantityWnd").Child("QTYW_SliderInput").Text() ~= amt and mq.gettime() < timeout do
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
                printf("Not enough %s! Available: %d, Requested: %s", coinType, availableCoinAmount, amt)
            end
        else
            printf("No %s available in inventory!", coinType)
        end
    end

    -- Check and transfer coins based on coin type
    if normalizedCoinName == 'platinum' then
        local availablePlatinum = mq.TLO.Me.Platinum()
        handleCoinTransfer('platinum', availablePlatinum)

    elseif normalizedCoinName == 'gold' then
        local availableGold = mq.TLO.Me.Gold()
        handleCoinTransfer('gold', availableGold)

    elseif normalizedCoinName == 'silver' then
        local availableSilver = mq.TLO.Me.Silver()
        handleCoinTransfer('silver', availableSilver)

    elseif normalizedCoinName == 'copper' then
        local availableCopper = mq.TLO.Me.Copper()
        handleCoinTransfer('copper', availableCopper)

    else
        printf("Invalid coin type: %s", itemName)
    end
end

-- The other functions are likely correct, but ensure the element names match your UI.
local function OpenInventory()
    printf('Opening Inventory')
    mq.TLO.Window('InventoryWindow').DoOpen()
    mq.delay(1500, function() return mq.TLO.Window('InventoryWindow').Open() end)
end

local function ClickTrade()
    mq.delay(1000)
    mq.TLO.Window("TradeWnd").Child("TRDW_Trade_Button").LeftMouseUp()
    mq.delay(500)
end

local function NavToTradeTargetByID(targetID)
    local distance = mq.TLO.Spawn("id " .. targetID).Distance3D() or 0
    if distance > 20 then
        printf('Moving to ID %s.', targetID)
        mq.cmd('/nav id ' .. targetID)
        while mq.TLO.Navigation.Active() and mq.TLO.Spawn("id " .. targetID).Distance3D() > 20 do
            mq.delay(50)
        end
        mq.cmd('/nav stop')
        mq.cmd('/face')  -- Face the target
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
        ValidateTargetID(targetID)
        NavToTradeTargetByID(targetID)
        OpenInventory()
        tradeit(itemName, quantity)
        ClickTrade()
        return true

    elseif cmd == 'list' and targetID then
            ValidateTargetID(targetID)
            NavToTradeTargetByID(targetID)
            OpenInventory()
    
            -- Wait until all items have been processed by the button
            if allItemsProcessed then
                -- Once all items are processed, click trade
                ClickTrade()
                allItemsProcessed = false -- Reset the flag after trading
                return true
            else
                printf("Waiting for all items to be processed before clicking trade.")
                return false
            end

    elseif cmd == 'coin' and targetID and itemName and amt then
        ValidateTargetID(targetID)
        NavToTradeTargetByID(targetID)
        OpenInventory()
        tradeitCoin(itemName, amt)
        ClickTrade()

    elseif cmd == 'group' and itemName and amt then
        OpenInventory()
        local groupMemberCount = mq.TLO.Group.Members()
        for i = 1, groupMemberCount do
            local memberID = mq.TLO.Group.Member(i).ID()
            local isOtherZone = mq.TLO.Group.Member(i).OtherZone()  -- Check if the group member is in another zone
            if memberID and mq.TLO.Me.CleanName() ~= mq.TLO.Group.Member(i).CleanName() then
                -- Check if the group member is in the same zone as the player
                if not isOtherZone then  -- Only trade if the group member is in the same zone
                    ValidateTargetID(memberID)
                    NavToTradeTargetByID(memberID)
                    tradeitCoin(itemName, amt)
                    ClickTrade()
                else
                    printf("Skipping group member %s: not in the same zone.", mq.TLO.Group.Member(i).CleanName())
                end
            end
        end

    elseif cmd == 'raid' and itemName and amt then
        OpenInventory()
        local raidMemberCount = mq.TLO.Raid.Members()
        for i = 1, raidMemberCount do
            local memberName = mq.TLO.Raid.Member(i).CleanName()
            local spawnID = mq.TLO.Spawn(memberName).ID()  -- Get spawn ID, 0 if not online or not in the same zone
            if spawnID > 0 and mq.TLO.Me.CleanName() ~= memberName then
                ValidateTargetID(spawnID)
                NavToTradeTargetByID(spawnID)
                tradeitCoin(itemName, amt)
                ClickTrade()
            else
                printf("Skipping raid member %s: not in the same zone or offline.", memberName)
            end
        end
    end
end

local function isSpawnInRange(spawnName, maxDistance)
    local spawn = mq.TLO.Spawn(spawnName)
    
    if spawn() then
        local distance = spawn.Distance()
        if distance and distance <= maxDistance then
            return true
        else
            printf(string.format("Error: Spawn '%s' is out of range (%.2f units away, max %d units).", spawnName, distance, maxDistance))
        end
    else
        printf(string.format("Error: Spawn '%s' not found.", spawnName))
    end
    return false
end

-- Function to handle autocomplete
local function handleAutoCompleteItem(itemName)
    if itemName ~= "" then
        local allSuggestions = findClosestItemMatch(itemName)
        local uniqueSuggestions = {}  -- Table to hold unique suggestions

        -- Add unique items to the suggestion list
        for _, suggestion in ipairs(allSuggestions) do
            local lowerSuggestion = suggestion:lower()
            if not uniqueSuggestions[lowerSuggestion] then
                uniqueSuggestions[lowerSuggestion] = suggestion  -- Store unique item
            end
        end

        -- Convert uniqueSuggestions table back to a list
        suggestionList = {}
        for _, uniqueSuggestion in pairs(uniqueSuggestions) do
            table.insert(suggestionList, uniqueSuggestion)
        end

        -- Check if the input exactly matches any item in the suggestion list
        local exactMatchFound = false
        for _, suggestion in ipairs(suggestionList) do
            if suggestion:lower() == itemName:lower() then
                exactMatchFound = true
                break
            end
        end

        -- Show suggestions if we have matches and there's no exact match
        showSuggestions = #suggestionList > 0 and not exactMatchFound
    else
        showSuggestions = false  -- No input, hide suggestions
    end

    -- Return the input, no change in case of no match
    return itemName
end

local function quantityValidation(itemQuantityInput)
    -- Validate the input to ensure it's a number, and show an error message if it's invalid
    local isValidNumber = true
    if not tonumber(itemQuantityInput) then
        isValidNumber = false  -- Invalid input, mark it for error message
    end

    -- Display an error message if the input is not valid
    if not isValidNumber then
        ImGui.TextColored(1, 0, 0, 1, "Please enter a valid number.") -- Error message in red
    end
end

local function renderTargetInputSection()
    -- Centered section header with colored text
    CenterTextWithColoredSection("------------------------= ", "Target", " =------------------------", {1.0, 1.0, 0.0, 1.0})
    ImGui.Separator()

    -- Render Target Name Input (Auto-complete with Tab)
    ImGui.Text("Target Name:")
    ImGui.SetNextItemWidth(200)
    nameInput = ImGui.InputText('##name', nameInput, 256)
    ImGui.SetNextItemWidth(100)

    -- Custom Button for "Use Current Target"
    ImGui.SameLine()
    ImGui.PushStyleColor(ImGuiCol.Button, ImVec4(0.3, 0.0, 0.0, 1.0))
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered, ImVec4(0.5, 0.0, 0.0, 1.0))
    ImGui.PushStyleColor(ImGuiCol.ButtonActive, ImVec4(1.0, 0.0, 0.0, 1.0))
    if ImGui.Button("T", 20, 20) then
        nameInput = mq.TLO.Target.CleanName() or ""
        prevTargetName = nameInput
    end
    ImGui.PopStyleColor(3)

    -- GUI logic for suggestion list
    local suggestionNameList = nameInput ~= "" and findClosestMatches(nameInput, filterRaidMembers, filterGroupMembers, filterNPCs, filterPCs) or {} 
    local showNameSuggestions = nameInput ~= "" and #suggestionNameList > 0

    -- Display the dropdown of suggestions if there are any
    if showNameSuggestions and prevTargetName ~= nameInput then
        ImGui.BeginChild("##suggestions", 200, 100, ImGuiChildFlags.Scrollable)
        for _, suggestion in ipairs(suggestionNameList) do
            if ImGui.Selectable(suggestion) then
                nameInput = suggestion
                prevTargetName = nameInput
                -- After selecting, we should clear the input for suggestion list and hide it
                suggestionNameList = {}  -- Clear the suggestions
                showNameSuggestions = false  -- Disable further showing of suggestions
                break  -- Immediately break the loop after selection to stop rendering the list
            end
        end
        ImGui.EndChild()
    end

    -- Collapsible section for filter checkboxes
    if ImGui.CollapsingHeader("Filters") then
        -- Display the checkboxes for filtering
        filterRaidMembers, _ = ImGui.Checkbox("Raid Members", filterRaidMembers)
        filterGroupMembers, _ = ImGui.Checkbox("Group Members", filterGroupMembers)
        filterNPCs, _ = ImGui.Checkbox("NPCs", filterNPCs)
        filterPCs, _ = ImGui.Checkbox("PCs (not in raid/group)", filterPCs)
    end
    ImGui.NewLine()
    ImGui.Separator()
end

local function renderTradeItemInputSection()
    
    CenterTextWithColoredSection("------------------------= ", "Item", " =------------------------", {1.0, 1.0, 0.0, 1.0})
    ImGui.Separator()

-- Item 1 Input and Quantity Handling
ImGui.Text("Item 1:")
ImGui.SameLine(270)
ImGui.SetNextItemWidth(50)
ImGui.Text("Qty:")
ImGui.SetNextItemWidth(200)

itemName1 = ImGui.InputText('##itemName1', itemName1, 256)
ImGui.SameLine()
renderItemIconButton(itemName1)

-- Ensure itemQuantity1 is on the same line after the icon button
ImGui.SameLine()
ImGui.SetNextItemWidth(40)  -- Set the width for the quantity input
itemQuantity1 = ImGui.InputText('##itemQuantity1', itemQuantity1)
ImGui.SameLine()
if ImGui.Button("All##Item1") then
    itemQuantity1 = itemMaxQuantity(itemName1)
end

if itemName1 and itemName1 ~= prevItemName1 then
    if itemName1 ~= "" then
        itemName1 = handleAutoCompleteItem(itemName1)
        prevItemName1 = itemName1
    end
end

if itemName1 ~= "" and showSuggestions and #suggestionList > 0 then
    ImGui.BeginChild("##suggestions1", 200, 100, ImGuiChildFlags.Scrollable)
    for _, suggestion in ipairs(suggestionList) do
        if ImGui.Selectable(suggestion) then
            itemName1 = suggestion
            suggestionList = {}
            showSuggestions = false
        end
    end
    ImGui.EndChild()
end

if itemName1 and itemName1 ~= prevItemNameQuantity1 and itemName1 ~= "" then
    if itemQuantity1 == nil or itemQuantity1 == "" or itemQuantity1 == "0" or tonumber(itemQuantity1) > 1 then
        if not mq.TLO.FindItem(itemName1).Stackable() then
            itemQuantity1 = "1"
            prevItemNameQuantity1 = itemName1
        end
    end
end

quantityValidation(itemQuantity1)

ImGui.NewLine()

-- Trade Item Button logic
if ImGui.Button('Trade') then
    if not ValidateItemName(itemName1) then
        printf("Invalid item name: %s", itemName1)
    elseif not ValidateItemQuantity(itemQuantity1, itemName1) then
        printf("Invalid quantity for item: %s", itemName1)
    elseif tonumber(itemQuantity1) == 0 then
        printf("Item quantity cannot be 0.")
    elseif nameInput == "" then
        printf("Target name is missing.")
    elseif not isSpawnInRange(nameInput, 200) then
        printf("Target is out of range.")
    elseif not restrictToInventoryCheck(itemName1) then
    else
        -- If all validations pass, proceed with the trade
        mq.cmdf('/tradeit item "%s" "%s" %s', nameInput, itemName1, itemQuantity1)
    end
end

ImGui.SameLine()

-- Render the checkbox
restrictToInventory = ImGui.Checkbox("Inventory Only", restrictToInventory)

end

local function renderTradeCoinsInputSection()
    
    CenterTextWithColoredSection("------------------------= ", "Coins", " =------------------------", {1.0, 1.0, 0.0, 1.0})

    ImGui.Separator()
    imgui.NewLine()
    -- Example: Render buttons for each coin type
    for i, coin in ipairs(coinTypes) do
        renderCoinIconButton(coin, i - 1)  -- Render each coin button with its corresponding animation and index

        -- Position buttons in the same line
        if i < #coinTypes then
            ImGui.SameLine()
        end
    end

    -- Coin Amount Input
    ImGui.Text("Amount:")
    ImGui.SetNextItemWidth(80)

    -- Input field for coin amount
    coinAmountInput = ImGui.InputText('##coinAmount', CheckInputType('coinAmountInput', coinAmountInput, 'string'))

    -- Safely get the available coin amount using the selected coin type dynamically
    local availableCoinAmount = 0
    if coinTypeInput then
        -- Capitalize the first letter of coinTypeInput
        local capitalizedCoinType = capitalizeFirstLetter(coinTypeInput)
        
        -- Check if mq.TLO.Me[capitalizedCoinType] exists and retrieve its value
        if mq.TLO.Me[capitalizedCoinType] then
            availableCoinAmount = mq.TLO.Me[capitalizedCoinType]() or 0  -- Dynamically retrieve the available amount for the selected coin type
        end
    end

    -- Ensure the input is not greater than the available coin amount
    if tonumber(coinAmountInput) and tonumber(coinAmountInput) > availableCoinAmount then
        coinAmountInput = tostring(availableCoinAmount)  -- Set to max available if input exceeds available
    end

    -- Button to set the coin amount to the max available
    ImGui.SameLine()
    if ImGui.Button("All") then
        coinAmountInput = tostring(availableCoinAmount)  -- Set the input to max available coins
    end

    imgui.NewLine()

    if ImGui.Button('Trade') then
        if not isSpawnInRange(nameInput, 200) then
        elseif not ValidateCoinAmount(coinAmountInput) then
        else
            printf("Checking available %s: %s", capitalize(coinTypeInput), availableCoinAmount or "nil")

            if availableCoinAmount == nil then
                printf("No %s available, please check the coin type.", capitalize(coinTypeInput))
            elseif availableCoinAmount < tonumber(coinAmountInput) then
                printf("Not enough %s available. You have %d, but need %s.", coinTypeInput, availableCoinAmount, coinAmountInput)
            else
                mq.cmdf('/tradeit coin "%s" %s %s', nameInput, coinTypeInput, coinAmountInput)
            end
        end
    end

    imgui.SameLine()         

    -- Group Distribution
    if ImGui.Button('Group') then
        local isInGroup = mq.TLO.Me.Grouped()

        if isInGroup then
            if ValidateCoinAmount(coinAmountInput) and availableCoinAmount >= tonumber(coinAmountInput) then
                mq.cmdf('/tradeit group coin %s %s', coinTypeInput, coinAmountInput)
            else
                printf("Not enough coins or invalid input.")
            end
        else
            printf("You are not in a group.")
        end
    end

    imgui.SameLine()    

    -- Raid Distribution
    if ImGui.Button('Raid') then
        local isInRaid = mq.TLO.Raid.Members() > 0

        if isInRaid then
            if ValidateCoinAmount(coinAmountInput) and availableCoinAmount >= tonumber(coinAmountInput) then
                mq.cmdf('/tradeit raid coin %s %s', coinTypeInput, coinAmountInput)
            else
                printf("Not enough coins or invalid input.")
            end
        else
            printf("You are not in a raid.")
        end
    end

    end


local function tradeitGUI()

    -- Exit if GUI is not meant to be shown
    if not showtradeitGUI then return end

    -- Set window size
    ImGui.SetNextWindowSize(360, 630)

    -- Begin ImGui window with a unique identifier and close behavior
    isOpen, _ = ImGui.Begin("TRADEIT", isOpen, 2)

    -- If the window is closed (user pressed "X"), stop the script
    if not isOpen then
        mq.cmd("/lua stop tradeit")
    end

    -- Add a separator for better UI clarity
    ImGui.Separator()

    -- Begin the tab bar
    if ImGui.BeginTabBar("TradeTabs") then

        -- First Tab: Items Trade
        if ImGui.BeginTabItem("Items") then
            -- Handle global item clicks and render the target and trade item input sections
            handleGlobalItemClick()
            renderTargetInputSection()
            renderTradeItemInputSection()

            -- End the "Items" tab
            ImGui.EndTabItem()
        end

        -- Second Tab: Coins Trade
        if ImGui.BeginTabItem("Coins") then
            -- Render the target and trade coins input sections
            renderTargetInputSection()
            renderTradeCoinsInputSection()

            -- End the "Coins" tab
            ImGui.EndTabItem()
        end

        -- End the tab bar
        ImGui.EndTabBar()
    end

    -- End the window
    ImGui.End()
end

-- Initialize ImGui and render the GUI
mq.imgui.init('TRADEIT', tradeitGUI)


local function setup()
    -- Register commands to hide/show the GUI
    mq.bind('/tradeithide', hideTradeitGUI)
    mq.bind('/tradeitshow', showTradeitGUI)
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
        mq.delay(200)
    end
end

setup()
main()