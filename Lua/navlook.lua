local mq = require("mq")
local player = mq.TLO.Me
local pitch_threshold = 0.1 -- Set the threshold for detecting elevation changes (Z-axis)
local xy_threshold = 2.00 -- Set the threshold for detecting X and Y movement
local previous_x = player.X()
local previous_y = player.Y()
local previous_z = player.Z()
local is_panning_up = false
local is_panning_down = false
local last_elevation_change_time = os.clock() -- Track time of the last elevation change

-- Print method for standardized output
local function PRINTMETHOD(printMessage, ...)
    printf("[tradeit] " .. printMessage, ...)
end

-- Function to check if levitation effect is active
local function has_levitation()
    return mq.TLO.Me.Levitating() -- Check if the character is levitating
end

-- Function to handle pitchup or pitchdown camera adjustments
local function handle_camera(direction)
    if direction == "up" and not is_panning_up then
        PRINTMETHOD("Holding Page Up key (pitch up)")
        mq.cmd('/keypress pitchup hold')  -- Hold the Page Up key
        is_panning_up = true
        is_panning_down = false
    elseif direction == "down" and not is_panning_down then
        PRINTMETHOD("Holding Page Down key (pitch down)")
        mq.cmd('/keypress pitchdown hold')  -- Hold the Page Down key
        is_panning_down = true
        is_panning_up = false
    end
end

-- Function to stop panning by releasing the pitch keys
local function stop_panning()
    if is_panning_up then
        PRINTMETHOD("Stopping pitch up movement")
        mq.cmd('/keypress pitchup') -- Release the Page Up key
        is_panning_up = false
    elseif is_panning_down then
        PRINTMETHOD("Stopping pitch down movement")
        mq.cmd('/keypress pitchdown') -- Release the Page Down key
        is_panning_down = false
    end
end

-- Function to adjust player's view based on Z-axis (elevation) changes
local function adjust_view_based_on_movement()
    local current_x = player.X() -- Get current X-coordinate
    local current_y = player.Y() -- Get current Y-coordinate
    local current_z = player.Z() -- Get current Z-coordinate
    local elevation_diff = current_z - previous_z -- Calculate elevation difference
    local xy_diff = math.abs(current_x - previous_x) + math.abs(current_y - previous_y) -- Check X and Y movements

    -- Output debugging information about X, Y, and Z positions and elevation difference
    PRINTMETHOD(string.format("Current X: %f, Y: %f, Z: %f, Elevation difference: %f", current_x, current_y, current_z, elevation_diff))

    -- Check if levitation is active
    if has_levitation() then
        PRINTMETHOD("Levitation effect active. Skipping camera adjustment.")
        stop_panning() -- Stop panning if levitation is active
    else
        -- Only consider Z-axis movement if X and Y have not changed significantly
        if xy_diff < xy_threshold and math.abs(elevation_diff) > pitch_threshold then
            -- Handle camera panning based on Z-axis direction
            if elevation_diff > 0 then
                PRINTMETHOD("Elevation increase detected without X/Y movement. Panning camera up.")
                handle_camera("up")
            elseif elevation_diff < 0 then
                PRINTMETHOD("Elevation decrease detected without X/Y movement. Panning camera down.")
                handle_camera("down")
            end
            last_elevation_change_time = os.clock() -- Update the last elevation change time
        else
            -- Stop panning only when Z movement stops or changes direction
            if math.abs(elevation_diff) <= pitch_threshold then
                PRINTMETHOD("Z movement stopped. Stopping camera pan.")
                stop_panning()
            end
        end
    end

    -- Update previous_x, previous_y, and previous_z for the next check
    previous_x = current_x
    previous_y = current_y
    previous_z = current_z
end

-- Main loop to monitor player movement and adjust view
while true do
    -- Check if navigation is active
    if mq.TLO.Navigation.Active() then
        adjust_view_based_on_movement() -- Adjust view based on X, Y, Z changes
    end
    
    mq.delay(500) -- Check every 100ms for smooth updates
end