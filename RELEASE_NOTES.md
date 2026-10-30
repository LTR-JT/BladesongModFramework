Bladesong Mod Framework 0.1.6

Download **BladesongModFramework_0.1.6_Easy_Install_With_UE4SS.zip** for a new installation. Close Bladesong, Extract All, open the folder and double-click INSTALL.cmd. UE4SS is included and its debug windows are disabled.

- Browse displays cached or bundled entries immediately; network refresh runs in the background.
- Installation and repository URLs are part of Browse. There is no separate Install tab.
- Updates are checked at startup and shown with Update controls on Installed mod cards. There is no separate Updates tab.
- Deferred native button actions run on the next frame instead of waiting for the half-second monitor interval.
- Creative PCL tabs reuse library models and thumbnails. Preview decoding is progressive, outside the tab click callback; repeated binding events no longer repeatedly rebuild the card controls.
- Index/name changes and invalid game objects invalidate the cache.
- Manual and easy installs include ownership receipts for future in-game updates.

PCL 15.18.2 remains compatible. First-time network requests and uncached thumbnails still need time; cached content can be used while that work finishes.

- Browse shows a checkmark and Installed text for existing mods.
- The catalogue URL is hidden; the dark, gold-text Install from URL field is at the top of Browse.
- Creative mode has a bottom-right Close control using the native Main Menu action.

- Install and Update are one click: validate, download, enable and restart/apply automatically. Local-edit and staged-file checks run before requesting game exit.
