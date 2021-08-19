if SERVER then
    AddCSLuaFile()

    resource.AddFile("materials/vgui/ttt/vskin/events/impo_sabo_timeout.vmt")
end

if CLIENT then
	EVENT.title = "title_event_impo_sabo_timeout"
	EVENT.icon = Material("vgui/ttt/vskin/events/impo_sabo_timeout.vmt")
	
	function EVENT:GetText()
		local desc_event_str = "desc_event_impo_sabo_success_"
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
			mode = sabo_mode
		})
	end
	
	function EVENT:Serialize()
		return self.event.serialname
	end
end