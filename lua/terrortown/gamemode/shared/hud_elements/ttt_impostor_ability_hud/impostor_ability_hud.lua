local base = "pure_skin_element"

DEFINE_BASECLASS(base)

HUDELEMENT.Base = base

--Most code here is taken from Beacon HUD logic.
if CLIENT then
	local pad = 7
	local iconSize = 64
	--Used for Insta Kill and Venting
	local icon_kill_waiting = Material("vgui/ttt/dynamic/roles/icon_impo")
	local icon_kill_ready = Material("vgui/ttt/dynamic/roles/icon_traitor")
	local icon_in_vent = Material("vgui/ttt/icon_vent")
	--Used for Sabotage Lights
	local icon_lit_bulb = Material("vgui/ttt/icon_lit_bulb")
	local icon_unlit_bulb = Material("vgui/ttt/icon_unlit_bulb")
	
	local const_defaults = {
		basepos = {x = 0, y = 0},
		size = {w = 365, h = 32},
		minsize = {w = 225, h = 32}
	}

	function HUDELEMENT:PreInitialize()
		BaseClass.PreInitialize(self)

		local hud = huds.GetStored("pure_skin")
		if not hud then return end

		hud:ForceElement(self.id)
	end

	function HUDELEMENT:Initialize()
		self.scale = 1.0
		self.basecolor = self:GetHUDBasecolor()
		self.pad = pad
		self.iconSize = iconSize

		BaseClass.Initialize(self)
	end

	-- parameter overwrites
	function HUDELEMENT:IsResizable()
		return true, false
	end
	-- parameter overwrites end

	function HUDELEMENT:GetDefaults()
		const_defaults["basepos"] = {
			x = 10 * self.scale,
			y = ScrH() - self.size.h - 146 * self.scale - self.pad - 10 * self.scale
		}

		return const_defaults
	end

	function HUDELEMENT:PerformLayout()
		self.scale = self:GetHUDScale()
		self.basecolor = self:GetHUDBasecolor()
		self.iconSize = iconSize * self.scale
		self.pad = pad * self.scale

		BaseClass.PerformLayout(self)
	end

	function HUDELEMENT:ShouldDraw()
		local client = LocalPlayer()
		
		return HUDEditor.IsEditing or (client:Alive() and client:GetSubRole() == ROLE_IMPOSTOR)
	end
	
	function HUDELEMENT:DrawComponent(text, bg_color, icon_color, icon, first_bar)
		local pos = self:GetPos()
		local size = self:GetSize()
		local x, y = pos.x, pos.y
		local w, h = size.w, size.h
		if not first_bar then
			y = y - (self.size.h + self.pad + 10 * self.scale)
		end
		
		self:DrawBg(x, y, w, h, bg_color)
		draw.AdvancedText(text, "PureSkinBar", x + self.iconSize + self.pad, y + h * 0.5, util.GetDefaultColor(bg_color), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, true, self.scale)
		self:DrawLines(x, y, w, h, self.basecolor.a)
		
		local nSize = self.iconSize - 16
		
		draw.FilteredShadowedTexture(x, y - 2 - (nSize - h), nSize, nSize, icon, 255, icon_color, self.scale)
	end
	
	local function TimeLeftToString(time_left)
		return " (" .. math.ceil(math.abs(time_left)) .. ")"
	end
	
	function HUDELEMENT:DrawInstaKillComponent()
		local client = LocalPlayer()
		local icon_color = COLOR_BLACK
		local kill_str = LANG.GetTranslation("KILL_" .. IMPOSTOR.name)
		local bg_color = COLOR_LGRAY
		if client.impo_can_insta_kill then
			bg_color = IMPOSTOR.color
		end
		local icon = nil
		
		--Venting GUI has priority over insta-kill
		if IsValid(client.impo_in_vent) then
			icon = icon_in_vent
			bg_color = COLOR_ORANGE
		elseif client.impo_can_insta_kill then
			icon = icon_kill_ready
		else
			icon = icon_kill_waiting
		end
		
		--Display time left if possible.
		if not client.impo_can_insta_kill and timer.Exists("ImpostorKillTimer_Client_" .. client:SteamID64()) then
			local time_left = timer.TimeLeft("ImpostorKillTimer_Client_" .. client:SteamID64())
			kill_str = kill_str .. TimeLeftToString(time_left)
		elseif client.impo_can_insta_kill then
			local kill_key = string.upper(input.GetKeyName(bind.Find("ImpostorSendInstantKillRequest")))
			kill_str = kill_str .. " (" .. LANG.GetTranslation("PRESS_" .. IMPOSTOR.name) .. kill_key .. ")"
		end
		
		self:DrawComponent(kill_str, bg_color, icon_color, icon, true)
	end
	
	function HUDELEMENT:DrawSabotageLightsComponent()
		local icon_color = COLOR_WHITE
		local sabo_str = LANG.GetTranslation("SABO_LIGHTS_" .. IMPOSTOR.name)
		local bg_color = Color(255, 255, 153, 255) --Beacon's color
		local icon = icon_lit_bulb
		
		if timer.Exists("ImpostorSaboTimer_Client") then
			--Sabotage is on cooldown
			local time_left = timer.TimeLeft("ImpostorSaboTimer_Client")
			sabo_str = sabo_str .. TimeLeftToString(time_left)
		elseif timer.Exists("ImpostorSaboLightsTimer_Client") then
			--Sabotage is in progress.
			local fade_time = GetConVar("ttt2_impostor_sabo_lights_fade"):GetFloat()
			local sabo_lights_len = GetConVar("ttt2_impostor_sabo_lights_length"):GetFloat()
			local time_left = timer.TimeLeft("ImpostorSaboLightsTimer_Client")
			
			if time_left > sabo_lights_len + fade_time then
				--Screen is transitioning to complete darkness
				local fract = (time_left - (sabo_lights_len + fade_time)) / fade_time
				local h, s, v = ColorToHSV(bg_color)
				bg_color = HSVToColor(h, s, v * fract)
				
				icon_color = COLOR_LGRAY
				icon = icon_unlit_bulb
			elseif time_left <= fade_time then
				--Screen is transitioning from complete darkness
				local fract = 1 - (time_left / fade_time)
				local h, s, v = ColorToHSV(bg_color)
				bg_color = HSVToColor(h, s, v * fract)
			else
				--Screen is completely dark.
				bg_color = COLOR_BLACK
				icon_color = COLOR_LGRAY
				icon = icon_unlit_bulb
				
				--Give seconds left until darkness lifts
				sabo_str = sabo_str .. TimeLeftToString(time_left - fade_time)
			end
		else
			--Sabotage is ready to go
			local sabo_key = string.upper(input.GetKeyName(bind.Find("ImpostorSendSabotageRequest")))
			sabo_str = sabo_str .. " (" .. LANG.GetTranslation("PRESS_" .. IMPOSTOR.name) .. sabo_key .. ")"
		end
		
		self:DrawComponent(sabo_str, bg_color, icon_color, icon, false)
	end
	
	function HUDELEMENT:DrawSabotageCommsComponent()
		local icon_color = COLOR_BLACK
		local sabo_str = LANG.GetTranslation("SABO_COMMS_" .. IMPOSTOR.name)
		local bg_color = COLOR_LGRAY
		local icon = icon_lit_bulb
		
		if timer.Exists("ImpostorSaboTimer_Client") then
			--Sabotage is on cooldown
			local time_left = timer.TimeLeft("ImpostorSaboTimer_Client")
			sabo_str = sabo_str .. TimeLeftToString(time_left)
		elseif timer.Exists("ImpostorSaboCommsTimer_Client") then
			--Sabotage is in progress.
			local time_left = timer.TimeLeft("ImpostorSaboCommsTimer_Client")
			
			--Screen is completely dark.
			bg_color = IMPOSTOR.color
			icon = icon_unlit_bulb
			
			--Give seconds left until darkness lifts
			sabo_str = sabo_str .. TimeLeftToString(time_left)
		else
			--Sabotage is ready to go
			local sabo_key = string.upper(input.GetKeyName(bind.Find("ImpostorSendSabotageRequest")))
			sabo_str = sabo_str .. " (" .. LANG.GetTranslation("PRESS_" .. IMPOSTOR.name) .. sabo_key .. ")"
		end
		
		self:DrawComponent(sabo_str, bg_color, icon_color, icon, false)
	end
	
	function HUDELEMENT:Draw()
		local client = LocalPlayer()
		
		self:DrawInstaKillComponent()
		if (client.impo_sabo_mode == SABO_MODE.LIGHTS and not timer.Exists("ImpostorSaboCommsTimer_Client")) or timer.Exists("ImpostorSaboLightsTimer_Client") then
			self:DrawSabotageLightsComponent()
		elseif client.impo_sabo_mode == SABO_MODE.COMMS or timer.Exists("ImpostorSaboCommsTimer_Client") then
			self:DrawSabotageCommsComponent()
		end
	end
end