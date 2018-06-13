# Mod Loader API

## Table of Contents

* [init.lua](#initlua)

* [API](#api)
	* [Global](#global)
		* [GetScreenCenter](#getscreencenter)
		* [GetHangarOrigin](#gethangarorigin)
		* [SetDifficulty](#setdifficulty)
		* [AddDifficulty](#adddifficulty)
		* [GetDifficultyId](#getdifficultyid)
		* [GetBaselineDifficulty](#getbaselinedifficulty)
		* [InterpolateColor](#interpolatecolor)
		* [compare_tables](#compare_tables)
		* [list_indexof](#list_indexof)
		* [table:OnSerializationStart](#tableonserializationstart)
		* [table:OnSerializationEnd](#tableonserializationend)
		* [RegisterRepairIconReplacement](#registerrepairiconreplacement)

	* [modApi](#modapi)
		* [modApi:deltaTime](#modapideltatime)
		* [modApi:elapsedTime](#modapielapsedtime)
		* [modApi:scheduleHook](#modapischedulehook)
		* [modApi:conditionalHook](#modapiconditionalhook)
		* [modApi:runLater](#modapirunlater)
		* [modApi:splitString](#modapisplitstring)
		* [modApi:splitStringEmpty](#modapisplitstringempty)
		* [modApi:trimString](#modapitrimstring)
		* [modApi:stringStartsWith](#modapistringstartswith)
		* [modApi:stringEndsWith](#modapistringendswith)
		* [modApi:isVersion](#modapiisversion)
		* [modApi:addGenerationOption](#modapiaddgenerationoption)
		* [modApi:writeAsset](#modapiwriteasset)
		* [modApi:readAsset](#modapireadasset)
		* [modApi:appendAsset](#modapiappendasset)
		* [modApi:copyAsset](#modapicopyasset)
		* [modApi:addSquad](#modapiaddsquad)
		* [modApi:overwriteText](#modapioverwritetext)
		* [modApi:addWeapon_Texts](#modapiaddweapon_texts)
		* [modApi:addPopEvent](#modapiaddpopevent)
		* [modApi:setPopEventOdds](#modapisetpopeventodds)
		* [modApi:addOnPopEvent](#modapiaddonpopevent)
		* [modApi:addMap](#modapiaddmap)
		* [modApi:loadIntoEnv](#modapiloadintoenv)
		* [modApi:loadSettings](#modapiloadsettings)
		* [modApi:loadProfile](#modapiloadprofile)
		* [modApi:writeProfileData](#modapiwriteprofiledata)
		* [modApi:readProfileData](#modapireadprofiledata)
		* [modApi:writeModData](#modapiwritemoddata)
		* [modApi:readModData](#modapireadmoddata)

	* [sdlext](#sdlext)
		* [sdlext.isConsoleOpen](#sdlextisconsoleopen)
		* [sdlext.isMainMenu](#sdlextismainmenu)
		* [sdlext.isHangar](#sdlextishangar)
		* [sdlext.isGame](#sdlextisgame)
		* [sdlext.getUiRoot](#sdlextgetuiroot)
		* [sdlext.showDialog](#sdlextshowdialog)
		* [sdlext.showTextDialog](#sdlextshowtextdialog)
		* [sdlext.showAlertDialog](#sdlextshowalertdialog)
		* [sdlext.showInfoDialog](#sdlextshowinfodialog)
		* [sdlext.showConfirmDialog](#sdlextshowconfirmdialog)

* [Hooks](#hooks)
	* modApi
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
		* [preIslandSelectionHook](#preislandselectionhook)
		* [postIslandSelectionHook](#postislandselectionhook)
		* [preStartGameHook](#prestartgamehook)
		* [postStartGameHook](#poststartgamehook)
		* [preLoadGameHook](#preloadgamehook)
		* [postLoadGameHook](#postloadgamehook)
		* [saveGameHook](#savegamehook)
	* sdlext
		* [settingsChangedHook](#settingschangedhook)
		* [continueClickHook](#continueclickhook)
		* [newGameClickHook](#newgameclickhook)
		* [uiRootCreatedHook](#uirootcreatedhook)
		* [mainMenuEnteredHook](#mainmenuenteredhook)
		* [mainMenuExitedHook](#mainmenuexitedhook)
		* [mainMenuLeavingHook](#mainmenuleavinghook)
		* [hangarEnteredHook](#hangarenteredhook)
		* [hangarExitedHook](#hangarexitedhook)
		* [hangarLeavingHook](#hangarleavinghook)
		* [gameEnteredHook](#gameenteredhook)
		* [gameExitedHook](#gameexitedhook)
		* [frameDrawnHook](#framedrawnhook)
		* [windowVisibleHook](#windowvisiblehook)
		* [preKeyDownHook](#prekeydownhook)
		* [preKeyUpHook](#prekeyuphook)
		* [postKeyDownHook](#postkeydownhook)
		* [postKeyUpHook](#postkeyuphook)


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

## Global

### `GetScreenCenter`

Returns a `Point` center of the screen.


### `GetHangarOrigin`

Returns a `Point` representing hangar origin - a reference point that can be used by modded UI to position itself in the hangar in relation to game's own UI.


### `SetDifficulty`

| Argument name | Type | Description |
|---------------|------|-------------|
| `difficultyLevel` | number | The new difficulty level to set |

Sets difficulty of the game to the specified level. Default valid arguments:

* `DIFF_EASY`
* `DIFF_NORMAL`
* `DIFF_HARD`
* `DIFF_VERY_HARD`
* `DIFF_IMPOSSIBLE`

Example:
```lua
SetDifficulty(DIFF_VERY_HARD)
```


### `AddDifficulty`

| Argument name | Type | Description |
|---------------|------|-------------|
| `id` | string | Id of the new difficulty that also serves as its global variable name (eg. DIFF_HARD) |
| `level` | number | Non-negative integer level of the new difficulty. |
| `tipTitle` | string | Title displayed in the hangar when user hovers over this difficulty |
| `tipText` | string | Text displayed in the hangar when user hovers over this difficulty |

Adds a new difficulty level to the game, taking care of minutae like updating texts and enemy spawners.

If there already exists a difficulty level with the same value as the `level` argument, the old difficulty (and all difficulties above it) will be shifted one level up to make room for the difficulty being added. Eg. adding a new difficulty as `DIFF_EASY` (0) will change `DIFF_EASY` to have a value of `1` (`DIFF_NORMAL` to `2`, etc).

Custom difficulty levels use the same vek spawning and score rules as the vanilla difficulty level directly below them. Eg. adding a "Very Hard" difficulty level will have additional alpha Vek and increase score by 50%. Adding a "New Normal" that is between vanilla "Normal" and "Hard" will use normal vek spawning and normal score. This is called a **baseline difficulty level**. To get it programmatically, use [GetBaselineDifficulty](#getbaselinedifficulty).

Example:
```lua
AddDifficulty(
	"DIFF_VERY_HARD",
	#DifficultyLevels, -- adds as a new highest difficulty
	"Very Hard Mode",
	"Intended for veteran Commanders looking for a challenge."
)
```


### `GetDifficultyId`

| Argument name | Type | Description |
|---------------|------|-------------|
| `level` | number | Difficulty level whose id is to be returned. Defaults to value returned by `GetDifficulty()` if omitted. |

Returns the id of the specified difficulty level.

Example:
```lua
LOG(GetDifficultyId(DIFF_EASY)) -- prints DIFF_EASY
```


### `GetBaselineDifficulty`

| Argument name | Type | Description |
|---------------|------|-------------|
| `level` | number | Difficulty level to get the baseline difficulty for. Defaults to value returned by `GetDifficulty()` if omitted. |

Returns the baseline difficulty level for the specified level.

A baseline difficulty level is the vanilla difficulty level that is immediately below the one specified. Eg. a custom difficulty of level 2 would sit between `DIFF_NORMAL` and `DIFF_HARD`, so its baseline difficulty level would be `DIFF_NORMAL`.

Example:
```lua
LOG(GetBaselineDifficulty(DIFF_VERY_HARD)) -- prints value of DIFF_HARD
```


### `IsVanillaDifficultyLevel`

| Argument name | Type | Description |
|---------------|------|-------------|
| `level` | number | Difficulty level to check. Defaults to value returned by `GetDifficulty()` if omitted. |

Returns `true` if the level specified in argument is a vanilla difficulty level (`DIFF_EASY`, `DIFF_NORMAL`, `DIFF_HARD`), accounting for shifting done by `AddDifficulty`.


### `InterpolateColor`

| Argument name | Type | Description |
|---------------|------|-------------|
| `startColor` | userdata | Color (`sdl.rgb`/`sdl.rgba`) to start interpolating from |
| `endColor` | userdata | Color (`sdl.rgb`/`sdl.rgba`) to interpolate to |
| `t` | number | Number value in range [0, 1], specifying the intensity of `endColor` (0 means 100% `startColor`, 1 means 100% `endColor`) |

Linearly interpolates between two color values.

Example:
```lua
local c1 = sdl.rgb(255, 0, 0) -- red
local c2 = sdl.rgb(0, 0, 255) -- blue
local c3 = InterpolateColor(c1, c2, 0.66) -- purple (84, 0, 168)
```


### `compare_tables`

| Argument name | Type | Description |
|---------------|------|-------------|
| `tbl1` | table | First table to compare |
| `tbl2` | table | Second table to compare |

Compares two distinct tables for equality, checking member table fields recursively using the same function. Fields that cannot be compared (eg. userdata) are ignored. Does not explicitly account for metatables. Returns `true` if both tables hold the same data, `false` otherwise.


### `list_indexof`

| Argument name | Type | Description |
|---------------|------|-------------|
| `list` | table | List to search |
| `value` | object | The value to look for |

Returns index of the `value` object in the specified list, or `nil` if not found.


### `table:OnSerializationStart`

| Argument name | Type | Description |
|---------------|------|-------------|
| `t` | table | A helper table used to store temporarily removed fields |

Every table that is saved to `GAME`, and defines this function, will have this function called whenever the game is being saved. This effectively allows to temporarily prune unserializable fields (such as raw pawn references), or transient data that should not be saved to the savefile (for example when creating custom Missions).

The `t` argument can be used to save the field before it is removed. The same table is then passed on to `OnSerializationEnd` callback, allowing to restore the field.

Example:
```lua
mytable = {}
mytable.transientField = "qwe"
mytable.OnSerializationStart = function(self, t)
	t.transientField = self.transientField
	self.transientField = nil
end

-- OR

MyMission.transientField = "qwe"
funtion MyMission:OnSerializationStart(t)
	t.transientField = self.transientField
	self.transientField = nil
end
```


### `table:OnSerializationEnd`

| Argument name | Type | Description |
|---------------|------|-------------|
| `t` | table | A helper table used to store temporarily removed fields |

Every table that is saved to `GAME`, and defines this function, will have this function called whenever the game is being saved. This effectively allows to temporarily prune unserializable fields (such as raw pawn references), or transient data that should not be saved to the savefile (for example when creating custom Missions).

The `t` argument can be used to retrieve fields that were removed in `OnSerializationStart` callback.

Example:
```lua
mytable = {}
mytable.OnSerializationEnd = function(self, t)
	self.transientField = t.transientField
end

-- OR

function MyMission:OnSerializationEnd(t)
	self.transientField = t.transientField
end
```


### `RegisterRepairIconReplacement`

| Argument name | Type | Description |
|---------------|------|-------------|
| `personalityId` | string | Id of the pilot personality whose repair icon is to be replaced (sans the `Pilot_` prefix, eg. `Original`) |
| `iconPath` | string | Path to the image that will replace the repair icon. Either in the game archives, or in the mod directory. |

This function allows to define repair skill replacement icons that will be drawn on top of the vanilla repair icon.

Caveats:
- Hotkey is obscured by the custom icon
- Replacement icon shows up when the pilot of the last selected mech had a replacement registered, is deselected, and then another mech is hovered over without being selected.

Example:
```lua
RegisterRepairIconReplacement("Original", "img/weapons/repair_mantis.png")
```


## modApi

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


### `modApi:conditionalHook`

| Argument name | Type | Description |
|---------------|------|-------------|
| `conditionFn` | function | Argumentless predicate function evaluated once every frame |
| `fn` | function | Argumentless function which will be invoked when the amount of time specified in the first argument has elapsed. |
| `remove` | boolean | Whether the hook should be removed once it is triggered. Defaults to `true` if omitted. |

Registers a conditional hook which will be executed once the condition function associated with it returns `true`. By default, the hook is removed once it is triggered.

Example:
```lua
-- This hook gets fired when a Combat Mech is selected
modApi:conditionalHook(
	function()
		return Pawn and Pawn:GetType() == "PunchMech"
	end,
	function()
		LOG("Punch mech selected")
	end
)
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

Splits the input string around the provided separator string, and returns a table holding the split string. Does not include empty strings.


### `modApi:splitStringEmpty`

| Argument name | Type | Description |
|---------------|------|-------------|
| `input` | string | The string to be split |
| `separator` | string | The string to split by. Defaults to whitespace if omitted |

Splits the input string around the provided separator string, and returns a table holding the split string. Includes empty strings.


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


### `modApi:writeAsset`

| Argument name | Type | Description |
|---------------|------|-------------|
| `resource` | string | Path inside resource.dat where your asset should be placed. Use forward slahes (`/`). |
| `content` | string | String content to be written to the file |

Writes a file with the specified content to the `resource.dat` archive, either creating a new file or overwriting one if it already exists. All calls to this function must be inside your mod's `init` function.


### `modApi:readAsset`

| Argument name | Type | Description |
|---------------|------|-------------|
| `resource` | string | Path inside resource.dat where your asset should be placed. Use forward slahes (`/`). |

Reads the specified file from the `resource.dat` archive, and returns its contents as a string. Throws an error if the file could not be found. All calls to this function must be inside your mod's `init` function.

Example:
```lua
modApi:readAsset("img/units/player/mech_punch.png")
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


### `modApi:copyAsset`

| Argument name | Type | Description |
|---------------|------|-------------|
| `src` | string | Path inside `resource.dat`, specifying the file to be copied. Use forward slahes (`/`). |
| `dst` | string | Path inside `resource.dat`, specifying the destination the file will be copied to. |

Copies an existing asset within the `resource.dat` archive to another path within the `resource.dat` archive. Can overwrite existing files. All calls to this function must be inside your mod's `init` function.

Example:
```lua
-- replaces reactor core image with The Button
modApi:copyAsset("img/weapons/support_destruct.png", "img/weapons/reactor_core.png")
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


### `modApi:loadIntoEnv`

| Argument name | Type | Description |
|---------------|------|-------------|
| `path` | string | Path to the file to load. |
| `envTable` | table | The environment the file will be loaded to. Will hold all global variables the file defines. Can be omitted, defaulting to an empty table. |

Loads the specified file, loading any global variable definitions into the specified table instead of the global namespace (\_G). The file can still access variables defined in \_G, but not write to them by default (unless specifically doing \_G.foo = bar).

Return value of the loaded file is ignored by this function.

Example:
```lua
local env = modApi:loadIntoEnv("some/file.lua")
GlobalVar = env.var1       -- this variable will be accessible globally
local localVar = env.var2  -- this variable will not
```


### `modApi:loadSettings`

Reloads the settings file to have access to selected settings from in-game lua scripts. Generally you shouldn't have to call this, the modloader reloads the file on its own and stores the result in global `Settings` table.

If you need to be notified when settings change, see [settingsChangedHook](#settingschangedhook).

Example:
```lua
local settings = modApi:loadSettings()
```


### `modApi:loadProfile`

Reloads profile data of the currently selected profile. Generally you shouldn't have to call this, the modloader reloads the profile data on its own and stores the result in global `Profile` table.

Example:
```lua
local profile = modApi:loadProfile()
```


### `modApi:writeProfileData`

| Argument name | Type | Description |
|---------------|------|-------------|
| `id` | string | Key the data will be saved as in the modded profile table |
| `obj` | object | A lua object to store in the modded profile table |

Stores the specified object under the specified key in `modcontent.lua` file in the currently selected profile's directory.

Example:
```lua
local diff = GetDifficulty()
modApi:writeProfileData("CustomDifficulty", level)
```


### `modApi:readProfileData`

| Argument name | Type | Description |
|---------------|------|-------------|
| `id` | string | Key of the data to be retrieved from the modded profile table |

Reads the object under the specified key from `modcontent.lua` file in the currently selected profile's directory.

Example:
```lua
local diff = modApi:readProfileData("CustomDifficulty")
```


### `modApi:writeModData`

| Argument name | Type | Description |
|---------------|------|-------------|
| `id` | string | Key the data will be saved as in the modded settings table |
| `obj` | object | A lua object to store in the modded settings table |

Stores the specified object under the specified key in `modcontent.lua` file in game's savedata directory.

Example:
```lua
local diff = GetDifficulty()
modApi:writeModData("CustomDifficulty", level)
```


### `modApi:readModData`

| Argument name | Type | Description |
|---------------|------|-------------|
| `id` | string | Key the data will be saved as in the modded settings table |

Reads the object under the specified key from `modcontent.lua` file in game's savedata directory.

Example:
```lua
local diff = modApi:readModData("CustomDifficulty")
```


## sdlext

### `sdlext.isConsoleOpen`

Returns `true` if console is currently open. `false` otherwise.


### `sdlext.isMainMenu`

Returns `true` if the player is currently in the main menu. `false` otherwise.


### `sdlext.isHangar`

Returns `true` if the player is currently in the hangar. `false` otherwise.


### `sdlext.isGame`

Returns `true` if the player is currently in a game. `false` otherwise.


### `sdlext.getUiRoot`

Returns the root UI element.


### `sdlext.showDialog`

| Argument name | Type | Description |
|---------------|------|-------------|
| `initFn` | function | An initialization function used to create the dialog's UI |


`initFn`:

| Argument name | Type | Description |
|---------------|------|-------------|
| `ui` | table | The UI object the dialog should be added to. |
| `quit` | function | Argumentless function that be invoked to programmatically dismiss the dialog. |

Puts a dark overlay on the screen which intercepts key and mouse events and prevents them from reaching the game (exception: for some reason the console receives partial input). The game continues running in the background. Clicking on the dark overlay or pressing Escape will dismiss the dialog.

This function can be used to stack multiple dialogs on top of each other. Only the most recently created dialog is active. Quitting the dialog makes the previous dialog active.

The `ui` object defines a `onDialogExit` callback, which can be overridden to run some custom code once the dialog is dismissed.

Example:
```lua
sdlext.showDialog(function(ui, quit)
	local clicked = 0

	ui.onDialogExit = function(self)
		LOG("The button has been left-clicked " .. clicked .. " times.")
	end

	local btn = Ui()
		:widthpx(200):heightpx(30)
		:pos(0.25, 0.3)
		:decorate({ DecoButton(), DecoCaption() })
		:caption("Click me!")
		:addTo(ui)

	btn.onclicked = function(self, button)
		if button == 1 then -- left click only
			clicked = clicked + 1

			if clicked >= 10 then
				quit()
			end
		end

		return true
	end
end)
```


### `sdlext.showTextDialog`

| Argument name | Type | Description |
|---------------|------|-------------|
| `title` | string | Title of the dialog |
| `text` | string | Text displayed in the dialog |
| `w` | number | Optional width of the dialog. Defaults to 700 if omitted. |
| `h` | number | Optional height of the dialog. Defaults to 400 if omitted. |

Shows a simple information dialog on the screen, which prevents interaction with the game until it is dismissed, either by clicking outside of it, or pressing Escape.

The dialog's height is automatically changed depending on length of the message, up to a maximum of 400px, after which the text becomes scrollable.

Example:
```lua
sdlext.showTextDialog(
	"Attention",
	"This is a very important message that demands your attention."
)
```


### `sdlext.showAlertDialog`

| Argument name | Type | Description |
|---------------|------|-------------|
| `title` | string | Title of the dialog |
| `text` | string | Text displayed in the dialog |
| `responseFn` | function | Function which receives index of the clicked button as argument. Can be nil. |
| `w` | number | Optional width of the dialog. Defaults to 700 if omitted. |
| `h` | number | Optional height of the dialog. Defaults to 400 if omitted. |
| `buttons` | string(s) | Varargs. Texts for buttons that will be displayed below the dialog text. Must have at least one argument. |

Shows a dialog on the screen, which prevents interaction with the game until it is dismissed. The dialog can only be dismissed by clicking one of the buttons.

Button texts typically should be in all uppercase, to match the game's dialogs' style.

When the dialog is dismissed, the `responseFn` function is called, with the index of the clicked button as its argument.

The dialog's height is automatically changed depending on length of the message, up to a maximum of 400px, after which the text becomes scrollable.

The dialog's width is automatically changed depending on number and width of buttons. Width is not capped, and putting too many buttons will simply cause the dialog to be too wide to be displayed on the screen.

Example:
```lua
local buttons = { "OK, I GOT IT", "JEEZ, LET ME GO ALREADY" }
local responseFn = function(buttonIndex)
	LOG("Clicked button:", buttons[buttonIndex])
end

sdlext.showAlertDialog(
	"Attention",
	"This is a very important message that demands your attention, and it will not allow you to dismiss it without acknowledging its presence.",
	responseFn, nil, nil, buttons
)
```


### `sdlext.showInfoDialog`

| Argument name | Type | Description |
|---------------|------|-------------|
| `title` | string | Title of the dialog |
| `text` | string | Text displayed in the dialog |
| `responseFn` | function | Function which receives index of the clicked button as argument. Can be nil. |
| `w` | number | Optional width of the dialog. Defaults to 700 if omitted. |
| `h` | number | Optional height of the dialog. Defaults to 400 if omitted. |

Convenience function to display an information dialog.

Shows an undismissable dialog with the specified title and text, and an `OK` button.


### `sdlext.showConfirmDialog`

| Argument name | Type | Description |
|---------------|------|-------------|
| `title` | string | Title of the dialog |
| `text` | string | Text displayed in the dialog |
| `responseFn` | function | Function which receives index of the clicked button as argument. Can be nil. |
| `w` | number | Optional width of the dialog. Defaults to 700 if omitted. |
| `h` | number | Optional height of the dialog. Defaults to 400 if omitted. |

Convenience function to display a confirmation dialog.

Shows an undismissable dialog with the specified title and text, and `YES` and `NO` buttons.


## Hooks

## modApi

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


### `preIslandSelectionHook`

| Argument name | Type | Description |
|---------------|------|-------------|
| `corporation` | string | A string identifier of the island's corporation. `Corp_Grass`, etc. |
| `island` | number | A number id of the island. `0` for Archive, `1` for R.S.T., etc. |

Fired when the player selects an island, before missions are created for the island.

Example:
```lua
local hook = function(corporation, island)
	LOG("Selected island " .. island .. ": " .. corporation)
end

modApi:addPreIslandSelectionHook(hook)
```


### `postIslandSelectionHook`

| Argument name | Type | Description |
|---------------|------|-------------|
| `corporation` | string | A string identifier of the island's corporation. `Corp_Grass`, etc. |
| `island` | number | A number id of the island. `0` for Archive, `1` for R.S.T., etc. |

Fired when the player selects an island, after missions have been created for the island.

Example:
```lua
local hook = function(corporation, island)
	LOG("Selected island " .. island .. ": " .. corporation)
end

modApi:addPostIslandSelectionHook(hook)
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


## sdlext

### `settingsChangedHook`

| Argument name | Type | Description |
|---------------|------|-------------|
| `old` | table | Old settings table |
| `new` | table | New settings table |

Fired when settings are changed.

Example:
```lua
sdlext.addSettingsChangedHook(function(old, new)
	LOG("Settings have changed")
end)
```


### `continueClickHook`

Fired when the Continue button in main menu is clicked.

Example:
```lua
sdlext.addContinueClickHook(function()
	LOG("Continue clicked!")
end)
```


### `newGameClickHook`

Fired when the New Game button in main menu is clicked (does not account for the confirmation popup when trying to start a new game while still having a game you can return to -- for that, use [`mainMenuLeavingHook`](#mainmenuleavinghook)).

Example:
```lua
sdlext.addNewGameClickHook(function()
	LOG("New Game clicked!")
end)
```


### `uiRootCreatedHook`

| Argument name | Type | Description |
|---------------|------|-------------|
| `screen` | userdata | The screen object accepting draw instructions |
| `uiRoot` | table | The root UI element |

Fired when the root UI element is created. This hook can be used to create your own custom UI, if you need it created as soon as the game starts.

The root UI element handles stuff like mouse and keyboard interaction with the game. All of your mod's UI should be a child of this root UI element.

Example:
```lua
sdlext.addUiRootCreatedHook(function(screen, uiRoot)
	LOG("UI root created!")
end)
```


### `mainMenuEnteredHook`

| Argument name | Type | Description |
|---------------|------|-------------|
| `screen` | userdata | The screen object accepting draw instructions |
| `wasHangar` | boolean | True if the player was previously in the hangar screen |
| `wasGame` | boolean | True if the player was prviously in game |

Fired when the player enters the main menu screen.

Example:
```lua
sdlext.addMainMenuEnteredHook(function(screen, wasHangar, wasGame)
	LOG("Main menu entered!")
end)
```


### `mainMenuExitedHook`

| Argument name | Type | Description |
|---------------|------|-------------|
| `screen` | userdata | The screen object accepting draw instructions |

Fired when the player exits the main menu screen.

Example:
```lua
sdlext.addMainMenuExitedHook(function(screen)
	LOG("Main menu exited!")
end)
```


### `mainMenuLeavingHook`

Fired when the player starts leaving the main menu screen.

Example:
```lua
sdlext.addMainMenuLeavingHook(function()
	LOG("Leaving main menu!")
end)
```


### `hangarEnteredHook`

| Argument name | Type | Description |
|---------------|------|-------------|
| `screen` | userdata | The screen object accepting draw instructions |

Fired when the player enters the hangar screen.

Example:
```lua
sdlext.addHangarEnteredHook(function(screen)
	LOG("Hangar entered!")
end)
```


### `hangarExitedHook`

| Argument name | Type | Description |
|---------------|------|-------------|
| `screen` | userdata | The screen object accepting draw instructions |

Fired when the player exits the hangar screen.

Example:
```lua
sdlext.addHangarExitedHook(function(screen)
	LOG("Hangar exited!")
end)
```


### `hangarLeavingHook`

| Argument name | Type | Description |
|---------------|------|-------------|
| `startGame` | boolean | `true` if the hangar is being left to start a new game. `false` otherwise. |

Fired when the player starts leaving the hangar screen.

Example:
```lua
sdlext.addHangarLeavingHook(function(startGame)
	LOG("Leaving hangar!")
end)
```


### `gameEnteredHook`

| Argument name | Type | Description |
|---------------|------|-------------|
| `screen` | userdata | The screen object accepting draw instructions |

Fired when the player enters the game screen.

Example:
```lua
sdlext.addGameEnteredHook(function(screen)
	LOG("Game entered!")
end)
```


### `gameExitedHook`

| Argument name | Type | Description |
|---------------|------|-------------|
| `screen` | userdata | The screen object accepting draw instructions |

Fired when the player exits the game screen.

Example:
```lua
sdlext.addGameExitedHook(function(screen)
	LOG("Game exited!")
end)
```


### `frameDrawnHook`

| Argument name | Type | Description |
|---------------|------|-------------|
| `screen` | userdata | The screen object accepting draw instructions |

Fired when a frame is finished being drawn.

Example:
```lua
sdlext.addFrameDrawnHook(function(screen)
	LOG("Frame drawn!")
end)
```


### `windowVisibleHook`

| Argument name | Type | Description |
|---------------|------|-------------|
| `screen` | userdata | The screen object accepting draw instructions |
| `wx` | number | X position of the window on screen in pixels |
| `wy` | number | Y position of the window on screen in pixels |
| `ww` | number | Width of the window in pixels |
| `wh` | number | Height of the window in pixels |

Fired every frame when a shadow-casting UI element is visible. This includes a variety of stuff like inert UI panes, tooltips, tip images, etc. Can be used to hack together heuristics for whether some kind of UI window is open.

`sdlext.CurrentWindowRect` is a rect that is set to the `wx`, `wy`, `ww`, and `wh` values every frame, reducing the need for this hook. `sdlext.LastWindowRect` does the same, but holds values for the previous window that was visible before the current one has been opened.

Example:
```lua
sdlext.addWindowVisibleHook(function(screen, wx, wy, ww, wh)
	LOG("Window visible! Dimensions:", wx, wy, ww, wh)
end)
```


### `preKeyDownHook`

| Argument name | Type | Description |
|---------------|------|-------------|
| `keycode` | number | SDL keycode of the key that has been pressed. See [SDL Keycode Lookup table](https://wiki.libsdl.org/SDLKeycodeLookup) |

Fired whenever a key is pressed down. The hooked function can optionally return `true` to signal that it handled the key event, and that this event should not be processed further. This stops the game and other hooks from even being notified of this keypress.

Key hooks are fired WHEREVER in the game you are, whenever you press a key. So your hooks will need to have a lot of additional restrictions on *when* they're supposed to fire.

Pre key hooks are fired BEFORE the `uiRoot` handles the key events. These hooks can be used to completely hijack input and bypass the normal focus-based key event handling.

Example:
```lua
sdlext.addPreKeyDownHook(function(keycode)
	LOG("Pressed key: " .. keycode)
end
```


### `preKeyUpHook`

| Argument name | Type | Description |
|---------------|------|-------------|
| `keycode` | number | SDL keycode of the key that has been pressed. See [SDL Keycode Lookup table](https://wiki.libsdl.org/SDLKeycodeLookup) |

Fired whenever a key is released. The hooked function can optionally return `true` to signal that it handled the key event, and that this event should not be processed further. This stops the game and other hooks from even being notified of this keypress.

Key hooks are fired WHEREVER in the game you are, whenever you press a key. So your hooks will need to have a lot of additional restrictions on *when* they're supposed to fire.

Pre key hooks are fired BEFORE the `uiRoot` handles the key events. These hooks can be used to completely hijack input and bypass the normal focus-based key event handling.

Example:
```lua
sdlext.addPreKeyUpHook(function(keycode)
	LOG("Released key: " .. keycode)
end
```


### `postKeyDownHook`

| Argument name | Type | Description |
|---------------|------|-------------|
| `keycode` | number | SDL keycode of the key that has been pressed. See [SDL Keycode Lookup table](https://wiki.libsdl.org/SDLKeycodeLookup) |

Same as [preKeyDownHook](#prekeydownhook), except:

Post key hooks are fired AFTER the `uiRoot` has handled the key events. These hooks can be used to process leftover key events which haven't been handled via the normal focus-based key event handling.

Example:
```lua
sdlext.addPostKeyDownHook(function(keycode)
	LOG("Pressed key: " .. keycode)
end
```


### `postKeyUpHook`

| Argument name | Type | Description |
|---------------|------|-------------|
| `keycode` | number | SDL keycode of the key that has been pressed. See [SDL Keycode Lookup table](https://wiki.libsdl.org/SDLKeycodeLookup) |

Same as [preKeyUpHook](#prekeyuphook), except:

Post key hooks are fired AFTER the `uiRoot` has handled the key events. These hooks can be used to process leftover key events which haven't been handled via the normal focus-based key event handling.

Example:
```lua
sdlext.addPostKeyUpHook(function(keycode)
	LOG("Released key: " .. keycode)
end
```

