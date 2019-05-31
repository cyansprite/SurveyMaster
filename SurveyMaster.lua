local LAM2 = LibStub:GetLibrary("LibAddonMenu-2.0")

SM = {}
local SM = SM

SM.name = "SurveyMaster"
SM.isDirty = false
SM.currentSurveys = {}
SM.currentSurveyBank = {}
SM.currentSurveySubBank = {}
SM.currentSurveyCount = nil
SM.SavedVariables = nil

EVENT_MANAGER:RegisterForEvent(SM.name, EVENT_PLAYER_ACTIVATED , function(eventCode, initial) -- {{{
    SM.isDirty = true
end)

-- }}}

function SM:ParseBag(bag, surveyArr) -- {{{
    local count = 1

    for slotId = 0, GetBagSize(bag) do
        local id = GetItemId(bag, slotId)
        local thename = GetItemName(bag, slotId)

        if GetItemType(bag, slotId) == SPECIALIZED_ITEMTYPE_TROPHY_SURVEY_REPORT then
            local link = GetItemLink(bag, slotId, LINK_STYLE_DEFAULT)
            local icon, _, _, _, _, _, _, _ = GetItemInfo(bag, slotId)

            surveyArr[count] = {
                ["id"] = id,
                ["name"] = thename,
                ["link"] = link,
                ["icon"] = icon,
                ["slotId"] = slotId
            }

            count = count + 1
        end
    end

    SM.currentSurveyCount = count
    SM.isDirty = false
end -- }}}

function SM:Bank(from, from2, to, to2)
    local slots = {}
    local count = 1
    local amISecure = CallSecureProtected("RequestMoveItem")

    local SLOT_INDEX = 1
    local STACK_INDEX = 2
    local BAG_INDEX = 3

    function fillSlots(bag)
        for slotId = 0, GetBagSize(bag) do
            local type, special = GetItemType(bag, slotId)

            if special == SPECIALIZED_ITEMTYPE_TROPHY_SURVEY_REPORT then
                local _, stack = GetItemInfo(bag, slotId)
                slots[count] = { slotId, stack, bag }
                count = count + 1

                d ( GetItemName(bag, slotId) .. " :: " .. stack )
            end
        end
    end

    function requestMove(bag)
        if count == 1 then return end

        for slotId = 0, GetBagSize(bag) do
            if count == 1 then break end
            if GetItemId(bag, slotId) == 0 then
                count = count - 1
                CallSecureProtected("RequestMoveItem", slots[count][BAG_INDEX], slots[count][SLOT_INDEX], bag, slotId, slots[count][STACK_INDEX])
            end
        end
    end

    fillSlots(from)
    if from2 then fillSlots(from2) end

    requestMove(to)
    if to2 then requestMove(to2) end

    if count > 1 then
        local leftover = count - 1
        d ( "Needed x : more slots " .. leftover)
    end
end

function SM:Withdraw()
    SM:Bank(BAG_BANK, BAG_SUBSCRIBER_BANK, BAG_BACKPACK, nil)
end

function SM:Deposit()
    SM:Bank(BAG_BACKPACK, nil, BAG_BANK, BAG_SUBSCRIBER_BANK)
end

EVENT_MANAGER:RegisterForEvent(SM.name, EVENT_ADD_ON_LOADED, function (event, addonName) -- {{{
    if name ~= SM.name then return end
    SM.SavedVariables = ZO_SavedVars:New("Survey_Master_sv", 1, nil, SM.defaults)
    EVENT_MANAGER:UnregisterForEvent(SM.name, EVENT_ADD_ON_LOADED)
end)

