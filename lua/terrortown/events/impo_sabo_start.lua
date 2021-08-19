if SERVER then
    AddCSLuaFile()

    resource.AddFile("materials/vgui/ttt/vskin/events/impo_sabo_start.vmt")
end

if CLIENT then
	EVENT.title = "title_event_impo_sabo_start"
	EVENT.icon = Material("vgui/ttt/vskin/events/impo_sabo_start.vmt")
	
	function EVENT:GetText()
		local desc_event_str = "desc_event_impo_sabo_start_"
		if self.event.mode == SABO_MODE.LIGHTS then
			desc_event_str = desc_event_str .. "lights"
		elseif self.event.mode == SABO_MODE.COMMS then
			desc_event_str = desc_event_str .. "comms"
		elseif self.event.mode == SABO_MODE.O2 then
			desc_event_str = desc_event_str .. "o2"
		elseif self.event.mode == SABO_MODE.REACT then
			desc_event_str = desc_event_str .. "react"
		end
		
		return {
			{
				string = desc_event_str,
				params = {
					name = self.event.impo_name
				},
				translateParams = true
			}
		}
    end
end

if SERVER then
	function EVENT:Trigger(impo, sabo_mode)
		self:AddAffectedPlayers(
			{impo:SteamID64()},
			{impo:GetName()}
		)
		
		return self:Add({
			serialname = self.event.title,
			impo_name = impo:GetName(),
			mode = sabo_mode
		})
	end
	
	function EVENT:Serialize()
		return self.event.serialname
	end
end