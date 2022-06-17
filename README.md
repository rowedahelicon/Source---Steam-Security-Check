# Source---Steam-Security-Check

This is a plugin that will kick players with an incomplete steam profile, this is almost always a hacker using a bot of some sort. An incomplete steam profile usually has no avatar and the profile displays the following text.

>This user has not yet set up their Steam Community profile.
If you know this person, encourage them to set up their profile and join in the gaming!

sec_steam_api "" - Set this to use your steam API key, which can aquired from here. https://steamcommunity.com/dev
sec_steam_check "0" - Set this to 1 to enable the use of the plugin, 0 to disable.

This uses Steamworks (https://forums.alliedmods.net/showthread.php?t=229556) and SM Json (https://github.com/clugg/sm-json). In order for a player to get kicked, a successful connection to the Steam API must take place, otherwise the plugin will not kick anyone. This should be safe against instances where steam is offline. 

Note: There may not be proper error handling in the handling of the Json data, if there are issues, please feel free to report or contact me, and I will sort them out. Thank you!
