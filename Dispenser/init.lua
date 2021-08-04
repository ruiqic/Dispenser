local _, core = ...; -- Namespace

--------------------------------------
-- Custom Slash Command
--------------------------------------
core.commands = {
	["on"] = function()
		core.Config:On();
		core:Print("Dispenser turned on");
	end,
	
	["off"] = function()
		core.Config:Off();
		core:Print("Dispenser turned off");
	end,
	
	["status"] = function()
		local CurrentStatus = core.Config:GetStatus();
		core:Print(CurrentStatus);
	end,
	
	["help"] = function()
		core:Print("List of slash commands:")
		core:Print("|cff00cc66/disp status|r - shows dispenser status");
		core:Print("|cff00cc66/disp on|r - enables auto dispense");
		core:Print("|cff00cc66/disp off|r - disables auto dispense");
		core:Print("|cff00cc66/disp help|r - shows help info");
	end,
	
	["test"] = {
		["pickup"] = function()
			for bag = 0, 4 do
				local bagsize = GetContainerNumSlots(bag);
				for slot = 1, bagsize do
					_, count, _, _, _, _, _, _, _, id = GetContainerItemInfo(bag, slot);
					if (id == 8079 and count == 20) then
						PickupContainerItem(bag, slot);
						return;
					end
				end
			end
		end,
		
		["place"] = function()
			if (CursorHasItem) then
				ClickTradeButton(1)
				return;
			end
		end,
		
		["msg"] = function()
			SendChatMessage("show" , "CHANNEL" , nil , "4");
		end,
		
		["accept"] = AcceptTrade,
		
		["equip"] = function()
			EquipItemByName("Drakefire Amulet");
		end,
		
		["test"] = function()
			print("testing");
		end,
		
		["trigger"] = function ()
			triggerActionSlotEvent(31);
		end
	}
};

local function HandleSlashCommands(str)	
	if (#str == 0) then	
		-- User just entered "/dispenser" with no additional args.
		core.commands.help();
		return;		
	end	
	
	local args = {};
	for _, arg in ipairs({ string.split(' ', str) }) do
		if (#arg > 0) then
			table.insert(args, arg);
		end
	end
	
	local path = core.commands; -- required for updating found table.
	
	for id, arg in ipairs(args) do
		if (#arg > 0) then -- if string length is greater than 0.
			arg = arg:lower();			
			if (path[arg]) then
				if (type(path[arg]) == "function") then				
					-- all remaining args passed to our function!
					path[arg](select(id + 1, unpack(args))); 
					return;					
				elseif (type(path[arg]) == "table") then				
					path = path[arg]; -- another sub-table found!
				end
			else
				-- does not exist!
				core.commands.help();
				return;
			end
		end
	end
end

function core:Print(...)	
    local hex = select(4, self.Config:GetThemeColor());	
    local prefix = string.format("|cff%s%s|r", hex:upper(), "Dispenser:");		
    DEFAULT_CHAT_FRAME:AddMessage(string.join(" ", prefix, ...));
end

-- WARNING: self automatically becomes events frame!
function core:init(event, name)
	if (name ~= "Dispenser") then return end 

	-- allows using left and right buttons to move through chat 'edit' box
	for i = 1, NUM_CHAT_WINDOWS do
		_G["ChatFrame"..i.."EditBox"]:SetAltArrowKeyMode(false);
	end
	
	----------------------------------
	-- Register Slash Commands!
	----------------------------------

	SLASH_Dispenser1 = "/disp";
	SlashCmdList.Dispenser = HandleSlashCommands;

    core:Print("Dispenser addon loaded");
end

local events = CreateFrame("Frame");
events:RegisterEvent("ADDON_LOADED");
events:SetScript("OnEvent", core.init);