# Into the Breach Mod Loader

A mod loader for the game [Into the Breach](https://www.subsetgames.com/itb.html), written in Lua, and with extension DLLs for some additional features. Originally created by Cyberboy2000, who has unfortunately been absent and unreachable for extended periods of time.

- The mod loader's thread on Subset forums: [link](https://www.subsetgames.com/forum/viewtopic.php?f=26&t=33119)
- Original lua mod loader created by *Cyberboy2000*: [link](https://www.subsetgames.com/forum/viewtopic.php?f=26&t=32833)
- Original Lua proxy DLLs created by *AUTOMATIC*: [link](https://github.com/AUTOMATIC1111/IntoTheBreachLua)


## Download

The mod loader can be downloaded from the [Releases](https://github.com/kartoFlane/ITB-ModLoader/releases) page above.

Since people unfamiliar with GitHub are often confused where to click:

<img src="https://i.imgur.com/NpaEhyE.png"/><img src="https://i.imgur.com/EOULQhJ.png"/>


## Installation

Extract the zip file into the game's base directory, overwriting files as necessary. The zip includes original copies of the overwritten files so you can easily revert, if need be.

If you're upgrading from a previous version of the modloader and encounter issues, the nuclear option of doing a clean reinstall of the game will solve all of them. If not, come ask your question either on [Into the Breach Discord server in `#modding-discussion` channel](https://discord.gg/trrNB6p), or [on the Subset forums](https://www.subsetgames.com/forum/viewtopic.php?f=26&t=33119).


## Uninstallation

To uninstall the mod loader, follow these steps:

1. Go to the base game directory (the one containing the .exe)
2. Delete `lua5.1.dll`, `SDL2.dll`, and `opengl32.dll`.
3. Rename `lua5.1-original.dll` to `lua5.1.dll`, and `SDL2-original.dll` to `SDL2.dll`.
4. Go to `scripts` folder, find the file named `scripts.lua`, open it with any text editor, and remove this line (near the end of the file): `"scripts/mod_loader/__scripts.lua"`. Save the file.
5. Go to `resources` folder, and delete `resource.dat`.
6. Rename `resource.dat.bak` to `resource.dat`.

After that, the game should be back to unmodded state. If you get any errors despite following these steps, try validating integrity of game cache (if on Steam), or reinstalling the game.
