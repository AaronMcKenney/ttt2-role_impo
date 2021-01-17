local L = LANG.GetLanguageTableReference("english")

-- GENERAL ROLE LANGUAGE STRINGS
L[IMPOSTOR.name] = "Impostor"
L["info_popup_" .. IMPOSTOR.name] = [[You are an Impostor! Impostors are traitors have access to a close range instant kill ability, sabotage ability, and vents that allow them to teleport. 

However, you do not have access to a shop and deal little to no damage normally.]]
L["body_found_" .. IMPOSTOR.abbr] = "They were an Impostor!"
L["search_role_" .. IMPOSTOR.abbr] = "This person was an Impostor"
L["target_" .. IMPOSTOR.name] = "Impostor"
L["ttt2_desc_" .. IMPOSTOR.name] = [[You are an Impostor! Impostors are traitors have access to a close range instant kill ability, sabotage ability, and vents that allow them to teleport. 

However, you do not have access to a shop and deal little to no damage normally.]]

-- OTHER ROLE LANGUAGE STRINGS
L["INFORM_" .. IMPOSTOR.name] = "There are {n} impostor(s) among us..."
L["KILL_" .. IMPOSTOR.name] = "KILL"
L["PRESS_" .. IMPOSTOR.name] = "PRESS "
L["TO_KILL_" .. IMPOSTOR.name] = " TO KILL"

-- VENT LANGUAGE STRINGS
L["VENT_NAME_" .. IMPOSTOR.name] = "Vent"
L["VENT_DESC_" .. IMPOSTOR.name] = [[A vent that can be manually placed on most surfaces.
Impostors treat these vents as a teleportation network.

NOTE: By default, vents are invisible to non-traitors until they are first entered or exited.]]
L["VENT_PRIMARY_DESC_" .. IMPOSTOR.name] = "Primary attack to deploy."
L["VENT_CANNOT_PLACE_" .. IMPOSTOR.name] = "Unable to place vent."
L["VENT_MAX_HIT_" .. IMPOSTOR.name] = "Maximum number of vents have been placed."
L["VENT_FULL_" .. IMPOSTOR.name] = "You can't hold any more vents."
L["VENT_CANNOT_TAKE_" .. IMPOSTOR.name] = "Unable to take vent."
L["VENT_TRAPPER_TIME_LEFT_" .. IMPOSTOR.name] = "{t} seconds until you can no longer use the vents."
L["VENT_TRAPPER_TIME_UP_" .. IMPOSTOR.name] = "You are out of time and can no longer use vents."
L["VENT_TRAPPER_ENTER_" .. IMPOSTOR.name] = "A trapper is in the vents!"
L["VENT_TRAPPER_EXIT_" .. IMPOSTOR.name] = "A trapper has left the vents!"
L["VENT_ANYONE_ENTER_" .. IMPOSTOR.name] = "Someone has entered a vent."
L["VENT_ANYONE_EXIT_" .. IMPOSTOR.name] = "Someone has exited a vent."

-- SABOTAGE LANGUAGE STRINGS
L["SABO_LIGHTS_" .. IMPOSTOR.name] = "SABOTAGE LIGHTS"
L["SABO_LIGHTS_START_" .. IMPOSTOR.name] = "An Impostor has sabotaged the lights!"
L["SABO_LIGHTS_END_" .. IMPOSTOR.name] = "The lights are back on!"
