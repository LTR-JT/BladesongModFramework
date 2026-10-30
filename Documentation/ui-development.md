# Menus and input

Framework/shared/BladesongFramework/ui/pcl_menu_host.lua is the actual PCL native-grid menu implementation, preserved rather than replaced. ui/folder_tabs.lua is its existing registry. ui/primitives.lua is extracted from its tested folder-lip rendering and native-button hit behavior, with host adapters for the central manager.

A PCL library-page request uses native Creative Mode navigation and then waits for its existing grid. It does not load a sword or enter Forge.

RegisterPage publishes only a title/description and page ID. The callback stays in the dependent mod and is invoked by Framework.Poll. Commands use bounded serialized shared variables. Each mod has one pending page request; they are navigation commands, not a reliable general-purpose event stream. Lua functions are never serialized.

Native CommonButtonBase clicks dispatch through the game's reflected HandleButtonClicked event. Decorative strokes and labels are hit-test invisible. Native transparent button faces retain a small positive opacity so their Slate hit testing remains active. The PCL Forge lip has a dedicated viewport surface to avoid the native border intercepting its horizontal seam.

Reacquire widget references after transitions. Never blindly call a guessed method: an absent reflected function may appear as a UE4SS TrivialObject proxy, which is not callable. The earlier GetToolTipText failure is an example; the verified API exposes ToolTipText as a property.

The SDK event-listener and menu-page examples use implemented functions. Raw RegisterKeyBind is a UE4SS API, not a framework invention. Keep UObject reads/writes on the game thread; asynchronous workers may process network/file data only.
