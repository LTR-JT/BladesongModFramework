return {
 properties={weapon_design='WeaponDesignDefinition',piece_name='Name',applied_parts='AppliedSwordParts'},
 objects={text='/Script/Engine.Default__KismetTextLibrary',utils='/Script/Bladesong.Default__BladesongUtils',gameplay='/Script/Engine.Default__GameplayStatics',system='/Script/Engine.Default__KismetSystemLibrary'},
 classes={sword='/Script/Bladesong.Piece',forge='/Script/Bladesong.ForgeMode',part='/Script/Bladesong.SwordPartActor',main_menu='/Game/UI/MainMenu/WBP_MainMenu.WBP_MainMenu_C'},
 events={forge_enter='/Script/Bladesong.BladesongGameMode:EnterForgeMode',forge_leave='/Script/Bladesong.BladesongGameMode:LeaveAnyMode',common_button='/Script/CommonUI.CommonButtonBase:HandleButtonClicked'},
 functions={synchronize='SerializeSwordPartActorsToData',root_part='GetRootSwordPartActor',game_state='GetBladesongGameState',game_mode='GetBladesongGameMode',forge='GetForgeMode',current_sword='GetPiece'},
 capabilities={['forge.parts']='/Script/Bladesong.ForgeMode:GetRootSwordPartActor',['component.transform']='/Script/Engine.SceneComponent:K2_SetRelativeTransform',['game.state']='/Script/Bladesong.BladesongUtils:GetBladesongGameState',['forge.read']='/Script/Bladesong.ForgeMode:GetPiece',['ui.native_buttons']='/Script/CommonUI.CommonButtonBase:HandleButtonClicked'},
}
