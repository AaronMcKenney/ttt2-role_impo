local L = LANG.GetLanguageTableReference("english")

-- GENERAL ROLE LANGUAGE STRINGS
L[IMPOSTOR.name] = "Impostor"
L["info_popup_" .. IMPOSTOR.name] = [[You are an Impostor! Impostors have access to a close range instant kill attack and vents that allow them to teleport. 

However, you do not have access to a shop and deal little to no damage normally.]]
L["body_found_" .. IMPOSTOR.abbr] = "They were an Impostor!"
L["search_role_" .. IMPOSTOR.abbr] = "This person was an Impostor"
L["target_" .. IMPOSTOR.name] = "Impostor"
L["ttt2_desc_" .. IMPOSTOR.name] = [[You are an Impostor! Impostors have access to a close range instant kill attack and vents that allow them to teleport. 

However, you do not have access to a shop and deal little to no damage normally.]]

-- OTHER ROLE LANGUAGE STRINGS
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