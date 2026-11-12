local framework = ...
local controls = {}
local valid = framework._valid
local modId = 'BladesongModFramework'
local optionsButtons = {}
local forgeState
local nextOptionsScan = 0
local lastError

local function same(a, b)
    return valid(a) and valid(b) and a:GetAddress() == b:GetAddress()
end

local function text(value)
    return StaticFindObject('/Script/Engine.Default__KismetTextLibrary'):Conv_StringToText(value)
end

local function createButton(owner, reference, caption)
    local library = StaticFindObject('/Script/UMG.Default__WidgetBlueprintLibrary')
    local button = library:Create(owner, reference:GetClass(), owner:GetOwningPlayer())
    assert(valid(button), 'Could not create Forge controls button')
    button:SetStyle(reference:GetStyle():GetClass())
    button:SetCaption(text(caption))
    button:SetMinDimensions(0, 28)
    button:SetToolTipText(text(''))
    return button
end

local function parentOfClass(widget, class)
    while valid(widget) and not widget:IsA(class) do widget = widget:GetParent() end
    return widget
end

local function refreshOptions(hidden)
    for address, entry in pairs(optionsButtons) do
        if not valid(entry.owner) or not valid(entry.checkbox) then
            optionsButtons[address] = nil
        else
            local checked = entry.checkbox:IsChecked()
            if checked ~= entry.checked then
                framework.SetSetting(modId, 'hide_tang', checked)
                entry.checked, hidden = checked, checked
            elseif checked ~= hidden then
                entry.checkbox:SetIsChecked(hidden)
                entry.checked = hidden
            end
        end
    end
    if os.time() < nextOptionsScan then return hidden end
    nextOptionsScan = os.time() + 2
    local horizontalClass = StaticFindObject('/Script/UMG.HorizontalBox')
    local checkboxClass = StaticFindObject('/Script/UMG.CheckBox')
    local labelClass = StaticFindObject('/Script/UMG.TextBlock')
    if not valid(horizontalClass) or not valid(checkboxClass) or not valid(labelClass) then return hidden end
    for _, owner in pairs(FindAllOf('WBP_OptionsMenu_C') or {}) do
        if valid(owner) and owner:IsVisible() then
            local address = owner:GetAddress()
            local reference = owner.DisplayHammerTimeUICheckbox
            if not optionsButtons[address] and valid(reference) then
                local row = parentOfClass(reference:GetParent(), horizontalClass)
                local referenceLabel = owner.CommonTextBlock_26
                if valid(row) and valid(referenceLabel) then
                    local checkbox = StaticConstructObject(checkboxClass, owner.WidgetTree)
                    local label = StaticConstructObject(labelClass, owner.WidgetTree)
                    checkbox.WidgetStyle = reference.WidgetStyle
                    checkbox:SetIsChecked(hidden)
                    label:SetText(text('Hide tang'))
                    label:SetFont(referenceLabel.Font)
                    label:SetColorAndOpacity(referenceLabel.ColorAndOpacity)
                    label:SetVisibility(3)
                    local checkSlot = row:AddChildToHorizontalBox(checkbox)
                    checkSlot:SetVerticalAlignment(2)
                    checkSlot:SetPadding({Left=18, Top=0, Right=8, Bottom=0})
                    row:AddChildToHorizontalBox(label):SetVerticalAlignment(2)
                    optionsButtons[address] = {owner=owner, checkbox=checkbox, checked=hidden}
                end
            end
        end
    end
    return hidden
end

local function shown(widget)
    local visibility = widget:GetVisibility()
    return visibility ~= 1 and visibility ~= 2
end

local function visible(widget)
    while valid(widget) do
        if not shown(widget) then return false end
        widget = widget:GetParent()
    end
    return true
end

local function showCatalogue(state)
    if not state.minimized then return end
    for _, entry in ipairs(state.minimized) do
        if valid(entry.widget) and entry.widget:GetVisibility() == 1 then
            entry.widget:SetVisibility(entry.visibility)
        end
    end
    for _, entry in ipairs(state.liftedTooltips or {}) do
        if valid(entry.widget) then entry.widget:SetRenderTranslation(entry.translation) end
    end
    state.liftedTooltips = nil
    state.minimized = nil
end

