return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`CacklingTrapper` encountered an error loading the Darktide Mod Framework.")

		new_mod("CacklingTrapper", {
			mod_script       = "CacklingTrapper/scripts/mods/CacklingTrapper/CacklingTrapper",
			mod_data         = "CacklingTrapper/scripts/mods/CacklingTrapper/CacklingTrapper_data",
			mod_localization = "CacklingTrapper/scripts/mods/CacklingTrapper/CacklingTrapper_localization",
		})
	end,
	packages = {},
	version = "1.1.0-fixed",
	author = "Seph; compatibility fix",
}