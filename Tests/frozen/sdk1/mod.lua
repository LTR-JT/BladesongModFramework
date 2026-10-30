-- Frozen preservation fixture: do not modify to accommodate newer game adapters.
return function(SDK)
 local sword,why=SDK.GetCurrentSword()
 if not sword then return nil,why end
 local design=SDK.GetSwordDesign(sword)
 return {sword=sword,part_count=#design.AppliedSwordParts}
end
