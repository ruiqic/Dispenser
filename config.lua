--------------------------------------
-- Namespaces
--------------------------------------
local _, core = ...;
core.Config = {}; -- adds Config table to addon namespace

local Config = core.Config;

--------------------------------------
-- Defaults (usually a database!)
--------------------------------------
local defaults = {
	theme = {
		r = 0, 
		g = 0.8, -- 204/255
		b = 1,
		hex = "00ccff"
	},
	isOn = false
}

--------------------------------------
-- Config functions
--------------------------------------

function Config:GetThemeColor()	
	local c = defaults.theme;
	return c.r, c.g, c.b, c.hex;
end

function Config:On()
	defaults.isOn = true;
	return;
end

function Config:Off()
	defaults.isOn = false;
	return;
end

function Config:GetStatus()
	if (defaults.isOn) then
		return "Currently On";
	else
		return "Currently Off";
	end
end

local waitTable = {};
local waitFrame = nil;
function Disp_wait(delay, func, ...)
  if(type(delay)~="number" or type(func)~="function") then
    return false;
  end
  if(waitFrame == nil) then
    waitFrame = CreateFrame("Frame","WaitFrame", UIParent);
    waitFrame:SetScript("onUpdate",function (self,elapse)
      local count = #waitTable;
      local i = 1;
      while(i<=count) do
        local waitRecord = tremove(waitTable,i);
        local d = tremove(waitRecord,1);
        local f = tremove(waitRecord,1);
        local p = tremove(waitRecord,1);
        if(d>elapse) then
          tinsert(waitTable,i,{d-elapse,f,p});
          i = i + 1;
        else
          count = count - 1;
          f(unpack(p));
        end
      end
    end);
  end
  tinsert(waitTable,{delay,func,{...}});
  return true;
end

-------------------
-- Event section --
-------------------

local Disp = CreateFrame("Frame", "Dispenser")

local function OnEvent(self, event, ...)
	local dispatch = self[event]

	if dispatch then
		dispatch(self, ...)
	end
end

Disp:SetScript("OnEvent", OnEvent)
Disp:RegisterEvent("CHAT_MSG_WHISPER")
Disp:RegisterEvent("TRADE_ACCEPT_UPDATE")
Disp:RegisterEvent("TRADE_SHOW")
Disp:RegisterEvent("TRADE_CLOSED")

function Disp:CHAT_MSG_WHISPER(msg, charname, _)
	if (defaults.isOn) then
		local stacks, item, level = handleWhisper(msg, charname);
	end
end

function Disp:TRADE_ACCEPT_UPDATE(playerAccepted, targetAccepted)
    if (defaults.isOn) then
		if (playerAccepted == 0) then
			triggerActionSlotEvent(31);
		else
			triggerActionSlotEvent(32);
		end
	end
end

function Disp:TRADE_SHOW()
	local charname = UnitName("npc");
	if (defaults.isOn) then
		SendChatMessage("Thanks for trading. Please whisper me with the format: '<stacks> <food/water> <optional:level>' (ex: 6 water 55)", "WHISPER", nil, charname);
	end
end

function Disp:TRADE_CLOSED()
	if (defaults.isOn) then
		triggerActionSlotEvent(32);
	end
end

