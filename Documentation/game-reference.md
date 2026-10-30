# Verified game interfaces

SDK/game-reference.json is generated from the locally supplied UE4SS CXXHeaderDump. It contains declarations, header provenance hashes and an evidence label. It does not contain the game executable, full proprietary assets, or a claim that each declared method is runtime tested.

- ABladesongGameMode.GetForgeMode returns the current AForgeMode.
- AForgeMode.GetPiece returns UPiece. UPiece is the sword's data object; ABladeMesh is a rendered actor, not the same type.
- UPiece.WeaponDesignDefinition is FWeaponDesignDefinition. GetSwordDesign exposes that verified design struct. GetSwordComponents traverses the active Forge root part using SlotChildParts and FreeChildParts with cycle/size guards.
- ABladesongGameState.PieceInventory and RecentStoryModeSwordsInventory are different collections. PCL's Creative deletion path excludes Story data.
- WBP_MainMenu has QuitButton, OptionsButton and VersionText. Its user widget may be nested in the game's menu flow, so IsInViewport alone is not a valid discovery test.
- WBP_CreativeModeHome uses native PieceItemsCollection, MagicWordTextBox, DownloadButton, FilterText and ClearButton. Its grid remains native in the migrated UI.
- K2_SetRelativeTransform on SceneComponent is used by the baseline camera marker. Framework.SetComponentTransform validates a presentation transform; it is not a general persistent sword-edit API.

Sword construction/serialization remains in PCL's tested adapters and native helpers. The existing cache/download/anchor helpers contain build-specific assumptions. Their source is included for maintenance, with exact executable gating; public developers should not copy hardcoded addresses into branch-independent mods.

Materials, dynamic material parameters, colors, part slot topology, editable stretch-node restoration and preview generation have PCL-specific behavior. Raw declarations are in the generated reference; stable universal mutation APIs for all those systems are not claimed by this preview.
