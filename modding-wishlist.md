# Modding Wishlist

What follows is a list of features that would make modding Into the Breach much easier, or would open a lot of new doors that are currently closed.


## Modded UI

At the moment, modded UI is implemented by replacing original `lua5.1.dll` and `SDL2.dll`, and adding `opengl32.dll` libraries. Mods then create hook functions which receive an instance of SDL `screen` object as argument, and push their drawing operations to that. This allows drawing on top of the game's frames.

This solution works decently at the moment, but once Into the Breach is released on other platforms, all mods which make use of modded UI will be effectively SOL'd, and will most likely not work. Seeing as I have no C++ experience whatsoever, I will not be able to update the .dlls to work on other platforms. Without an experienced C++ programmer to do this, or direct support from the game's side, the days of modded UI are effectively numbered.


## Game settings modification

Ability to modify game settings like fullscreen, colorblind mode, grid numbers on/off, etc.

This could be easily achieved by taking the `Settings` table obtained by loading the `settings.lua` file, making changes to values, then offering the altered table back to the game through a function. The game could look at the table and see what's changed, and apply those changes via native functions.


## Savedata modification

`GameData`, `SquadData`, maybe also `RegionData`

Ability to modify `SquadData` and `GameData` would be useful to allow modifying the player's equipment or pilots on the fly.

For that matter, having those tables be updated by the game itself, instead of requiring a modloader to continually refresh them by reloading the save file would be pretty great.

Things that are interesting from a modder's perspective that are present in the savefile, but not accessible from lua (to the best of my knowledge, at the moment):

- Current health of buildings
- The player's inventory
- Pilot data - current experience, skills (both powered and passive)
- Changing pilots assigned to each mech
- Pretty much everything about pawns:
	- Currently equipped weapons
	- Powered/unpowered and upgrade status of weapons
	- Knowing whether a pawn has moved already / allowing a pawn to move again
	- Health and move upgrade status
	- Modifying max health of the pawn
	- Setting health of each pawn directly (without having to do that via SpaceDamage)
- Plenty of other things I'm forgetting right now

## Enemies using the `Move` skill, like player mechs do

Currently mods are unable to easily detect movement of enemies, because unlike player mechs, they do not use a Move skill that is exposed to lua. Making enemies use a skill to move (not necessarily the same one as player mechs, though it would be nice) would allow mods to detect their movement.


## Ability to temporarily have more than 3 piloted mechs

This is in reference to an idea where each island's CEO could assist the player somehow by joining the battle in their own mech. It would be a great touch to have the CEO's portrait displayed in the pilot's list during missions.

Not that this makes any sense lore-wise, but it'd be a nice option to have. If this is not feasible, it can probably be hacked in via modded UI, as long as there's API exposed to notify the game's UI of being clicked.

At the moment, attempting to add a third mech pawn crashes the game.

