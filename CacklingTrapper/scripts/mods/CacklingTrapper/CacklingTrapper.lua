--[[
Cackling Trapper - compatibility fix
Original idea/author: Seph (Steam: Concoction of Constitution)

The 2024 version replaced only the netgunner footstep sound. The current game
uses a separate approach behavior with its own low-frequency VO trigger, so the
footstep replacement is no longer a reliable warning. This version keeps the
footstep laugh and also directly plays the native laugh while the Trapper is
approaching within audible range of the local player.
--]]

local mod = get_mod("CacklingTrapper")

local LAUGH_EVENT = "wwise/events/minions/play_traitor_guard_netgunner_laugh_vce"
local SOUNDS_PATH = "scripts/settings/breed/breeds/renegade/renegade_netgunner_sounds"
local APPROACH_PATH = "scripts/extension_systems/behavior/nodes/actions/bt_renegade_netgunner_approach_action"

local LAUGH_INTERVAL = 1.35
local MAX_AUDIBLE_DISTANCE = 45
local MAX_AUDIBLE_DISTANCE_SQ = MAX_AUDIBLE_DISTANCE * MAX_AUDIBLE_DISTANCE
local NEXT_LAUGH_KEY = "cackling_trapper_next_laugh_t"

local MOVEMENT_SOUND_ALIASES = {
	"footstep",
	"footstep_land",
	"run_foley",
	"run_foley_special",
}

local function replace_movement_sounds(sound_data)
	if type(sound_data) ~= "table" or type(sound_data.events) ~= "table" then
		return
	end

	sound_data.use_proximity_culling = sound_data.use_proximity_culling or {}

	for i = 1, #MOVEMENT_SOUND_ALIASES do
		local sound_alias = MOVEMENT_SOUND_ALIASES[i]

		sound_data.events[sound_alias] = LAUGH_EVENT
		sound_data.use_proximity_culling[sound_alias] = false
	end
end

mod:hook_require(SOUNDS_PATH, replace_movement_sounds)

local function local_player_unit()
	local players = Managers and Managers.player
	local player = players and players:local_player_safe(1)

	return player and player.player_unit
end

local function is_near_local_player(unit)
	if not Unit.alive(unit) or not POSITION_LOOKUP then
		return false
	end

	local player_unit = local_player_unit()

	if not player_unit or not Unit.alive(player_unit) then
		return false
	end

	local unit_position = POSITION_LOOKUP[unit]
	local player_position = POSITION_LOOKUP[player_unit]

	if not unit_position or not player_position then
		return false
	end

	return Vector3.distance_squared(unit_position, player_position) <= MAX_AUDIBLE_DISTANCE_SQ
end

local function play_laugh(unit)
	if not Unit.alive(unit) or not WwiseWorld or not Managers.world then
		return false
	end

	local dialogue_extension = ScriptUnit.has_extension(unit, "dialogue_system")

	if not dialogue_extension then
		return false
	end

	local world = Unit.world(unit)
	local wwise_world = Managers.world:wwise_world(world)

	if not wwise_world then
		return false
	end

	local voice_node = dialogue_extension:get_voice_node()
	local source_id = WwiseWorld.make_auto_source(wwise_world, unit, voice_node)
	local switch_group, switch_value, voice_fx_preset = dialogue_extension:voice_data()

	if switch_group and switch_value then
		WwiseWorld.set_switch(wwise_world, switch_group, switch_value, source_id)
	end

	if voice_fx_preset then
		WwiseWorld.set_source_parameter(wwise_world, source_id, "voice_fx_preset", voice_fx_preset)
	end

	WwiseWorld.trigger_resource_event(wwise_world, LAUGH_EVENT, true, source_id)

	return true
end

mod:hook_require(APPROACH_PATH, function(action_class)
	mod:hook_safe(action_class, "enter", function(self, unit, breed, blackboard, scratchpad, action_data, t)
		scratchpad[NEXT_LAUGH_KEY] = (t or 0) + LAUGH_INTERVAL

		if is_near_local_player(unit) then
			play_laugh(unit)
		end
	end)

	mod:hook_safe(action_class, "run", function(self, unit, breed, blackboard, scratchpad, action_data, dt, t)
		t = t or 0

		if t < (scratchpad[NEXT_LAUGH_KEY] or 0) then
			return
		end

		if not is_near_local_player(unit) then
			return
		end

		if play_laugh(unit) then
			scratchpad[NEXT_LAUGH_KEY] = t + LAUGH_INTERVAL
		end
	end)

end)

