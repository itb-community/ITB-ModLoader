Notes on how to perform various tasks related to maintaining the mod loader.

# Releasing a new version

1. Finish up your changes on the master branch
2. Increment the version in `modApi.version` variable, in `scripts/mod_loader/modapi/init.lua`.
3. Prepare package zip
   - GitHub workflows:  
      1. Run the `Package` GitHub workflow, replacing the default version input (`#.#.#`) with desired version, eg. `2.6.3`
      2. When the job completes, the properly named artifact will be available for download

      *- or -*
   - Manually:  
      1. Run `package.bat` script - it will produce a file named `ITB-ModLoader-#.#.#.zip`
      2. Replace the `#` with appropriate version numbers, eg. `#.#.#` to `2.6.3`
4. Prepare a new release
    1. Navigate to the Releases page on the mod loader's GitHub repository page 
    2. Click `Draft a new release` button
    3. Fill out the tag version and release title fields with the version number, prefixed with `v`
       - So for version `2.6.3`, the tag and release name will be `v2.6.3`
    4. Write out the changelog for the release, briefly summarising all changes made since last release, with links to relevant wiki pages on the mod loader's GitHub wiki.
       - It's useful to prepare the draft as soon as there's a change, and prepare the changelog entry for it. This way you don't have to recall features you've implemented several weeks/months back.
    5. Attach the zip file to the release
    6. Publish the release
5. Update releases, links, and write update posts for:
   - [Nexusmods](https://www.nexusmods.com/intothebreach/mods/6)
      - Brief release notes, link back to GitHub release page for full notes
      - Upload ZIP package
   - [Subset forums thread](https://subsetgames.com/forum/viewtopic.php?f=26&p=117100)
      - Edit original post - update thread title & download links, pointing to GitHub release page
      - Post brief release notes, link back to GitHub release page for full notes
   - [Discord](https://discord.gg/trrNB6p)
      - `#modding-discussion` channel
      - Brief message that a new version is available, possibly mention major milestones, link back to GitHub release page

# Updating `SDL2.dll`

Navigate to https://github.com/kartoFlane/IntoTheBreachLua (or your fork) - the README has instructions on how to build the `.dll`
