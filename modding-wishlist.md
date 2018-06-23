# Modding Wishlist

What follows is a list of features that would make modding Into the Breach much easier, or would open a lot of new doors that are currently closed.

There is no particular order to this list, other than maybe chronological.


## Modded UI

At the moment, modded UI is implemented by replacing original `lua5.1.dll` and `SDL2.dll`, and adding `opengl32.dll` files. Mods then create hook functions which receive an instance of a `screen` object as argument, and push their drawing operations to that. This allows drawing on top of the game's frames.

This solution works decently at the moment, but once Into the Breach is released on other platforms, all mods which make use of modded UI will be effectively FUBAR'd, and will most likely stop working. Seeing as I have no C++ experience whatsoever, I will not be able to update the DLLs to work on other platforms. Without an experienced C++ programmer to do this, or direct support from the game's side, the days of modded UI are effectively numbered.

Things that the game's lua API should provide in order to make the mod loader independent of modified DLLs (this list is incomplete, and probably uses different terminology than the game's engine):
- A function allowing to walk a directory tree (needed to find and load mods in /mods directory)
	- Technically doable in lua, but requires a lot of fussing and would likely be pretty slow
- A way to draw arbitrary pixels on the screen
	- Rendering a rect of solid color (RGB/RGBA)
	- Rendering a texture
	- Rendering text
	- Clipping to prevent drawing outside of the designated area (to implement a scrollable pane)
- A color object (RGB/A) with read-write access to fields
- A texture object used to draw images/text on the screen
	- Read access to width and height
- A font object
- A timer: read access to `SDL_GetTicks()` would be sufficient to implement this
- Read access to mouse position

Code for the DLLs is hosted on GitHub. Hopefully these files will be useful:
Functions exported to lua: https://github.com/AUTOMATIC1111/IntoTheBreachLua/blob/master/lua-functions.cc#L133
SDL abstractions (?): https://github.com/AUTOMATIC1111/IntoTheBreachLua/blob/master/sdl-utils.cpp


## Game settings modification

Ability to modify game settings like fullscreen, colorblind mode, grid numbers on/off, etc. Ability to read those settings without having to load `settings.lua` (since it's not updated frequently enough -- eg. clicking Windows' Maximize button does not update the fullscreen setting).

This could be fairly easily achieved by taking the `Settings` table obtained by loading the `settings.lua` file, making changes to values, then offering the altered table back to the game through a function. The game could look at the table and see what's changed, and apply those changes by calling the appropriate native functions.


## Savedata modification

*Problem*: modifying game state data that's not included in the lua API. This includes various data stored under `GameData`, `SquadData`, `RegionData` tables in the save file.

Things that are interesting from a modder's perspective that are present in the savefile, but not accessible from lua (to the best of my knowledge, at the moment):

- Current health of buildings (or all tiles, for that matter -- `Board:IsDamaged()` is not enough)
- The player's inventory (giving and removing items)
- Pilot data - current experience, skills (both powered and passive)
- Changing pilots assigned to each mech
- Pretty much everything about pawns:
	- Getting / setting currently equipped weapons
	- Powered/unpowered and upgrade status of weapons
	- Knowing whether a pawn has moved already / allowing a pawn to move again
	- Health and move upgrade status
	- Modifying max health of the pawn instance
	- Setting health of each pawn instance directly (without having to do that via `SpaceDamage`)
	- Modifying undo state of a pawn (both whether a move can be undone, and the state that the pawn will be restored to when undo move is performed)
- ...plenty of other things I'm forgetting right now


## Savedata storage format

The way savedata file is serialized and formatted makes its manual inspection an absolute pain.

Currently, only the `GAME` table is serialized through the `save_table()` function in `global.lua`. Either making the default serializer use prettier formatting, or handling all serialization (where possible, userdata and functions are obviously out of the question) through that function would be a nice addition.


## Enemies using the `Move` skill, like player mechs do

Currently mods are unable to easily detect movement of enemies, because unlike player mechs, they do not use the Move skill that is exposed to lua. Making enemies use a skill to move (not necessarily the same one as player mechs, though it would be nice) would allow mods to detect their movement.


## (Temporarily) Controlling more than 3 piloted mechs

This is in reference to an idea where each island's CEO could assist the player somehow by joining the battle in their own mech. It would be a great touch to have the CEO's portrait displayed in the pilot's list during missions.

Not that this makes any sense lore-wise, but it'd be a nice option to have. If this is not feasible, it can probably be hacked in via modded UI, as long as there's API exposed to notify the game's own UI of being clicked / allow modded UI to call the same functions that game UI does.

At the moment, attempting to add a fourth mech pawn crashes the game.


## Rebinding console key (~)

People with some keyboard layouts have to switch their layout every time they wish to open the console, which is really inconvenient.

This does not necessarily have to be via the in-game options menu. If casual players abusing the console (and inadvertently messing up their savegames) is a concern, hiding it away in `settings.lua` is perfectly fine.


## Modding maps

Currently, the entire `maps/` scripts directory is sandboxed, and completely separate from the `scripts/` directory, making dynamic control of map loading/selection logic fairly challenging, if not downright impossible. Handling maps through the same lua context as the other scripts would be a great addition.


## Modding sound

As it stands, modders have no way at all to add new sound files or define new FMOD sound events (or it is prohibitively difficult). Perhaps it would be possible to have a `modded.bank` file loaded by the game, whose FMOD project is exposed, allowing modification by mods?

Recently, Celeste has released its whole FMOD project. Perhaps this could be used for reference. Quote from Discord:
```
Satellite - Last Tuesday at 14:38

https://www.fmod.com/download#demos Celeste, also using FMOD Studio for sound, released its whole FMOD project and lets you activate FMOD live update in the game settings (Steam version) which makes it possible to mod on the fly while the game is running. If Subset did something similar, even if they release just the project and not the assets, that would make audio mods very easy to make (main problem would then be conflicting audio mods)
```


## Playing sounds

At the moment sounds can be played via `Game:TriggerSound` function. Generally this is fine, however the `Game` object is `nil` when in the main menu or in the hangar, which means that there's no way for mods to play sounds while not in an active game.


## `GetSkillEffect` and weapon previews

When aiming a weapon, the game uses the `SkillEffect` returned by that weapon to construct the live preview of the weapon effects, shown directly on the game board. It's pretty great, but there's one issue with it.

When the player confirms their targeting decision, the game uses the exact same `SkillEffect` instance that was used to construct the preview. This is an understandable optimization, however it severely limits the potential of modded weapons, since for very complex weapons, the preview constructed by the game is often wrong.

A very simple fix would be to have the game call the weapon's `GetSkillEffect` method once more, after the pawn's armed weapon has been reset to -1. This would allow modded weapons to check whether the pawn is in targeting mode (via `GetArmedWeaponId`), and modify the returned `SkillEffect` instance accordingly, to construct an accurate preview.
