if SERVER then
    AddCSLuaFile()

    resource.AddFile("materials/vgui/ttt/vskin/events/impo_insta_kill.vmt")
end

if CLIENT then
	EVENT.title = "title_event_impo_insta_kill"
	EVENT.icon = Material("vgui/ttt/vskin/events/impo_insta_kill.vmt")
	
	function EVENT:GetText()
		return {
			{
				string = "desc_event_impo_insta_kill",
				params = {
					name1 = self.event.impo_name,
					name2 = self.event.victim_name
				},
				translateParams = true
			}
		}
    end
end

if SERVER then
	function EVENT:Trigger(impo, victim)
		self:AddAffectedPlayers(
			{impo:SteamID64(), victim:SteamID64()},
			{impo:GetName(), victim:GetName()}
		)
		
		return self:Add({
			serialname = self.event.title,
			impo_name = impo:GetName(),
			impo_id = impo:SteamID64(),
			victim_name = victim:GetName()
		})
	end
	
	function EVENT:CalculateScore()
		self:SetPlayerScore(self.event.impo_id, {
			score = 1
		})
	end
	
	function EVENT:Serialize()
		return self.event.serialname
	end
end