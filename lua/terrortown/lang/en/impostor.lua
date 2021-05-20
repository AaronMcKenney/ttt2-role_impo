local L = LANG.GetLanguageTableReference("en")

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
L["INFORM_ONE_" .. IMPOSTOR.name] = "There is an impostor among us..."
L["INFORM_" .. IMPOSTOR.name] = "There are {n} impostors among us..."
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
L["VENT_TIME_LEFT_" .. IMPOSTOR.name] = "{t} seconds until you can no longer use the vents."
L["VENT_TIME_UP_" .. IMPOSTOR.name] = "You are out of time and can no longer use vents."
L["VENT_FOREIGNER_ENTER_" .. IMPOSTOR.name] = "A non-Traitor is in the vents!"
L["VENT_FOREIGNER_EXIT_" .. IMPOSTOR.name] = "A non-Traitor has left the vents!"
L["VENT_ANYONE_ENTER_" .. IMPOSTOR.name] = "Someone has entered a vent."
L["VENT_ANYONE_EXIT_" .. IMPOSTOR.name] = "Someone has exited a vent."

-- SABOTAGE LANGUAGE STRINGS
L["SABO_MNGR_" .. IMPOSTOR.name] = "STATION MANAGER"
L["SABO_MNGR_HELP_" .. IMPOSTOR.name] = "Add a new station spawn by pressing this key while looking at a qualifying player. Select an existing spawn by pressing this key while looking at it. Station spawns may be marked as unusable post-sabotage, to dissuade re-use."
L["SABO_MNGR_CREATE_PASS_" .. IMPOSTOR.name] = "A new Impostor sabotage station spawn has been created."
L["SABO_MNGR_BAD_PLY_" .. IMPOSTOR.name] = "Cannot create station spawn from target player."
L["SABO_MNGR_TOO_CLOSE_" .. IMPOSTOR.name] = "Target player is too close to an existing station spawn."
L["SABO_MNGR_UNSAFE_" .. IMPOSTOR.name] = "Failed to create station spawn from target player (unsafe position)."
L["SABO_CANNOT_REUSE_" .. IMPOSTOR.name] = "Cannot reuse selected station spawn. Use Station Manager to create/select another."
L["SABO_CANNOT_PLACE_" .. IMPOSTOR.name] = "Failed to create Impostor sabotage station!"
L["SABO_LIGHTS_" .. IMPOSTOR.name] = "SABOTAGE LIGHTS"
L["SABO_LIGHTS_INFO_FADE_" .. IMPOSTOR.name] = "An Impostor has sabotaged the lights! Victims will experience rolling blackouts until the sabotage ends!" 
L["SABO_LIGHTS_INFO_MAP_" .. IMPOSTOR.name] = "An Impostor has sabotaged the lights! Victims will experience darkness until the sabotage ends!"
L["SABO_LIGHTS_START_" .. IMPOSTOR.name] = "An Impostor has sabotaged the lights!"
L["SABO_LIGHTS_END_" .. IMPOSTOR.name] = "The lights are back on!"
L["SABO_COMMS_" .. IMPOSTOR.name] = "SABOTAGE COMMS"
L["SABO_COMMS_INFO_MUTE_AND_DEAF_" .. IMPOSTOR.name] = "An Impostor has sabotaged the comms! Victims are muted and deafened until the sabotage ends!"
L["SABO_COMMS_INFO_MUTE_" .. IMPOSTOR.name] = "An Impostor has sabotaged the comms! Victims are muted until the sabotage ends!"
L["SABO_COMMS_START_" .. IMPOSTOR.name] = "An Impostor has sabotaged the comms!"
L["SABO_COMMS_END_" .. IMPOSTOR.name] = "The comms are back on!"
L["SABO_O2_" .. IMPOSTOR.name] = "SABOTAGE O2"
L["SABO_O2_INFO_" .. IMPOSTOR.name] = "An Impostor has sabotaged the air! Victims may suffer constant damage until the sabotage ends!"
L["SABO_O2_START_" .. IMPOSTOR.name] = "An Impostor has sabotaged the air!"
L["SABO_O2_END_" .. IMPOSTOR.name] = "O2 levels are back to normal!"
L["SABO_REACT_" .. IMPOSTOR.name] = "SABOTAGE REACTOR"
L["SABO_REACT_INFO_LOSE_" .. IMPOSTOR.name] = "An Impostor has sabotaged the reactor! End the sabotage or EVERYONE WILL LOSE!"
L["SABO_REACT_INFO_TEAM_WIN_" .. IMPOSTOR.name] = "An Impostor has sabotaged the reactor! End the sabotage or THE IMPOSTOR'S TEAM WILL WIN!"
L["SABO_REACT_START_" .. IMPOSTOR.name] = "An Impostor has sabotaged the reactor!"
L["SABO_REACT_TIME_LEFT_" .. IMPOSTOR.name] = "{t} seconds until reactor meltdown!"
L["SABO_REACT_TEN_" .. IMPOSTOR.name] = "TEN"
L["SABO_REACT_NINE_" .. IMPOSTOR.name] = "NINE"
L["SABO_REACT_EIGHT_" .. IMPOSTOR.name] = "EIGHT"
L["SABO_REACT_SEVEN_" .. IMPOSTOR.name] = "SEVEN"
L["SABO_REACT_SIX_" .. IMPOSTOR.name] = "SIX"
L["SABO_REACT_FIVE_" .. IMPOSTOR.name] = "FIVE"
L["SABO_REACT_FOUR_" .. IMPOSTOR.name] = "FOUR"
L["SABO_REACT_THREE_" .. IMPOSTOR.name] = "THREE"
L["SABO_REACT_TWO_" .. IMPOSTOR.name] = "TWO"
L["SABO_REACT_ONE_" .. IMPOSTOR.name] = "ONE"
L["SABO_REACT_PASS_" .. IMPOSTOR.name] = "The reactor has stabilized!"
L["SABO_REACT_END_" .. IMPOSTOR.name] = "Have a nice day!"
L["SABO_REACT_STRANGE_GAME_" .. IMPOSTOR.name] = "A STRANGE GAME"
L["SABO_STAT_INFO_" .. IMPOSTOR.name] = "The sabotage ends when {n} players are in range of the Sabotage Station! It's outlined red!"

-- EVERYONE LOSES EVERYONE LOSES EVERYONE LOSES
L["win_losers"] = "EVERYONE LOSES"
L["hilite_win_losers"] = "EVERYONE LOSES"
L["ev_win_losers"] = "EVERYONE LOSES"