local function minimizeCatalogue(state)
    state.minimized = {}
    state.liftedTooltips = {}
    local tooltipParent = state.ui.SwordPartTooltipParent
    local tooltips = valid(tooltipParent) and {tooltipParent} or
        {state.ui.SwordPartTooltip, state.ui.SwordPartTooltipSecondary}
    for _, widget in pairs(tooltips) do
        if valid(widget) then
            local translation = widget.RenderTransform.Translation
            state.liftedTooltips[#state.liftedTooltips+1] = {
                widget=widget, translation={X=translation.X,Y=translation.Y}
            }
            widget:SetRenderTranslation({X=translation.X,Y=translation.Y-64})
        end
    end
    for _, widget in ipairs({state.panel, state.polish}) do
        if valid(widget) and shown(widget) then
            state.minimized[#state.minimized+1] = {widget=widget, visibility=widget:GetVisibility()}
            widget:SetVisibility(1)
        end
    end
end

local function clearCatalogue(state)
    showCatalogue(state)
    if valid(state.face) then state.face:RemoveFromParent() end
    if valid(state.lip) then state.lip:RemoveFromParent() end
    if state.restoreFrame then state.restoreFrame(); state.restoreFrame = nil end
    state.button, state.face, state.lip = nil, nil, nil
end

local function clearForge()
    if not forgeState then return end
    if valid(forgeState.tang) then forgeState.tang:SetVisibility(forgeState.tangWasVisible, false) end
    clearCatalogue(forgeState)
    forgeState = nil
end

local function updateCatalogueButton(state)
    local active = shown(state.ui) and visible(state.lip:GetParent())
    if state.minimized and not active then showCatalogue(state) end
    local minimized = state.minimized ~= nil
    local lipVisibility = active and minimized and 0 or 1
    local buttonVisibility = active and not minimized and shown(state.panel) and 4 or 1
    if state.lip:GetVisibility() ~= lipVisibility then state.lip:SetVisibility(lipVisibility) end
    if state.face:GetVisibility() ~= buttonVisibility then state.face:SetVisibility(buttonVisibility) end

end

local function mountExpandedButton(state, column)
    local panel, button = state.panel, state.face
    -- Match the resize handle, which straddles the catalogue's top border.
    button:SetRenderTranslation({X=0,Y=-22})
    local canvasClass = StaticFindObject('/Script/UMG.CanvasPanel')
    local overlayClass = StaticFindObject('/Script/UMG.Overlay')
    local panelClass = StaticFindObject('/Script/UMG.PanelWidget')
    local tree = panel.WidgetTree
    local root = valid(tree) and tree.RootWidget
    local contentClass = StaticFindObject('/Script/UMG.ContentWidget')
    local function addToOverlay(overlay)
        local slot = overlay:AddChildToOverlay(button)
        slot:SetHorizontalAlignment(3)
        slot:SetVerticalAlignment(1)
        slot:SetPadding({Left=0,Top=0,Right=86,Bottom=0})
    end
    -- Follow single-child layout wrappers to the catalogue's framing layer.
    while valid(root) and valid(panelClass) and root:IsA(panelClass) do
        if valid(canvasClass) and root:IsA(canvasClass) then
            local slot = root:AddChildToCanvas(button)
            slot:SetAnchors({Minimum={X=1,Y=0},Maximum={X=1,Y=0}})
            slot:SetAlignment({X=1,Y=0})
            slot:SetPosition({X=-86,Y=0})
            slot:SetSize({X=48,Y=48})
            slot:SetZOrder(20)
            return
        end
        if valid(overlayClass) and root:IsA(overlayClass) then
            addToOverlay(root)
            return
        end
        if valid(overlayClass) and valid(contentClass) and root:IsA(contentClass) and valid(root:GetContent()) then
            local content = root:GetContent()
            local overlay = StaticConstructObject(overlayClass, tree)
            assert(valid(overlay), 'Could not create catalogue frame overlay')
            content:RemoveFromParent()
            root:SetContent(overlay)
            overlay:SetVisibility(4)
            local slot = overlay:AddChildToOverlay(content)
            slot:SetHorizontalAlignment(0)
            slot:SetVerticalAlignment(0)
            local host = root
            state.restoreFrame = function()
                if valid(host) and valid(content) and same(host:GetContent(), overlay) then
                    content:RemoveFromParent()
                    host:SetContent(content)
                end
            end
            addToOverlay(overlay)
            return
        end
        if root:GetChildrenCount() ~= 1 then break end
        root = root:GetChildAt(0)
    end
    -- Give the native catalogue branch a shared layout slot with the toggle.
    -- Reinsert following siblings with their original slots so order is stable.
    if not valid(overlayClass) then return end
    local branch = panel
    while valid(branch) and not same(branch:GetParent(), column) do branch = branch:GetParent() end
    assert(valid(branch), 'Could not find the catalogue branch in its column')
    local function capture(widget)
        local slot = widget.Slot
        assert(valid(slot), 'Catalogue column slot is unavailable')
        return {
            widget=widget,
            padding={Left=slot.Padding.Left,Top=slot.Padding.Top,Right=slot.Padding.Right,Bottom=slot.Padding.Bottom},
            size={Value=slot.Size.Value,SizeRule=slot.Size.SizeRule},
            horizontal=slot.HorizontalAlignment, vertical=slot.VerticalAlignment
        }
    end
    local function following(widget)
        local result, found = {}, false
        for index=0, column:GetChildrenCount()-1 do
            local child = column:GetChildAt(index)
            if found then result[#result+1] = capture(child) end
            if same(child, widget) then found = true end
        end
        assert(found, 'Catalogue branch is missing from the column')
        return result
    end
    local function addToColumn(widget, original)
        local entry = column:AddChildToVerticalBox(widget)
        entry:SetPadding(original.padding)
        entry:SetSize(original.size)
        entry:SetHorizontalAlignment(original.horizontal)
        entry:SetVerticalAlignment(original.vertical)
    end
    local original, trailing = capture(branch), following(branch)
    local overlay = StaticConstructObject(overlayClass, state.ui.WidgetTree)
    assert(valid(overlay), 'Could not create catalogue layout overlay')
    overlay:SetVisibility(4)
    for _, entry in ipairs(trailing) do entry.widget:RemoveFromParent() end
    branch:RemoveFromParent()
    addToColumn(overlay, original)
    local content = overlay:AddChildToOverlay(branch)
    content:SetHorizontalAlignment(0)
    content:SetVerticalAlignment(0)
    -- Paint the controls above the native frame.
    addToOverlay(overlay)
    for _, entry in ipairs(trailing) do addToColumn(entry.widget, entry) end
    state.restoreFrame = function()
        if not valid(column) or not valid(branch) or not same(branch:GetParent(), overlay) or
            not same(overlay:GetParent(), column) then return end
        local siblings = following(overlay)
        for _, entry in ipairs(siblings) do entry.widget:RemoveFromParent() end
        branch:RemoveFromParent()
        overlay:RemoveFromParent()
        addToColumn(branch, original)
        for _, entry in ipairs(siblings) do addToColumn(entry.widget, entry) end
    end
    print('[BMF Forge Controls] Toggle anchored to native catalogue branch\n')
end

local function polishFrame(ui)
    local polish = ui.MaterialPolishSlider
    local horizontalClass = StaticFindObject('/Script/UMG.HorizontalBox')
    local contentClass = StaticFindObject('/Script/UMG.ContentWidget')
    if not valid(polish) or not valid(horizontalClass) then return end
    local frame = parentOfClass(polish:GetParent(), horizontalClass)
    if not valid(frame) then return end
    local parent = frame:GetParent()
    while valid(parent) and valid(contentClass) and parent:IsA(contentClass) do
        frame, parent = parent, parent:GetParent()
    end
    return frame
end

local function findCatalogue(ui)
    if valid(ui.WBP_CataloguePanel) then return ui.WBP_CataloguePanel end
    local panelClass = StaticFindObject('/Script/UMG.PanelWidget')
    if not valid(panelClass) or not valid(ui.WidgetTree) then return end
    local function visit(widget)
        if not valid(widget) then return end
        if widget:GetFName():ToString() == 'WBP_CataloguePanel' or
            widget:GetClass():GetFName():ToString() == 'WBP_CataloguePanel_C' then return widget end
        if widget:IsA(panelClass) then
            for i=0, widget:GetChildrenCount()-1 do
                local found = visit(widget:GetChildAt(i))
                if found then return found end
            end
        end
    end
    local panel = visit(ui.WidgetTree.RootWidget)
    if valid(panel) then return panel end
    for _, candidate in pairs(FindAllOf('WBP_CataloguePanel_C') or {}) do
        if valid(candidate) and same(candidate:GetOuter(), ui.WidgetTree) then return candidate end
    end
end

local function refreshTang(state, hidden)
    if not hidden and not valid(state.tang) then return end
    local blade = hidden and state.forge:GetBladeMesh()
    local tang = valid(blade) and blade.TangProceduralMeshComponent
    if not same(state.tang, tang) then
        if valid(state.tang) then state.tang:SetVisibility(state.tangWasVisible, false) end
        state.tang = nil
        if valid(tang) then state.tang, state.tangWasVisible = tang, tang:IsVisible() end
    end
    if valid(state.tang) and state.tang:IsVisible() then state.tang:SetVisibility(false, false) end
end

local function refreshForge(hidden)
    local mode = FindFirstOf('BladesongGameMode')
    local forge = valid(mode) and mode.ForgeMode
    if not valid(forge) then clearForge(); return end
    local frontend = forge.ForgeModeFrontend
    if not valid(frontend) then clearForge(); return end
    local ui = frontend.ForgeModeUi
    if not valid(ui) then clearForge(); return end
    if not forgeState or not same(forgeState.ui, ui) or not same(forgeState.forge, forge) then
        clearForge()
        forgeState = {forge=forge, ui=ui}
    end
    local state = forgeState
    refreshTang(state, hidden)
    if framework.GetGameBranch() == 'bleedingedge' then
        if valid(state.face) or valid(state.lip) then clearCatalogue(state) end
        return
    end
    if valid(state.button) and (not valid(state.panel) or not valid(state.lip)) then
        clearCatalogue(state)
    end
    if not valid(state.button) then
        if (state.nextLookup or 0) > os.time() then return end
        state.nextLookup = os.time() + 2
        local panel = findCatalogue(ui)
        if not valid(panel) or not valid(ui.LeaveForgeModeButton) then
            if not state.lookupReported then
                state.lookupReported = true
                print(('[BMF Forge Controls] Catalogue lookup panel=%s reference=%s\n'):format(
                    tostring(not not valid(panel)), tostring(not not valid(ui.LeaveForgeModeButton))))
            end
            return
        end
        local verticalClass = StaticFindObject('/Script/UMG.VerticalBox')
        if not valid(verticalClass) then return end
        local column = parentOfClass(panel:GetParent(), verticalClass)
        if not valid(column) then return end
        local borderClass = StaticFindObject('/Script/UMG.Border')
        local sizeClass = StaticFindObject('/Script/UMG.SizeBox')
        if not valid(borderClass) or not valid(sizeClass) then return end
        local face = StaticConstructObject(sizeClass, ui.WidgetTree)
        face:SetWidthOverride(48)
        face:SetHeightOverride(48)
        local frame = StaticConstructObject(borderClass, ui.WidgetTree)
        local fill = StaticConstructObject(borderClass, ui.WidgetTree)
        frame:SetBrushColor({R=.24,G=.23,B=.18,A=1})
        frame:SetPadding({Left=1,Top=1,Right=1,Bottom=1})
        fill:SetBrushColor({R=.012,G=.012,B=.010,A=1})
        fill:SetPadding({Left=0,Top=0,Right=0,Bottom=0})
        face:SetVisibility(4)
        frame:SetVisibility(4)
        fill:SetVisibility(4)
        local button = createButton(ui, ui.LeaveForgeModeButton, '-')
        button:SetMinDimensions(0, 0)
        fill:SetContent(button)
        frame:SetContent(fill)
        face:SetContent(frame)
        local lip = createButton(ui, ui.LeaveForgeModeButton, '+ Sword Parts')
        lip:SetMinDimensions(168, 32)
        lip:SetVisibility(1)
        state.panel, state.polish, state.button, state.face, state.lip = panel, polishFrame(ui), button, face, lip
        mountExpandedButton(state, column)
        local lipSlot = column:AddChildToVerticalBox(lip)
        lipSlot:SetHorizontalAlignment(2)
        print('[BMF Forge Controls] Catalogue toggle and bottom tab attached\n')
    end
    updateCatalogueButton(state)
end

local function safe(callback)
    local ok, err = pcall(callback)
    if not ok and lastError ~= err then
        lastError = err
        print('[BMF Forge Controls] ' .. tostring(err) .. '\n')
    end
end

function controls.Tick()
    local hidden = framework.GetSettings(modId).hide_tang == true
    safe(function() hidden = refreshOptions(hidden) end)
    safe(function() refreshForge(hidden) end)
end

RegisterHook('/Script/CommonUI.CommonButtonBase:HandleButtonClicked', function(context)
    local clicked = context:get()
    local state = forgeState
    if not state or (not same(clicked, state.button) and not same(clicked, state.lip)) then return end
    ExecuteInGameThreadWithDelay(1, function() safe(function()
        if state ~= forgeState or not valid(state.panel) or not valid(state.lip) then return end
        if same(clicked, state.lip) then
            showCatalogue(state)
        elseif same(clicked, state.button) and not state.minimized and shown(state.panel) then
            minimizeCatalogue(state)
        end
        updateCatalogueButton(state)
    end) end)
end, function() end)

return controls
