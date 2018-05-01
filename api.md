# Mod Loader API

## Table of Contents

* [init.lua](#initlua)

* [API](#api)
	* [modApi:deltaTime](#modapideltatime)
	* [modApi:elapsedTime](#modapielapsedtime)
	* [modApi:scheduleHook](#modapischedulehook)
	* [modApi:runLater](#modapirunlater)
	* [modApi:splitString](#modapisplitstring)
	* [modApi:trimString](#modapitrimstring)
	* [modApi:stringStartsWith](#modapistringstartswith)
	* [modApi:stringEndsWith](#modapistringendswith)
	* [modApi:isVersion](#modapiisversion)
	* [modApi:addGenerationOption](#modapiaddgenerationoption)
	* [modApi:appendAsset](#modapiappendasset)
	* [modApi:addSquad](#modapiaddsquad)
	* [modApi:overwriteText](#modapioverwritetext)
	* [modApi:addWeapon_Texts](#modapiaddweapon_texts)
	* [modApi:addPopEvent](#modapiaddpopevent)
	* [modApi:setPopEventOdds](#modapisetpopeventodds)
	* [modApi:addOnPopEvent](#modapiaddonpopevent)
	* [modApi:addMap](#modapiaddmap)

* [Hooks](#hooks)
	* [preMissionAvailableHook](#premissionavailablehook)
	* [postMissionAvailableHook](#postmissionavailablehook)
	* [preEnvironmentHook](#preenvironmenthook)
	* [postEnvironmentHook](#postenvironmenthook)
	* [nextTurnHook](#nextturnhook)
	* [missionUpdateHook](#missionupdatehook)
	* [missionStartHook](#missionstarthook)
	* [missionEndHook](#missionendhook)
	* [missionNextPhaseCreatedHook](#missionnextphasecreatedhook)
	* [voiceEventHook](#voiceeventhook)
	* [preStartGameHook](#prestartgamehook)
	* [postStartGameHook](#poststartgamehook)
	* [preLoadGameHook](#preloadgamehook)
	* [postLoadGameHook](#postloadgamehook)
	* [saveGameHook](#savegamehook)


## init.lua

Each mod is defined by its init.lua file. This file must exist in `scripts/init.lua` path in your mod's root directory, or mod loader will be unable to load it.
The file, when executed, must return a table with following fields:

| Field | Description |
| --- | --- |
| id | Mod id. A string that is supposed to uniquely identify your mod, and shouldn't change as you release updates to it. |
| name | Name of the mod displayed to user. |
| version | A freeform string with mod's version. |
| requirements | A table with mod ids of other mods. This will cause those mods to load before yours.  |
| init | The init function. |
| load | The load function. |


Init function is called by mod loader first, followed by the call to load function.

Arguments for init function are:

| Argument | Description |
| --- | --- |
| self | The mod object. |


Arguments for load function are:

| Argument | Description |
| --- | --- |
| self | The mod object. |
| options | Mod options. Presumably a table. Possiblty not fully implemented yet. |
| version | Mod version *(why is it here?)*. |

The `self` object, passed as first argument to both functions, is the table you previously returned from `init.lua` with following useful fields added:

| Field | Description |
| --- | --- |
| resourcePath | Path to mod's root directory. |
| scriptPath | Path to mod's root script directory - which should be equivalent to `self.resourcePath.."scripts/"`. |
| path | Path to mod's init.lua file. |
| dir | name of the mod's directory inside game's `mods` directory. |

Example:
```lua
local function init(self)
    LOG("Mod is being initialized!")
end

local function load(self,options,version)
    LOG("Mod is being loaded!")
end

return {
	id = "SampleMod",
	name = "Sample mod",
	version = "1.0.0",
	requirements = {},
	init = init,
	load = load,
}
```


## API

### `modApi:deltaTime`

Returns time between frames in milliseconds. For 60 FPS, this is 16ms. For 30 FPS, this is 33ms.


### `modApi:elapsedTime`

Returns the amount of time that has passed since the game has been launched, in milliseconds.


### `modApi:scheduleHook`

| Argument name | Type | Description |
|---------------|------|-------------|
| `msTime` | number | Time in which the function is to be invoked, in milliseconds. Measured from the moment this function is called |
| `fn` | function | Argumentless function which will be invoked when the amount of time specified in the first argument has elapsed. |

Schedules a function to be invoked at a later time. This can be used to perform delayed operations, mostly related to UI or mod management, or as a way to work around some hooks' limitations.

Keep in mind that these hooks are not retained when the player exits the game, so hooks scheduled to happen in a long time (like a minute) may end up never being executed if the player quits the game in the meantime.

Example:
```lua
LOG("This message is printed right away!")

modApi:scheduleHook(1000, function()
	LOG("This message is printed a second later!")
end)
```


### `modApi:runLater`

| Argument name | Type | Description |
|---------------|------|-------------|
| `fn` | function | Argumentless function which will be invoked on game's next update step. |

Executes the function on the game's next update step. Only works during missions.

Calling this during game loop (either in a function called from `missionUpdate`, `missionUpdateHook`, or as a result of previous `runLater`) will correctly schedule the function to be invoked during the next update step (not the current one).

Example:
```lua
local pawn = Board:GetPawn(Point(0, 0))

local d = SpaceDamage(Point(0, 0))
d.iFire = EFFECT_CREATE
Board:DamageSpace(d)

LOG(pawn:IsFire()) -- prints false, the tile's Fire status was
                   -- not applied to the pawn yet (this happens
                   -- during the game's update step)

modApi:runLater(function()
	LOG(pawn:IsFire()) -- prints true, the game already went
	                   -- through its update step and applied
	                   -- the Fire status to the pawn
end)
```


### `modApi:splitString`

| Argument name | Type | Description |
|---------------|------|-------------|
| `input` | string | The string to be split |
| `separator` | string | The string to split by. Defaults to whitespace if omitted |

Splits the input string around the provided separator string, and returns a table holding the split string.


### `modApi:trimString`

| Argument name | Type | Description |
|---------------|------|-------------|
| `input` | string | The string to be trimmed |

Trims leading and trailing whitespace from the string.

Example:
```lua
LOG(modApi:trimString("   some text !   ")) -- prints 'some text !'
```


### `modApi:stringStartsWith`

| Argument name | Type | Description |
|---------------|------|-------------|
| `input` | string | The string to test |
| `prefix` | string | The prefix string that the `input` string should be starting with |

Returns true if the `input` string starts with the `prefix` string.

Example:
```lua
local string = "PunchMech"
if modApi:stringStartsWith(string, "Punch") then
	LOG("It does")
end
```


### `modApi:stringEndsWith`

| Argument name | Type | Description |
|---------------|------|-------------|
| `input` | string | The string to test |
| `suffix` | string | The suffix string that the `input` string should be ending with |

Returns true if the `input` string ends with the `suffix` string.

Example:
```lua
local string = "PunchMech"
if modApi:stringEndsWith(string, "Mech") then
	LOG("It does")
end
```


### `modApi:isVersion`

| Argument name | Type | Description |
|---------------|------|-------------|
| `version` | string | Version to test |
| `comparedTo` | string | Version to compare the first argument to. Defaults to mod loader's version if omitted. |

Returns true if `version` argument is less than or equal to `comparedTo`. False otherwise.

Example:
```lua
if modApi:isVersion("2.1.1") then
	LOG("Mod loader is version 2.1.1 or higher.")
end

-- ...

someModVersion = "1.2"
if modApi:isVersion("1.1", someModVersion) then
	LOG("someMod is version 1.1 or higher, we can use stuff added in this version")
else
	LOG("Whoops, someMod is lower version than 1.1, we need to use some compatibility fall-back plan, or we just fail to load.")
end
```


### `modApi:addGenerationOption`

| Argument name | Type | Description |
|---------------|------|-------------|
| `id` | string | Identifier for the option |
| `name` | string | Name of the option that will be shown to the player |
| `tip` | string | Tooltip text shown when hovering over this option. Can be nil. |
| `data` | table | Table describing the option. Defaults to a checkbox option if omitted. |

Adds a new configuration option to the mod that is currently being initialized by the mod loader.

Example:
```lua
local function init(self)
	modApi:addGenerationOption("someCheckbox", "Some Checkbox Option", "This is a checkbox option that can be switched on and off. It is unchecked by default.", { enabled = false })

	modApi:addGenerationOption("someCheckbox2", "Another Checkbox Option", "This is a checkbox option that can be switched on and off. It is checked by default.", {})

	modApi:addGenerationOption("someDropdown", "Some Dropdown Option", "This is a dropdown in which the user can select one of multiple values.", {
		-- Internal values of the options
		values = { 1, 2, "a string", true },

		-- Names of the options that will be shown to the player.
		-- Defaults to a string representation of the entry from `values` table
		-- if there's no entry in the `strings` table at the corresponding index.
		strings = { "Option 1", "Option 2", "Option 3", "Option 4" },

		-- The value that is selected by default.
		-- Defaults to the first entry in the `values` table if omitted.
		value = "a string"
	})
end

local function load(self, options, version)
	if options["someCheckbox"].enabled then
		LOG("Some Checkbox Option is checked")
	end

	if options["someCheckbox2"].enabled then
		LOG("Another Checkbox Option is checked")
	end

	LOG("Selected multivalue option: " .. options["someDropdown"].value)
end
```


### `modApi:appendAsset`

| Argument name | Type | Description |
|---------------|------|-------------|
| `resource` | string | Path inside resource.dat where your asset should be placed. Use forward slahes (`/`). |
| `filePath` | string | Path to the asset in local filesystem. A common practice is to prepend `self.resourcePath` (which is the root directory of your mod) to the path. |

Adds an asset (image or font) to the game (by putting it into `resources/resource.dat` file). All calls to this function must be inside your mod's `init` function.

Example:
```lua
modApi:appendAsset("img/weapons/Whip.png",self.resourcePath.."/weapons/Whip.png")
```


### `modApi:addSquad`

| Argument name | Type | Description |
|---------------|------|-------------|
| `squad` | table | A table with 4 values - text identifier of the squad, followed by three mech text identifiers. Each mech mentioned must exist as a global variable, created similarly to game's mechs in `pawns.lua` file. |
| `name` | string | Name of the squad displayed to user. |
| `desc` | string | Description of the squad displayed to user. |
| `icon` | string | Icon used in custom squad selection UI. |

Adds a new squad to the game.

Example:
```lua
modApi:addSquad(
    { "Chess Squad", "AUTO_King", "AUTO_Knight", "AUTO_Rook" },
    "Chess Squad",
    "Chess piece themed mechs.",
    self.resourcePath.."/icon.png"
)
```


### `modApi:overwriteText`

| Argument name | Type | Description |
|---------------|------|-------------|
| `id` | string | Identifier of the text to be replaced |
| `text` | string | New text |


### `modApi:addWeapon_Texts`

| Argument name | Type | Description |
|---------------|------|-------------|
| `tbl` | table | Table with as many key-value string pairs as you need. |

Registers strings related to weapons with the game.

Weapons you create in mods are stored in global variables, and you use names of those variables to equip pawns. For every weapon, the game requires some strings to be defined, or can misbehave, or even crash. If a weapon is stored in vartable WeaponName, the game expects strings `WeaponName_Name` and `WeaponName_Description` to be registered. If a weapon has one upgrade, `WeaponName_Upgrade1` and `WeaponName_A_UpgradeDescription` must be registered, and with two upgrades, the game requires two more strings: `WeaponName_Upgrade2` and `WeaponName_B_UpgradeDescription`. The description for each string is in the table below.

| String | Description |
| --- | --- |
| WeaponName_Name | Name of the weapon displayed to user. |
| WeaponName_Description | Description of the weapon displayed to user. |
| WeaponName_Upgrade1 | Short description of the first upgrade. Make it less than about 12 characters, or it won't fit |
| WeaponName_A_UpgradeDescription | Long description of the first upgrade. |
| WeaponName_Upgrade2 | Short description of the second upgrade. Same restrictions apply. |
| WeaponName_B_UpgradeDescription | Long description of the second upgrade. |

Example:
```lua
modApi:addWeapon_Texts({
	AUTO_Rook_Cannon_Name = "Cross Cannons",
	AUTO_Rook_Cannon_Description = "Fires a projectile in all 4 directions, damaging and pushing on impact.",
	AUTO_Rook_Cannon_Upgrade1 = "Directional",
	AUTO_Rook_Cannon_A_UpgradeDescription = "Fire in three directions instead of four, with increased damage in one direction. Pushes self in the remaining direction.",
	AUTO_Rook_Cannon_Upgrade2 = "+1 Damage",
	AUTO_Rook_Cannon_B_UpgradeDescription = "Increases damage dealt by 1.",
	
	AUTO_Knight_Move_Name = "Knight Smite",
	AUTO_Knight_Move_Description = "Jumps to a location, killing any unit unfortunate enough to be there.",
})
```

A possibly more convenient way to use this function is to put all your weapon strings into a single file, `text_weapons.lua`:

```lua
return {
	AUTO_Rook_Cannon_Name = "Cross Cannons",
	AUTO_Rook_Cannon_Description = "Fires a projectile in all 4 directions, damaging and pushing on impact.",
	AUTO_Rook_Cannon_Upgrade1 = "Directional",
	AUTO_Rook_Cannon_A_UpgradeDescription = "Fire in three directions instead of four, with increased damage in one direction. Pushes self in the remaining direction.",
	AUTO_Rook_Cannon_Upgrade2 = "+1 Damage",
	AUTO_Rook_Cannon_B_UpgradeDescription = "Increases damage dealt by 1.",
	
	AUTO_Knight_Move_Name = "Knight Smite",
	AUTO_Knight_Move_Description = "Jumps to a location, killing any unit unfortunate enough to be there.",
}
```

And then add them to the game using:

```lua
modApi:addWeapon_Texts(require(self.scriptPath.."text_weapons"))
```


### `modApi:addPopEvent`

| Argument name | Type | Description |
|---------------|------|-------------|
| `event` | string | Event id, text identifier specifying which exactly event is being extended. Possible values for event are: `"Opening"`, `"Closing"`, `"Closing_Dead"`, `"Closing_Perfect"`, `"Closing_Bad"`, `"Threatened"`, `"Killed"`, `"Shielded"`, `"Frozen"` |
| `msg` | string | Text displayed to user. Inside the string, `#squad` and `#corp` can be used to refer to current squad name and coropration name respectively. |

Registers PopEvent, the text shown near cities when certain actions happen ("The mechs are here, we're saved!", "Get away from the windows!").


### `modApi:setPopEventOdds`

| Argument name | Type | Description |
|---------------|------|-------------|
| `event` | string | Event id |
| `msg` | number | A number from 0 to 100 indicating the probability of the PopEvent happening. |

Sets the probability of the PopEvent occuring.


### `modApi:addOnPopEvent`

| Argument name | Type | Description |
|---------------|------|-------------|
| `fn` | function | Function to be called when the event occurs. |

Registers the function to be called when a PopEvent occurs. This function is called with 5 arguments, once for each text in the PopEvent.

Arguments to the function are:

| Argument name | Type | Description |
|---------------|------|-------------|
| `text` | string | The text to be displayed to user. |
| `texts` | table | List of all texts registered for that event (and the first argumkent is one of them). |
| `i` | number | index of `text` in `texts` list. |
| `event` | string | Event id. |
| `count` | number | How many texts the game is expecting. |

The function should modify (or leave as it is) and return its first argument - the text displayed to user.

Example:
```lua
function modApi:addOnPopEvent(function(text, texts, i, event, count)
    return text.."!!!"
end)
```


### `modApi:addMap`

| Argument name | Type | Description |
|---------------|------|-------------|
| `mapPath` | string | Path to the map file. |

Copies the specified map to the game's `maps/` directory. Cannot overwrite default (vanilla) maps. **Call in your mod's `init()` function.**

This function ignores the file's parent directories, and only takes the filename into consideration. `some/long/path/to/mymap.map` and `path/mymap.map` will both be copied to `maps/mymap.map`.

Example:
```lua
local function init(self)
	modApi:addMap(self.resourcePath .. "maps/somemap.map")
end
```


## Hooks

### `preMissionAvailableHook`

| Argument name | Type | Description |
|---------------|------|-------------|
| `mission` | table | A table holding information about the current mission |

Fired right before a mission becomes available for selection on the island map.

Example:
```lua
local hook = function(mission)
	LOG("New mission is about to be made available!")
end

modApi:addPreMissionAvailableHook(hook)
```


### `postMissionAvailableHook`

| Argument name | Type | Description |
|---------------|------|-------------|
| `mission` | table | A table holding information about the current mission |

Fired when a mission becomes available for selection on the island map.

Example:
```lua
local hook = function(mission)
	LOG("New mission is now available!")
end

modApi:addPostMissionAvailableHook(hook)
```


### `preEnvironmentHook`

| Argument name | Type | Description |
|---------------|------|-------------|
| `mission` | table | A table holding information about the current mission |

Fired right before effects of the mission's environment (tidal waves, cataclysm, etc) are executed.

Example:
```lua
local hook = function(mission)
	LOG("The environment is about to do its thing!")
end

modApi:addPreEnvironmentHook(hook)
```


### `postEnvironmentHook`

| Argument name | Type | Description |
|---------------|------|-------------|
| `mission` | table | A table holding information about the current mission |

Fired after the effects of the mission's environment (tidal waves, cataclysm, etc) are executed.

Example:
```lua
local hook = function(mission)
	LOG("The environment has done its thing!")
end

modApi:addPostEnvironmentHook(hook)
```


### `nextTurnHook`

| Argument name | Type | Description |
|---------------|------|-------------|
| `mission` | table | A table holding information about the current mission |

Fired at the start of each turn, once for each team.

Both player and enemy have their own turns, so the function will be called twice after the user presses next turn button. Convenient built-in functions to call in the hook are `Game:GetTurnCount()`, which returns how many turns have passed,  and `Game:GetTeamTurn()`, which returns a value that can be compared to `TEAM_PLAYER` and `TEAM_ENEMY`.

Example:
```lua
local hook = function(mission)
	LOG("Currently it is turn of team: " .. Game:GetTeamTurn())
end

modApi:addNextTurnHook(hook)
```


### `missionUpdateHook`

| Argument name | Type | Description |
|---------------|------|-------------|
| `mission` | table | A table holding information about the current mission |

Called once every frame, after the game updates the game entities, ie. things such as status effects (fire/smoke/acid) have been processed and applied to pawns.

Example:
```lua
local hook = function(mission)
	LOG("Entities have been updated!")
end

modApi:addMissionUpdateHook(hook)
```


### `missionStartHook`

| Argument name | Type | Description |
|---------------|------|-------------|
| `mission` | table | A table holding information about the current mission |

Fired right after the player has selected a mission, loads into the game board, and is about to start deploying their mechs.

Example:
```lua
local hook = function(mission)
	LOG("Mission started!")
end

modApi:addMissionStartHook(hook)
```


### `missionEndHook`

| Argument name | Type | Description |
|---------------|------|-------------|
| `mission` | table | A table holding information about the current mission |
| `ret` | SkillEffect | A skill effect that can be used to apply effects to the game board when the mission ends. Vanilla game uses this to make enemies retreat, etc. |

Fired when the turn counter reaches 0, ie. a mission ends.
Not sure if it fires when the player loses all grid power.

Example:
```lua
local hook = function(mission)
	LOG("Mission end!")
end

modApi:addMissionEndHook(hook)
```


### `missionNextPhaseCreatedHook`

| Argument name | Type | Description |
|---------------|------|-------------|
| `prevMission` | table | A table holding information about the previous mission (the one the player just completed) |
| `nextMission` | table | A table holding information about the next mission (the one the player is now entering) |

Fired when a mission with `NextPhase` defined constructs its next phase mission object. 

Example:
```lua
local hook = function(prevMission, nextMission)
	LOG("Left mission " .. prevMission.ID .. ", going into " .. nextMission.ID)
end

modApi:addMissionNextPhaseCreatedHook(hook)
```


### `voiceEventHook`

| Argument name | Type | Description |
|---------------|------|-------------|
| `eventInfo` | VoiceEvent | A userdata type holding information about a voice event. Fields: `id` -- string identifier of the event, `pawn1` -- id of the pawn that triggered the event, if applicable, `pawn2` -- id of the target pawn of the event, if applicable |
| `customOdds` | number | Optional integer value ranging from 0 to 100, used to override odds of the voice dialog being triggered |
| `suppress` | boolean | Whether a voice dialog should be *not* be played in response to this voice event (this is true if eg. another hook has already played a dialog) |

Triggered by the game in response to various events, or by manually invoking the `TriggerVoiceEvent` function.

Example:
```lua
local hook = function(eventInfo, customOdds, suppress)
	if eventInfo.id == "SomeEventWeAreInterestedIn" and not suppress then
		LOG("Voice event!")
		-- We handled this event (and maybe played some dialogs between pilots), so
		-- we return true to tell other hooks that they shouldn't play their dialogs.
		return true
	end

	return false
end

modApi:addVoiceEventHook(hook)
```


### `preStartGameHook`

Fired right after the player exits the hangar and right after mods are loaded, but before game variables are set up (`GAME`, `Game`, `GameData`, `SquadData`, `RegionData`, etc.)

Example:
```lua
local hook = function()
	LOG("About to start a new game!")
end

modApi:addPreStartGameHook(hook)
```


### `postStartGameHook`

Fired after the player exits the hangar and game variables are set up (`GAME`, `Game`, `GameData`, `SquadData`, `RegionData`, etc.).

Example:
```lua
local hook = function()
	LOG("Started a new game!")
end

modApi:addPostStartGameHook(hook)
```


### `preLoadGameHook`

Fired after mods are loaded, but before savegame data is loaded. Triggers when pressing "Continue" and when resetting turn.

Example:
```lua
local hook = function()
	LOG("We're about to load a savegame!")
end

modApi:addPreLoadGameHook(hook)
```


### `postLoadGameHook`

Fired after savegame data is loaded. Triggers when pressing "Continue" and when resetting turn.

Example:
```lua
local hook = function()
	LOG("We've loaded a savegame!")
end

modApi:addPostLoadGameHook(hook)
```


### `saveGameHook`

Fired before the game is saved.

Example:
```lua
local hook = function()
	LOG("Game is being saved!")
end

modApi:addSaveGameHook(hook)
```

