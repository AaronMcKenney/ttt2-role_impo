if SERVER then
    AddCSLuaFile()

    resource.AddFile("materials/vgui/ttt/vskin/events/impo_sabo_react_end.vmt")
end

if CLIENT then
	EVENT.title = "title_event_impo_sabo_react_end"
	EVENT.icon = Material("vgui/ttt/vskin/events/impo_sabo_react_end.vmt")
	
	function EVENT:GetText()
		return {
			{
				string = "desc_event_impo_sabo_react_end",
				params = {
					name = self.event.impo_name
				},
				translateParams = true
			}
		}
    end
end

if SERVER then
	function EVENT:Trigger(impo)
		self:AddAffectedPlayers(
			{impo:SteamID64()},
			{impo:GetName()}
		)
		
		return self:Add({
			serialname = self.event.title,
			impo_name = impo:GetName(),
			impo_id = impo:SteamID64()
		})
	end
	
	function EVENT:CalculateScore()
		--Same score as if they killed one traitor on their team.
		self:SetPlayerScore(self.event.impo_id, {
			score = -16
		})
	end
	
	function EVENT:Serialize()
		return self.event.serialname
	end
end