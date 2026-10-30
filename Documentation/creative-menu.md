# Creative menu ownership

The framework provides the Creative library and Story swords tabs, folder-tab
layout, larger tile area, search and Magic Words footer, Forge Blade button,
hover behavior, selection/multi-delete controls and verified save backups.
These remain available without Preconstruction Library installed.

PCL 15.18.2 adds its library provider to the shared host. Its library tab, data
and import/copy/delete actions are available when PCL is enabled. PCL no longer
contains the Creative screen layout implementation. Its Forge-specific parts,
blades, anchors, previews and placement behavior remain in PCL.

Only one host owns a Creative screen at a time: the framework-only host when PCL
is absent/disabled, or the same framework implementation bound to PCL's data
provider when present. Existing provider instances keep their native widgets
and data within their own UE4SS Lua state; UObjects never cross the message bus.

Framework save snapshots are kept separately in BMF_SaveBackups under the
game's Saved directory. A checked backup is required before multi-delete.

## Add another tab

Put a Lua adapter beside the framework's main.lua. It returns a function accepting
`registry` and calls `registry.register{id, label, order, width, on_select, is_active}`.
Copy creative_tabs_config.example.lua to creative_tabs_config.lua and list the
adapter module names there. The framework draws and updates the folder lips.
