--  saved variables
ThefRaidMarkerDB = ThefRaidMarkerDB or {}

--  check if SpikesEasyMarks is available
local isSpikesEasyMarksLoaded = IsAddOnLoaded("SpikesEasyMarks")
local ThefRaidMarker_AddonNameColor = "|c00DA55BAThefRaidMarker|r"

--  onload function
function ThefRaidMarker_OnLoad(self)
    self:SetMovable(true)
    self:EnableMouse(true)
    self:RegisterForDrag("RightButton")

    --  hooks into target unit tooltips and shows the currently assigned mark by SpikesEasyMarks
    GameTooltip:HookScript("OnTooltipSetUnit", function(self)
        local unit = "mouseover"
        ThefRaidMarker_ShowCurrentMark(self, unit)
    end)

    self:RegisterEvent("ADDON_LOADED")
end

function ThefRaidMarker_OnEvent(self, event)
    if event == "ADDON_LOADED" then
        --  reload position
        if ThefRaidMarkerDB.position then
            self:ClearAllPoints()
            self:SetPoint(
                ThefRaidMarkerDB.position.point,
                ThefRaidMarkerDB.position.relativeTo,
                ThefRaidMarkerDB.position.relativePoint,
                ThefRaidMarkerDB.position.x,
                ThefRaidMarkerDB.position.y
            )
        end

        if ThefRaidMarkerDB.visible == false then
            self:Hide()
        else
            self:Show()
        end

        --  slash command
        SLASH_THEFRAIDMARKER1 = "/trm";
        SlashCmdList["THEFRAIDMARKER"] = function (msg)
            ThefRaidMarker_SlashCommandHandler(msg)
        end    

        DEFAULT_CHAT_FRAME:AddMessage(ThefRaidMarker_AddonNameColor .. " loaded.")
        
        self:UnregisterEvent("ADDON_LOADED")
    end
end

--  function to store position
function ThefRaidMarker_SavePosition(frame)
    local point, relativeTo, relativePoint, x, y = frame:GetPoint()
    if point and x and y then
        ThefRaidMarkerDB.position = {
            point = point,
            relativeTo = "UIParent",
            relativePoint = relativePoint,
            x = x,
            y = y
        }
    end
end

--  function to set the mark, and optionally invoke SpikesEasyMarks
function ThefRaidMarker_SetMarker(index, altModifier)
    local setSEM = altModifier and isSpikesEasyMarksLoaded

    if UnitExists("target") then
        local currentMark = GetRaidTargetIndex("target")

        if (currentMark ~= index) then
            SetRaidTarget("target", index)
            if setSEM then
                local guid = UnitGUID("target")
                if (guid and index > 0 and index < 9) then
                    SEM_AddNewRT(guid, index)
                end
            end
        else
            ThefRaidMarker_RemoveMarker(altModifier)
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage(ThefRaidMarker_AddonNameColor .. ": No target selected.")
    end
end

function ThefRaidMarker_RemoveMarker(altModifier)
    local setSEM = altModifier and isSpikesEasyMarksLoaded
    if UnitExists("target") then
        if setSEM then
            SEM_RemoveRT(UnitGUID("target"))
        end
        SetRaidTarget("target", 0)
    end
end

--  adds the current mark assigned by SpikesEasyMarks as a hint to the tooltip
function ThefRaidMarker_ShowCurrentMark(tooltip, unit)
    if UnitExists(unit) and isSpikesEasyMarksLoaded then
        local guid = UnitGUID(unit)
        local mark = SEM_GetMarkForTarget(guid)
        if (mark and mark > 0) then
            tooltip:AddDoubleLine("Automark:", "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_"..mark..":24|t")
        end
    end
end

function ThefRaidMarker_SlashCommandHandler(msg)
    local command = msg and msg:lower():match("^%s*(%S+)") or ""
    local frame = _G["ThefRaidMarkerFrame"]

    if command == "reset" then
        if frame then
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
            ThefRaidMarkerDB.position = nil
            DEFAULT_CHAT_FRAME:AddMessage(ThefRaidMarker_AddonNameColor .. ": Position reset.")
        else
            DEFAULT_CHAT_FRAME:AddMessage(ThefRaidMarker_AddonNameColor .. ": Error - toolbar not found.")
        end
    elseif command == "toggle" then
        if frame then
            if frame:IsShown() then
                frame:Hide()
                ThefRaidMarkerDB.visible = false
                DEFAULT_CHAT_FRAME:AddMessage(ThefRaidMarker_AddonNameColor .. ": Toolbar hidden. ")
            else
                frame:Show()
                ThefRaidMarkerDB.visible = true
                DEFAULT_CHAT_FRAME:AddMessage(ThefRaidMarker_AddonNameColor .. ": Toolbar visible.")
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage(ThefRaidMarker_AddonNameColor .. ": Error - toolbar not found.")
        end
    elseif command == "help" or command == "" then
        local isVisible = "|c0000ff00visible|r"
        if ThefRaidMarkerDB.visible == false then
            isVisible = "|c00ff0000hidden|r"
        end

        local baseCommand = "|c00DA55BA/trm|r"

        DEFAULT_CHAT_FRAME:AddMessage(ThefRaidMarker_AddonNameColor .. " commands")
        DEFAULT_CHAT_FRAME:AddMessage(baseCommand .. " |c00FFDD00reset|r - Reset the position of the toolbar.")
        DEFAULT_CHAT_FRAME:AddMessage(baseCommand .. " |c00FFDD00toggle|r - Show or hide the toolbar. (Current: " .. isVisible .. ")")
        DEFAULT_CHAT_FRAME:AddMessage(baseCommand .. " |c00FFDD00help|r - Shows this help text.")
    else
        DEFAULT_CHAT_FRAME:AddMessage(ThefRaidMarker_AddonNameColor .. ": Unknown command. Use /trm help for an overview.")
    end
end