function handleWhisper(msg, charname)
	local args = {};
	for _, arg in ipairs({ string.split(' ', msg) }) do
		if (#arg > 0) then
			table.insert(args, arg);
		end
	end

	local fw = args[1];
	if (fw == "ty" or fw == "thx" or fw == "thank" or fw == "thanks" or fw == "tyvm") then
		SendChatMessage("you are welcome!", "WHISPER", nil, charname);
		return
	end
	
	if (findFoodWater(args)) then
		SendChatMessage("Hi, if you need both food and water, please trade twice with me. (ex: 3 water 55) Thanks!", "WHISPER", nil, charname);
		return;
	end
	
	if (findPort(args)) then
		SendChatMessage("Hi, if you need ports, I currently don't have them. Sorry. There might be other mages around who can help you.", "WHISPER", nil, charname);
		return;
	end
	
	local stacks = tonumber(args[1]);
	local item = args[2];
	local level = tonumber(args[3]);
	
	if ((not stacks) or stacks < 1) then
		respondWhisper(false, item, level, charname)
		return;
	elseif (stacks > 6) then
		SendChatMessage("Hi, if you need more than 6 stacks, please trade multiple times. Thanks!", "WHISPER", nil, charname);
		return;
	end
	if (item ~= "water" and item ~= "food") then
		respondWhisper(false, item, level, charname)
		return;
	end
	if (level) then
		if (level >= 55) then
			level = 55;
		elseif (level >= 45) then
			level = 45;
		end
	else
		level = 55;
	end
	respondWhisper(stacks, item, level, charname)
	return;
end

function findFoodWater(stringTable)
	local water = false;
	local food = false;
	local i
	local leng = #stringTable
	for i = 1, leng do
		if (stringTable[i] == "water") then
			water = true;
		elseif (stringTable[i] == "food") then
			food = true;
		elseif (stringTable[i] == "both") then
			food = true;
			water = true;
		end
	end
	return (food and water);
end

function findPort(stringTable)
	local i
	local leng = #stringTable
	for i = 1, leng do
		if (stringTable[i] == "port" or stringTable[i] == "ports") then
			return true;
		elseif (stringTable[i] == "portal" or stringTable[i] == "portals") then
			return true;
		end
	end
	return false;
end

function respondWhisper(stacks, item, level, charname)
	local charname = string.split('-', charname)
	local interactName = UnitName("npc")
	if (not interactName) then
		SendChatMessage("Hi, to get food or water please first open trade with me, then whisper me with what you need, thank you!", "WHISPER", nil, charname);
		return;
	elseif (interactName ~= charname) then
		SendChatMessage("sorry I'm currenly trading with someone else. If you want food/water, please wait a bit then come trade with me", "WHISPER", nil, charname);
		return;
	end
	
	if (not stacks) then
		SendChatMessage("please try again with the format: '<stacks> <food/water> <optional:level>' (ex: 6 water 55) This gets you 6 stacks of level 55 water. You can omit level for highest level.", "WHISPER", nil, charname);
		return;
	else
		local id;
		if (item == "water" and level == 55) then
			id = 8079;
		elseif (item == "water" and level == 45) then
			id = 8078;
		elseif (item == "food") then
			id = 8076;
		end
		if (level < 45) then
			SendChatMessage("sorry I currently only have level 45 water, level 55 water, and level 45 food", "WHISPER", nil, charname);
			return;
		end
		
		if (not tradeInput(stacks, id)) then
			SendChatMessage("sorry I have ran out of the desired item, gonna go restock. Try again in a bit", "WHISPER", nil, charname);
			CloseTrade();
		end
		return;
	end
end

function tradeInput(stacks, id)
	local tradeIndex;
	for tradeIndex = 1, 6 do
		if (tradeIndex <= stacks) then
			pickupItem(id);
			local success = placeIntoTrade(tradeIndex);
			if (not success) then
				return false;
			end
		else 
			ClearCursor();
			ClickTradeButton(tradeIndex);
			ClearCursor();
		end
	end
	triggerActionSlotEvent(31);
	return true;
end

function pickupItem(id)
	for bag = 0, 4 do
		local bagsize = GetContainerNumSlots(bag);
		local slot;
		for slot = 1, bagsize do
			_, count, locked, _, _, _, _, _, _, bagitemID = GetContainerItemInfo(bag, slot);
			if ((not locked) and bagitemID == id and count == 20) then
				PickupContainerItem(bag, slot);
				return;
			end
		end
	end
end

function placeIntoTrade(tradeIndex)
	if (CursorHasItem()) then
		ClickTradeButton(tradeIndex);
		ClearCursor();
		return true;
	else
		ClearCursor();
		return false;
	end
end

function triggerActionSlotEvent(slotnumber)
	PickupAction(slotnumber);
	if (CursorHasSpell()) then
		ClearCursor();
	else
		PickupSpell(818);
		PickupAction(slotnumber);
	end
end
	


