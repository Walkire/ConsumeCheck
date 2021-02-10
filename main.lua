local EventFrame = CreateFrame("frame", "EventFrame")
EventFrame:RegisterEvent("CHAT_MSG_ADDON_LOGGED")
EventFrame:RegisterEvent("CHAT_MSG_ADDON")

-- commands
SLASH_CONSUMECHECK1 = '/cc';
SLASH_CONSUMECHECK2 = '/consumecheck';
SLASH_CONSUMECHECK3 = '/concheck';

-- events
ADDON_GET = 'CC_GET';
ADDON_POST = 'CC_POST';
C_ChatInfo.RegisterAddonMessagePrefix(ADDON_GET);
C_ChatInfo.RegisterAddonMessagePrefix(ADDON_POST);

TOTAL_CONSUMES = {}
DIALOG_SHOWN = false;

-- Takes a linked item and returns the amount current player has of that item
local function getItemCount(item)
        local c = 0;
        for bag=0,NUM_BAG_SLOTS do
                for slot=1,GetContainerNumSlots(bag) do
                        if (item == GetContainerItemLink(bag,slot) and select(2,GetContainerItemInfo(bag,slot))) then
                                c=c+(select(2,GetContainerItemInfo(bag,slot)))
                        end
                end
        end
        return c;
end

local function getConsumeData()
        local ret = "";
        for key, value in pairs(TOTAL_CONSUMES) do
                print(key, value)
                ret = ret .. "\n" .. (key .. " " .. value);
        end
        return ret or "Loading....";
end

-- Get current player and lead status
local function isLeader()
        local playerName = UnitName("player");
        return UnitIsGroupLeader(playerName);
end

-- Handle events
local function OnEvent(self, event, ...)
        local prefix, text, _, sender = ...;

        -- get request from raid leader
        if (prefix == ADDON_GET and text) then
                local amount = getItemCount(text);
                C_ChatInfo.SendAddonMessage(ADDON_POST, amount)
        end

        -- posted messages from players
        if (prefix == ADDON_POST and text and isLeader()) then
                TOTAL_CONSUMES[sender] = text
                print("POST " .. sender .. " " .. TOTAL_CONSUMES[sender]);
                if not(DIALOG_SHOWN) then 
                        StaticPopup_Show("CONSUMECHECK")
                        DIALOG_SHOWN = true;
                end
                StaticPopupDialogs["CONSUMECHECK"].text = getConsumeData();
        end
end

-- Handle register commands
local function handler(msg, editBox)
        -- Capture command and any leading message or whitespace
        local command, rest = msg:match("^(%S*)%s*(.-)$");

        if command == "find" and rest ~= "" and isLeader() then
                TOTAL_CONSUMES = {};
                C_ChatInfo.SendAddonMessage(ADDON_GET, rest)
        elseif isLeader() then
                print("[Consume Check] Syntax: /(cc|consumecheck|concheck) find [Link item]");
        else
                print("Need to be raid lead or party lead.");
        end
end

EventFrame:SetScript("OnEvent", OnEvent)
SlashCmdList['CONSUMECHECK'] = handler;

StaticPopupDialogs["CONSUMECHECK"] = {
        text = "Loading...",
        button1 = "Okay",
        OnAccept = function()
                StaticPopup_Hide("CONSUMECHECK")
                DIALOG_SHOWN = false;
        end,
        OnCancel = function ()
                DIALOG_SHOWN = false;
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
        setMoveable = true
}