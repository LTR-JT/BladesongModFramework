-- Framework-owned Creative menu implementation. Internal legacy names retain compatibility.
PCL151762_HOME=nil
PCL151762_IMPORT=nil
function pcl151762_text(value)
    if type(value)=='string' then return value end
    local ok,s=pcall(function()return value:ToString()end)
    return ok and type(s)=='string' and s or ''
end
function pcl151762_visible(home)
    return is_valid(home) and home:IsInViewport() and home:IsVisible()
end
function pcl151762_context(state)
    assert(state and PCL151762_HOME==state and pcl151762_visible(state.home),'Creative screen changed')
    local utils=StaticFindObject('/Script/Bladesong.Default__BladesongUtils')
    assert(is_valid(utils),'Game utilities unavailable')
    local gm,gs=utils:GetBladesongGameMode(state.home),utils:GetBladesongGameState(state.home)
    assert(is_valid(gm) and gm:IsCreativeMode() and is_valid(gs),'Open Creative mode first')
    local control=state.home.PieceItemsCollection
    assert(is_valid(control) and is_valid(control.BoundCollection),'Creative inventory unavailable')
    local collection=control.BoundCollection
    assert(is_valid(gs.PieceInventory) and collection:GetAddress()==gs.PieceInventory:GetAddress(),'Creative inventory binding changed')
    assert(not is_valid(gs.RecentStoryModeSwordsInventory) or collection:GetAddress()~=gs.RecentStoryModeSwordsInventory:GetAddress(),'Story inventory is excluded')
    return gs,collection,gm,utils
end
function pcl151762_snapshot(state)
    local gs,collection=pcl151762_context(state)
    local list,ids={},{}
    local items=collection.Items or collection:GetItems()
    local function visit(_,value)
        local piece=pcl151114_unwrap(value);assert(is_valid(piece),'Creative inventory changed')
        local id=piece:GetAddress();assert(not ids[id],'Duplicate Creative inventory object')
        ids[id]=true;list[#list+1]={piece=piece,id=id}
    end
    if type(items)=='table' and type(items.ForEach)~='function'then
        for index,value in ipairs(items)do visit(index,value)end
    else items:ForEach(visit)end
    assert(#list<=6000,'Creative inventory is too large for multi-delete')
    local keys={};for _,item in ipairs(list)do keys[#keys+1]=tostring(item.id)end
    return list,table.concat(keys,','),gs,collection
end
function pcl151762_status(state,message)
    if state and is_valid(state.message)then state.message:SetText(pcl15171_to_text(message or ''));state.message:SetVisibility(message and message~=''and 0 or 1)end
    log('PCL15_17_62_HOME '..tostring(message or ''))
end
function pcl151762_button(state,parent,caption,kind,extra)
    local button=pcl151723_button(state.panel,caption,state.rendering_rows and 44 or 56)
    local action=extra or {};action.kind=kind;action.home_state=state;action.panel=state.panel
    pcl15171_bind_button(button,action)
    local list=state.rendering_rows and state.row_buttons or state.buttons;list[#list+1]=button
    if parent then pcl151723_hadd(parent,button,true,2)end
    return button
end
function pcl151762_forget_buttons(buttons)
    for _,button in ipairs(buttons or {})do
        local id=button:GetAddress()
        PCL15171_ACTIONS[id]=nil;PCL15171_BOUND[id]=nil;PCL15171_LAST_CLICK[id]=nil;PCL151723_NATIVE_BUTTONS[id]=nil
        if PCL151762_CHROMELESS then PCL151762_CHROMELESS[id]=nil end
        if PCL15176_BUTTONS then PCL15176_BUTTONS[id]=nil end
    end
end
function pcl151762_preview_from_cache(code,panel)
    local statics=gameplay_statics_15()
    local saveclass=StaticFindObject('/Script/Bladesong.CreativeModeSave');local piececlass=StaticFindObject('/Script/Bladesong.Piece')
    assert(is_valid(saveclass) and is_valid(piececlass),'Preview data classes unavailable')
    local save=statics:LoadGameFromSlot(pcl151726_slot(code),0)
    if not is_valid(save) or save:GetClass():GetAddress()~=saveclass:GetAddress()then return end
    local piece=StaticConstructObject(piececlass,panel);pcl151731_fresh(piece);assert(is_valid(piece),'Preview data allocation failed')
    assert(pcl151726_bridge().restore(save:GetAddress(),piece:GetAddress(),saveclass:GetAddress(),piececlass:GetAddress())==1,'Preview data restore refused')
    local texture=piece:GetPreviewImage()
    if is_valid(texture)then PCL151724_PREVIEWS[code]={owner=panel,piece=piece,texture=texture}end
end
function pcl151762_selected_count(state)
    local n=0;for _ in pairs(state.selected or {})do n=n+1 end;return n
end
function pcl151762_mode(state,mode)
    if mode~='delete'then state.last_library_view=mode end
    assert(not state.busy and not state.confirm and not PCL151762_IMPORT,'Finish the current operation first')
    if mode=='all'then state.view='all';state.page=1;state.form:SetVisibility(1);pcl151762_render(state);pcl151762_status(state,'');return end
    if mode~='delete'then
        assert(mode=='parts' or mode=='blades','Unknown library tab')
        state.preview_cache=state.preview_cache or {};state.preview_cache[PCL151761_MODE]=state.preview_cache[PCL151761_MODE]or PCL151724_PREVIEWS or {}
        PCL151761_MODE=mode;PCL15171_LIBRARY_DIR=mode=='blades' and PCL151761_BLADE_DIR or PCL151761_PARTS_DIR
        PCL15171_LIBRARY_PATH=mode=='blades' and (PCL15171_LIBRARY_DIR..'library.index') or PCL151761_PARTS_PATH
        state.preview_cache=state.preview_cache or {};state.preview_cache[mode]=state.preview_cache[mode]or {}
        PCL151724_PREVIEWS=state.preview_cache[mode]
        local entries=BMF_CREATIVE_LIBRARY_CACHE.entries(mode,PCL15171_LIBRARY_DIR,PCL15171_LIBRARY_PATH)
        PCL15171_LIBRARY={};for _,entry in ipairs(entries)do PCL15171_LIBRARY[#PCL15171_LIBRARY+1]=entry.code end
        pcl151724_load_metadata()
    end
    state.view=mode;state.page=1;state.form:SetVisibility(1);pcl151762_render(state);pcl151762_status(state,'')
end
function pcl151762_input(state,open)
    local player=state.home:GetOwningPlayer();local lib=pcl15171_widget_library()
    if is_valid(player) and is_valid(lib)then
        if open==nil then lib:SetInputMode_GameAndUIEx(player,nil,0,false,false)
        else lib:SetInputMode_UIOnlyEx(player,open and state.panel or state.home,0,false)end
    end
end
function pcl151762_backup(state,gs)
    local _,_,_,utils=pcl151762_context(state);gs:SaveGame()
    local paths=StaticFindObject('/Script/Engine.Default__BlueprintPathsLibrary')
    assert(is_valid(paths),'Save paths unavailable; nothing deleted')
    local profile=pcl151762_text(utils:GetCurrentProfileSavegameDir()):gsub('\\','/'):gsub('/$','')
    local saved=pcl151762_text(paths:ProjectSavedDir()):gsub('\\','/'):gsub('/$','')
    local source
    for _,name in ipairs({profile..'/CreativeMode.sav',saved..'/SaveGames/'..profile..'/CreativeMode.sav',saved..'/'..profile..'/CreativeMode.sav'})do
        local file=io.open(name,'rb')
        if file then local header=file:read(4);file:close();if header=='GVAS'then source=name;break end end
    end
    assert(source,'Creative save backup unavailable; nothing deleted')
    local target=PCL151761_PARTS_DIR..'creative_before_delete_'..os.date('%Y%m%d_%H%M%S')..'_'..math.floor(os.clock()*1000)..'.sav'
    local input=assert(io.open(source,'rb'));local output=assert(io.open(target,'wb'));local total=0
    local ok,err=pcall(function()
        while true do local chunk=input:read(1024*1024);if not chunk then break end;assert(output:write(chunk));total=total+#chunk end
        assert(total>=4 and output:close());output=nil;input:close();input=nil
        local original=assert(io.open(source,'rb'));local backup=assert(io.open(target,'rb'));local same=true
        while true do local a,b=original:read(1024*1024),backup:read(1024*1024);if a~=b then same=false;break end;if not a then break end end
        original:close();backup:close();assert(same,'Backup verification failed; nothing deleted')
    end)
    if input then input:close()end;if output then output:close()end
    assert(ok,tostring(err));return target
end
function pcl151762_review_delete(state)
    assert(state.view=='delete' and not state.busy,'Multi-delete is unavailable')
    local list,fingerprint,gs,collection=pcl151762_snapshot(state)
    assert(fingerprint==state.fingerprint,'Inventory changed. Reopen Multi-delete and select again.')
    local selected={};for _,item in ipairs(list)do if state.selected[item.id]then selected[#selected+1]=item end end
    assert(#selected>0,'Select at least one Creative sword')
    state.confirm={items=selected,fingerprint=fingerprint,gs=gs,collection=collection}
    pcl151762_status(state,'Delete '..#selected..' selected Creative swords? A backup will be saved first.');pcl151762_controls(state)
end
function pcl151762_commit_delete(state)
    if PCL151762_SAVE_BACKUP then pcl151762_require_save_backup()end
    local request=assert(state.confirm,'Review the selected swords first')
    local _,fingerprint,gs,collection=pcl151762_snapshot(state)
    assert(fingerprint==request.fingerprint and gs:GetAddress()==request.gs:GetAddress() and collection:GetAddress()==request.collection:GetAddress(),'Inventory changed; nothing deleted')
    request.backup=pcl151762_backup(state,gs);state.busy=true;state.confirm=nil;request.deleted=0;state.deleting=request;pcl151762_controls(state)
    local function finish(message)
        if is_valid(gs)then pcall(function()gs:SaveGame()end)end
        state.busy=false;state.deleting=nil;state.selected={}
        if PCL151762_HOME==state and pcl151762_visible(state.home)then pcl151762_render(state);pcl151762_status(state,message)end
        log('PCL15_17_62_BULK_DELETE deleted='..request.deleted..' backup='..request.backup)
    end
    local function step()
        local ok,err=pcall(function()
            local current,_,current_gs,current_collection=pcl151762_snapshot(state)
            assert(current_gs:GetAddress()==gs:GetAddress() and current_collection:GetAddress()==collection:GetAddress(),'Creative inventory changed')
            local present={};for _,item in ipairs(current)do present[item.id]=item.piece end
            for i=1,4 do
                local item=request.items[request.deleted+1];if not item then break end
                assert(is_valid(item.piece) and present[item.id] and present[item.id]:GetAddress()==item.piece:GetAddress(),'Selected sword changed; deletion stopped')
                gs:RemovePiece(item.piece)
                local remaining=pcl151762_snapshot(state)
                present={}
                for _,other in ipairs(remaining)do assert(other.id~=item.id,'Game did not remove the selected sword');present[other.id]=other.piece end
                request.deleted=request.deleted+1
            end
        end)
        if not ok then finish('Deleted '..request.deleted..' swords; stopped: '..tostring(err)..'. Backup kept.');return end
        if request.deleted==#request.items then finish('Deleted '..request.deleted..' Creative swords. Backup saved.');return end
        pcl151762_status(state,'Deleting '..request.deleted..' / '..#request.items..' Creative swords...');pcl15179_schedule(33,step)
    end
    pcl15179_schedule(1,step)
end
function pcl151762_import_done(request,message)
    if PCL151762_IMPORT~=request then return end
    PCL151762_IMPORT=nil
    for _,widget in ipairs({request.service,request.holder})do if is_valid(widget)then pcall(function()widget:RemoveFromParent()end)end end
    if PCL151762_HOME==request.state then
        if request.state.open then pcl151762_render(request.state)end
        pcl151762_status(request.state,message);pcl151762_controls(request.state)
    end
end
function pcl151762_start_import(state,raw)
    assert(state.view=='parts' or state.view=='blades','Select a library first')
    assert(not PCL151762_IMPORT and not PCL151719_IMPORT and not PCL151725_UPLOAD_PENDING,'An import or upload is already running')
    local _,_,gm=pcl151762_context(state)
    local code=pcl15171_trim(raw):lower();assert(code:match('^%a+%-%a+%-%a+$'),'Enter a valid Magic Word')
    if pcl151726_has_cache(code)then assert(pcl15171_add_code(code));pcl151762_render(state);pcl151762_status(state,'Already saved in this library.');return end
    local bridge,why=pcl151719_bridge();assert(bridge,tostring(why))
    assert(bridge.status()~=1 and bridge.status()~=-9,'The previous download is still pending')
    local service=pcl15171_create_widget(state.home,state.home:GetClass())
    local holder=pcl15171_create_widget(state.home,state.home.PieceItemsCollection.ItemTemplate)
    local entryclass=StaticFindObject('/Script/Bladesong.UWPieceInventoryEntry');local piececlass=StaticFindObject('/Script/Bladesong.Piece')
    assert(is_valid(service) and is_valid(holder) and is_valid(entryclass) and holder:IsA(entryclass) and is_valid(piececlass),'Library download data objects unavailable')
    holder:SetVisibility(1);service:SetVisibility(1);state.hidden:AddChild(holder);state.hidden:AddChild(service)
    local request={state=state,service=service,holder=holder,bridge=bridge,code=code,mode=state.view,started=os.clock(),gm=gm}
    local armed=bridge.arm_home(service:GetAddress(),gm:GetAddress(),holder:GetAddress(),holder:GetClass():GetAddress(),piececlass:GetAddress())
    assert(armed==1,'Library-only download refused ('..tostring(armed)..')')
    PCL151762_IMPORT=request
    local sent,send_err=pcall(function()service:DownloadPiece(code)end)
    if not sent then bridge.cancel();pcl151762_import_done(request,'Download could not start.');error(tostring(send_err))end
    state.form:SetVisibility(1);pcl151762_status(state,'Importing into the '..state.view..' library...');pcl151762_controls(state)
    local function poll()
        if PCL151762_IMPORT~=request then return end
        local ok,err=pcall(function()
            if PCL151762_HOME~=state or not pcl151762_visible(state.home)then bridge.cancel();pcl151762_import_done(request,'Import cancelled: Creative screen changed.');return end
            if request.failed then pcl151762_import_done(request,'Magic Word download failed.');return end
            local status=bridge.status()
            if status==1 then assert(os.clock()-request.started<125,'Download timed out');pcl15179_schedule(100,poll);return end
            assert(status==2,'Download stopped ('..tostring(status)..')')
            local source=holder.BoundPiece;assert(is_valid(source),'Downloaded data unavailable');local piece=source
            if request.mode=='blades'then
                piece=pcl151761_fresh_piece(holder,source)
                assert(pcl151761_bridge().snapshot(source:GetAddress(),piece:GetAddress(),source:GetClass():GetAddress())==1,'Blade extraction failed')
                piece.Name=pcl15171_to_text(pcl15171_from_text(source:GetRawPieceName()));holder.BoundPiece=piece
            end
            local saved,save_err=pcl151726_save(code,piece);assert(saved,tostring(save_err))
            assert(pcl15171_add_code(code),'Could not update the library index')
            PCL151724_META[code]={original=pcl15171_from_text(piece:GetRawPieceName()),custom=''};assert(pcl151724_save_metadata())
            if request.mode=='parts' or #source.WeaponDesignDefinition.AppliedSwordParts==0 then
                local texture=source:GetPreviewImage()
                if is_valid(texture)then PCL151724_PREVIEWS[code]={owner=holder,texture=texture};pcl151727_save_preview(code,texture,state.panel)end
            end
            pcl151762_import_done(request,'Added to your '..request.mode..' library.')
            log('PCL15_17_62_HOME_IMPORTED mode='..request.mode..' code='..code..' forge_opened=false creative_inventory_added=false')
        end)
        if not ok then bridge.cancel();pcl151762_import_done(request,'Import stopped: '..tostring(err))end
    end
    pcl15179_schedule(100,poll)
end
function pcl151762_monitor_home()
    pcl151762_start_save_backup()
    local state=PCL151762_HOME
    if state and not pcl151762_visible(state.home)then pcl151762_cleanup_home();state=nil end
    if state then pcall(pcl151762_align_toolbar,state);return end
    for _,home in pairs(FindAllOf('WBP_CreativeModeHome_C') or {})do
        if pcl151762_visible(home) and is_valid(home.ForgeButton) and PCL151762_FAILED_HOME~=home:GetAddress()then
            if not pcl15171_load_widget_assets(home)then return end
            local ok,err=pcall(pcl151762_create_home,home)
            if not ok then pcl151762_cleanup_home();PCL151762_FAILED_HOME=home:GetAddress();log('PCL15_17_62_HOME_UI_ERROR '..tostring(err))end
            return
        end
    end
end
function pcl151762_library_delete(state)
    assert(state.library_selecting and state.open and state.view~='delete'and not state.busy,'Library selection changed')
    assert(not PCL151762_IMPORT and not PCL151719_IMPORT and not PCL151725_UPLOAD_PENDING,'Finish the current import/upload first')
    pcl151762_context(state)
    if not state.confirm then
        local selected={}
        for _,entry in ipairs(state.library_items or {})do if state.selected[entry.id]then selected[#selected+1]=entry end end
        assert(#selected>0,'Select at least one library entry')
        local files={}
        for _,entry in ipairs(selected)do
            assert(entry.mode=='parts'or entry.mode=='blades','Unknown library type')
            local path=entry.mode=='parts'and PCL151761_PARTS_PATH or(PCL151761_BLADE_DIR..'library.index')
            local file=files[path]
            if not file then
                local input=assert(io.open(path,'rb'));local data=input:read('*a');input:close();file={path=path,before=data,codes={}};files[path]=file
            end
            file.codes[entry.code]=true
        end
        for _,file in pairs(files)do
            local remaining,found={},{}
            for line in (file.before..'\n'):gmatch('(.-)\r?\n')do
                if file.codes[line]then found[line]=true elseif line~=''then remaining[#remaining+1]=line end
            end
            for code in pairs(file.codes)do assert(found[code],'Library changed; select again')end
            file.after=table.concat(remaining,'\n')..'\n'
        end
        state.confirm={library=true,files=files,count=#selected}
        pcl151762_status(state,'Remove '..#selected..' selected library entries? Library index backups will be kept.');pcl151762_controls(state);return
    end
    local request=state.confirm;assert(request.library,'Selection type changed')
    local ordered={};for _,file in pairs(request.files)do
        local input=assert(io.open(file.path,'rb'));local current=input:read('*a');input:close();assert(current==file.before,'Library changed; nothing removed');ordered[#ordered+1]=file
    end
    table.sort(ordered,function(a,b)return a.path<b.path end)
    local stamp=os.date('%Y%m%d_%H%M%S')..'_'..math.floor(os.clock()*1000000)
    -- Prepare and verify every backup before replacing either index. Cached build
    -- data is retained, so removing a library entry cannot delete Creative saves.
    for _,file in ipairs(ordered)do
        file.backup=file.path..'.before_multi_delete_'..stamp..'.bak'
        local existing=io.open(file.backup,'rb');if existing then existing:close();error('Backup path already exists')end
        local out=assert(io.open(file.backup,'wb'));assert(out:write(file.before));assert(out:close())
        local check=assert(io.open(file.backup,'rb'));local data=check:read('*a');check:close();assert(data==file.before,'Backup verification failed')
        file.temp=file.path..'.multi_delete_'..stamp..'.tmp';out=assert(io.open(file.temp,'wb'));assert(out:write(file.after));assert(out:close())
    end
    local committed={}
    local ok,err=pcall(function()
        for _,file in ipairs(ordered)do
            local original=file.path..'.multi_delete_'..stamp..'.old';assert(os.rename(file.path,original),'Could not stage library index')
            local success,why=os.rename(file.temp,file.path)
            if not success then assert(os.rename(original,file.path),'Could not restore library index');error(tostring(why))end
            file.original=original;committed[#committed+1]=file
        end
    end)
    if not ok then
        for i=#committed,1,-1 do local file=committed[i];assert(os.remove(file.path));assert(os.rename(file.original,file.path),'Could not restore library index; backup kept at '..file.backup)end
        error(tostring(err))
    end
    for _,file in ipairs(committed)do os.remove(file.original)end
    state.confirm=nil;state.selected={};pcl151762_mode(state,state.view)
    pcl151762_status(state,'Removed '..request.count..' library entries. Backups kept.')
end

function pcl151762_exit_to_main(state)
 assert(not state.busy and not state.confirm and not PCL151762_IMPORT,'Finish the current operation first')
 local player=state.home:GetOwningPlayer()
 local function finish()
  if PCL151762_HOME~=state then return true end
  for _,menu in pairs(FindAllOf('WBP_PauseMenu_C')or {})do
   if is_valid(menu)and is_valid(menu.BtnMainMenu)and is_valid(menu:GetOwningPlayer())and menu:GetOwningPlayer():GetAddress()==player:GetAddress()then
    local button=menu.BtnMainMenu
    pcl151762_cleanup_home()
    button:HandleButtonClicked() -- Use the game's own save/navigation flow.
    return true
   end
  end
  return false
 end
 if finish()then return end
 for _,opener in pairs(FindAllOf('BP_MenuOpener_C')or {})do
  if is_valid(opener)and not safe_full_name(opener):find('Default__',1,true)then
   opener:TogglePauseMenu()
   pcl15179_schedule(1,function()if not finish()then pcl151762_status(state,'Main menu control is unavailable. Use the pause menu to return.')end end)
   return
  end
 end
 error('Native menu controller is unavailable')
end
function pcl151762_dispatch(action)
    if not action.kind or action.kind:sub(1,5)~='home_'then return false end
    local state=action.home_state or PCL151762_HOME
    if not state or state~=PCL151762_HOME then return true end
    local ok,err=pcall(function()
        pcl151762_context(state)
        local kind=action.kind
        if kind=='home_folder_tab'then PCL_FOLDER_TABS.select(action.tab_id,state);pcl151762_controls(state);return end
        if kind=='home_exit'then pcl151762_exit_to_main(state);return end
        if kind=='home_close'then pcl151762_close(state);return end
        if kind=='home_libraries'then pcl151762_open(state,state.last_library_view or 'all');return end
        if kind=='home_multi_delete'then
            assert(not state.busy and not PCL151762_IMPORT,'Finish the current operation first')
            if state.open and state.view~='delete'then
                state.library_selecting=not state.library_selecting;state.selected={};state.confirm=nil;pcl151762_render(state);return
            elseif state.open and state.view=='delete'then
                state.selected={};state.confirm=nil;pcl151762_status(state,'');pcl151762_close(state)
            else
                state.active_tab_id='creative';if state.story_open then pcl151762_close(state)end
                state.selected={};pcl151762_open(state,'delete')
            end
            return
        end
        if not state.open or state.busy then return end
        if kind=='home_all'or kind=='home_parts' or kind=='home_blades'then pcl151762_mode(state,kind=='home_all'and 'all'or(kind=='home_parts'and 'parts'or 'blades'))
        elseif kind=='home_copy'then
            pcl151726_slot(action.code);local args={#action.code};for i=1,#action.code do args[#args+1]=action.code:byte(i)end
            assert(pcl151726_bridge().copy_word(table.unpack(args))==1,'Clipboard is busy; try again.');pcl151762_status(state,'Magic Word copied.')
        elseif kind=='home_previous' or kind=='home_next'then if not state.confirm then state.page=state.page+(kind=='home_next'and 1 or -1);pcl151762_render(state)end
        elseif kind=='home_select'then
            if not state.confirm then assert(is_valid(action.piece)and ((action.library and state.library_selecting and state.piece_entries[action.piece:GetAddress()]and (state.piece_entries[action.piece:GetAddress()].mode..':'..state.piece_entries[action.piece:GetAddress()].code)==action.id)or(not action.library and action.piece:GetAddress()==action.id)),'Selected entry changed');state.selected[action.id]=not state.selected[action.id]or nil;pcl151762_controls(state)end
        elseif kind=='home_select_all'then if not state.confirm then for _,item in ipairs(state.library_selecting and state.library_items or state.inventory or {})do state.selected[item.id]=true end;pcl151762_controls(state)end
        elseif kind=='home_clear'then if not state.confirm then state.selected={};pcl151762_controls(state)end
        elseif kind=='home_delete'then if state.library_selecting then pcl151762_library_delete(state)elseif state.confirm then pcl151762_commit_delete(state)else pcl151762_review_delete(state)end
        elseif kind=='home_cancel_confirm'then state.confirm=nil;pcl151762_status(state,'');pcl151762_controls(state)
        elseif kind=='home_import_form'then if not PCL151762_IMPORT then state.form:SetVisibility(0);state.input:SetText(pcl15171_to_text(''));state.input:SetKeyboardFocus()end
        elseif kind=='home_cancel_import'then state.form:SetVisibility(1)
        elseif kind=='home_submit'then pcl151762_start_import(state,pcl15171_from_text(state.input:GetText()))end
    end)
    if not ok then pcl151762_status(state,tostring(err))end
    return true
end
pcall(function()
    RegisterHook('/Script/Bladesong.UWCreativeMode:OnPieceDownloadFailed',function(context)
        local request=PCL151762_IMPORT;local widget=pcl15171_unwrap(context)
        if request and is_valid(widget) and widget:GetAddress()==request.service:GetAddress()then request.bridge.failed(widget:GetAddress());request.failed=true end
    end,function()end)
end)

-- Reuse the game's UItemsControl and its native Creative card template.
function pcl151762_class(widget,name)
    local class=StaticFindObject('/Script/UMG.'..name)
    return is_valid(widget) and is_valid(class) and widget:IsA(class)
end
function pcl151762_margin(value)
    return {Left=value.Left,Top=value.Top,Right=value.Right,Bottom=value.Bottom}
end
function pcl151762_slot_spec(widget)
    local parent=widget:GetParent();assert(is_valid(parent),'Native button parent unavailable')
    local slot=widget.Slot;local spec={parent=parent}
    if pcl151762_class(parent,'CanvasPanel')then
        spec.kind='canvas';local a=slot:GetAnchors();local align=slot:GetAlignment()
        spec.anchors={Minimum={X=a.Minimum.X,Y=a.Minimum.Y},Maximum={X=a.Maximum.X,Y=a.Maximum.Y}}
        spec.offsets=pcl151762_margin(slot:GetOffsets());spec.alignment={X=align.X,Y=align.Y};spec.auto=slot:GetAutoSize();spec.z=slot:GetZOrder()
    elseif pcl151762_class(parent,'ContentWidget')then spec.kind='content'
    else
        for _,entry in ipairs({{'Overlay','overlay'},{'VerticalBox','vertical'},{'HorizontalBox','horizontal'}})do
            if pcl151762_class(parent,entry[1])then spec.kind=entry[2];break end
        end
        assert(spec.kind,'Unsupported native button parent: '..safe_full_name(parent))
        spec.padding=pcl151762_margin(slot.Padding);spec.h=slot.HorizontalAlignment;spec.v=slot.VerticalAlignment
        if spec.kind~='overlay'then spec.size={Value=slot.Size.Value,SizeRule=slot.Size.SizeRule}end
    end
    return spec
end
function pcl151762_attach_slot(widget,spec)
    local parent=spec.parent;local slot
    if spec.kind=='content'then parent:SetContent(widget);return end
    if spec.kind=='canvas'then
        slot=parent:AddChildToCanvas(widget);slot:SetAnchors(spec.anchors);slot:SetOffsets(spec.offsets);slot:SetAlignment(spec.alignment);slot:SetAutoSize(spec.auto);slot:SetZOrder(spec.z);return
    elseif spec.kind=='overlay'then slot=parent:AddChildToOverlay(widget)
    elseif spec.kind=='vertical'then slot=parent:AddChildToVerticalBox(widget)
    else slot=parent:AddChildToHorizontalBox(widget)end
    slot:SetPadding(spec.padding);slot:SetHorizontalAlignment(spec.h);slot:SetVerticalAlignment(spec.v)
    if spec.size then slot:SetSize(spec.size)end
end
function pcl151762_swap_button(original,replacement)
    local spec=pcl151762_slot_spec(original)
    original:RemoveFromParent();pcl151762_attach_slot(replacement,spec)
    return {original=original,replacement=replacement,spec=spec}
end
function pcl151762_restore_swap(swap)
    if not swap then return end
    if is_valid(swap.replacement)then swap.replacement:RemoveFromParent()end
    if is_valid(swap.original) and is_valid(swap.spec.parent)then pcl151762_attach_slot(swap.original,swap.spec)end
end
function pcl151762_context(state)
    assert(state and PCL151762_HOME==state and pcl151762_visible(state.home),'Creative screen changed')
    local utils=StaticFindObject('/Script/Bladesong.Default__BladesongUtils');assert(is_valid(utils),'Game utilities unavailable')
    local gm,gs=utils:GetBladesongGameMode(state.home),utils:GetBladesongGameState(state.home)
    assert(is_valid(gm) and gm:IsCreativeMode() and is_valid(gs) and is_valid(gs.PieceInventory),'Open Creative mode first')
    local bound=state.home.PieceItemsCollection.BoundCollection
    local original=gs.PieceInventory
    assert(is_valid(bound) and (bound:GetAddress()==original:GetAddress() or (state.story_open and is_valid(gs.RecentStoryModeSwordsInventory)and bound:GetAddress()==gs.RecentStoryModeSwordsInventory:GetAddress())or (is_valid(state.library_collection) and bound:GetAddress()==state.library_collection:GetAddress())),'Creative inventory binding changed')
    assert(not is_valid(gs.RecentStoryModeSwordsInventory) or original:GetAddress()~=gs.RecentStoryModeSwordsInventory:GetAddress(),'Story inventory is excluded')
    return gs,original,gm,utils
end
function pcl151762_restore_cards(state)
    state.card_patch_key=nil
    for _,entry in ipairs(state.native_cards or {})do
        pcall(pcl151762_restore_swap,entry.swap)
        pcall(function()if is_valid(entry.remove)then entry.remove:SetIsInteractionEnabled(entry.remove_interaction)end end)
        pcall(function()if is_valid(entry.button)then entry.button.bApplyAlphaOnDisable=entry.apply_alpha;entry.button:SetIsInteractionEnabled(entry.interaction);entry.button:SetIsFocusable(entry.focusable);entry.button:SetRenderOpacity(entry.opacity or 1)end end)
    end
    pcl151762_forget_buttons(state.row_buttons);state.row_buttons={};state.native_cards={};state.selection_buttons={}
end
function pcl151762_patch_cards(state)
    if not state.open or state.patching then return end
    local control=state.home.PieceItemsCollection
    local identity={state.view,tostring(state.library_selecting)}
    for i=0,control.ItemPanel:GetChildrenCount()-1 do
     local view=control:GetChildAt(i);local piece=is_valid(view)and view.BoundPiece
     identity[#identity+1]=is_valid(view)and tostring(view:GetAddress())or '?'
     identity[#identity+1]=is_valid(piece)and tostring(piece:GetAddress())or '?'
    end
    local patch_key=table.concat(identity,':')
    if state.card_patch_key==patch_key then return end
    state.patching=true
    local ok,err=pcall(function()
        pcl151762_restore_cards(state)
        state.rendering_rows=true
        local models=state.home.PieceItemsCollection.InstantiatedViewModels
        local key_by_view={}
        models:ForEach(function(key,value)
            local view=pcl151114_unwrap(value)
            if is_valid(view)then key_by_view[view:GetAddress()]=pcl151114_unwrap(key)end
        end)
        -- The map can retain detached models from the previous collection.
        -- Only the views actually displayed by the existing ItemPanel are cards.
        local control=state.home.PieceItemsCollection
        for index=0,control.ItemPanel:GetChildrenCount()-1 do
            local view=control:GetChildAt(index)
            local piece=is_valid(view)and view.BoundPiece or nil
            local key_piece=is_valid(view)and key_by_view[view:GetAddress()]or nil
            if not is_valid(piece)then piece=key_piece end
            assert(is_valid(piece)and is_valid(view),'Native card data unavailable')
            local button,remove=view.Button,view.RemoveButton
            assert(is_valid(button)and is_valid(remove),'Native Creative card controls unavailable')
            local code=state.piece_codes and (state.piece_codes[piece:GetAddress()]or (is_valid(key_piece)and state.piece_codes[key_piece:GetAddress()]))
            local record={code=code,piece=piece,button=button,apply_alpha=button.bApplyAlphaOnDisable,opacity=button:GetRenderOpacity(),interaction=button:IsInteractionEnabled(),focusable=button:GetIsFocusable(),view=view,remove=remove,remove_interaction=remove:IsInteractionEnabled()}
            state.native_cards[#state.native_cards+1]=record
            button.bApplyAlphaOnDisable=false;button:SetIsInteractionEnabled(false);button:SetIsFocusable(false);button:SetRenderOpacity(1);remove:SetIsInteractionEnabled(false)
        end
        -- Disable every stock card action before replacing individual controls.
        -- A layout mismatch must leave the entire library unable to open Forge.
        for _,record in ipairs(state.native_cards)do
            local id=record.piece:GetAddress();local code=record.code
            local replacement
            if state.view=='delete'or state.library_selecting then
                if state.library_selecting then local entry=state.piece_entries[record.piece:GetAddress()];id=entry.mode..':'..entry.code end
                replacement=pcl151762_button(state,nil,'[ ] Select','home_select',{id=id,piece=record.piece,library=state.library_selecting});state.selection_buttons[id]=replacement
            else
                assert(code,'Unknown library card data for '..safe_full_name(record.piece))
                state.view_codes=state.view_codes or {};state.view_codes[record.view:GetAddress()]=code
                replacement=pcl151762_button(state,nil,'Copy Magic Word','home_copy',{code=code})
                local preview=(state.piece_previews and state.piece_previews[record.piece:GetAddress()])or PCL151724_PREVIEWS[code]
                if preview and is_valid(preview.texture)and is_valid(record.view.Image)then
                    record.view.Image:SetVisibility(0);record.view.Image:SetBrushFromTexture(preview.texture,true);pcl151751_image_tooltip(state.panel,record.view.Image,preview.texture)
                end
            end
            record.swap=pcl151762_swap_button(record.remove,replacement)
        end
        state.rendering_rows=false;pcl151762_controls(state)
    end)
    state.rendering_rows=false;state.patching=false
    if ok then state.card_patch_key=patch_key else pcl151762_status(state,'Card update stopped: '..tostring(err))end
end
function pcl151762_controls(state)
    local deleting=state.open and (state.view=='delete'or state.library_selecting);local locked=state.busy or state.confirm~=nil
    for _,button in ipairs({state.all,state.parts,state.blades})do pcl151762_action_visibility(state,button,state.open and not deleting and not state.story_open and 0 or 1);button:SetIsEnabled(not PCL151762_IMPORT and not locked)end
    for _,button in ipairs({state.select_all,state.clear,state.remove})do pcl151762_action_visibility(state,button,deleting and 0 or 1);button:SetIsEnabled(not locked)end
    pcl151762_action_visibility(state,state.cancel_confirm,deleting and state.confirm and 0 or 1)
    if is_valid(state.tools)then state.tools:SetVisibility(state.open and 0 or 1)end
    local n=pcl151762_selected_count(state)
    pcl151762_action_caption(state,state.remove,state.confirm and ('Confirm delete '..n)or ('Delete selected ('..n..')'))
    state.remove:SetIsEnabled(not state.busy and n>0)
    if is_valid(state.exit_button)then state.exit_button:SetIsEnabled(not locked and not PCL151762_IMPORT)end
    state.close:SetIsEnabled(not state.busy);if is_valid(state.nav_library)then state.nav_library:SetIsEnabled(not locked and not PCL151762_IMPORT)end
    pcl151762_action_opacity(state,state.close,(not state.open or deleting)and 1 or .40)
    pcl151762_action_opacity(state,state.nav_library,state.open and not deleting and 1 or .40)
    state.tab_opacity_dirty=true
    if is_valid(state.all)then pcl151762_action_opacity(state,state.all,state.view=='all'and 1 or .40)end
    pcl151762_action_opacity(state,state.parts,state.view=='parts'and 1 or .40);pcl151762_action_opacity(state,state.blades,state.view=='blades'and 1 or .40)
    pcl151762_magic_footer_visibility(state)
    state.nav_delete:SetIsEnabled(not state.busy and not PCL151762_IMPORT and not state.story_open)
    for _,stroke in ipairs(state.trash_strokes or {})do stroke:SetVisibility(deleting and 1 or 3)end
    for _,stroke in ipairs(state.cancel_strokes or {})do stroke:SetVisibility(deleting and 3 or 1)end
    state.nav_delete:SetToolTipText(pcl15171_to_text(''))
    pcl151762_action_opacity(state,state.nav_delete,state.story_open and .40 or 1)
    pcl151762_update_folder_tabs(state)
    if is_valid(state.import_submit)then state.import_submit:SetIsEnabled(not locked and not PCL151762_IMPORT)end
    for id,button in pairs(state.selection_buttons or {})do button:SetCaption(pcl15171_to_text(state.selected[id]and '[x] Selected'or '[ ] Select'));button:SetIsEnabled(not locked)end
end
function pcl151762_native_view(state,show)
    if show then
        if state.download_face then state.download_face.widget:SetVisibility(0);state.download_face.label:SetText(pcl15171_to_text('Conjure'))end
        if state.story_open then state.story_open=false;state.home.PieceItemsCollection.ItemTemplate=state.creative_template end
        pcl151762_restore_cards(state)
        if is_valid(state.original_collection)then state.home.PieceItemsCollection:Bind(state.original_collection)end
        pcl151762_restore_swap(state.import_swap);state.import_swap=nil
        if state.download_interaction~=nil then state.home.DownloadButton:SetIsInteractionEnabled(state.download_interaction);state.home.DownloadButton:SetIsFocusable(state.download_focusable)end
        if is_valid(state.import_submit)then state.import_submit:RemoveFromParent();state.import_submit:SetVisibility(1)end
        for name,visibility in pairs(state.native_visibility or {})do local widget=state.home[name];if is_valid(widget)then widget:SetVisibility(visibility)end end
        if state.original_heading then state.heading:SetText(state.original_heading)end
    else
        if state.download_face then state.download_face.widget:SetVisibility(0);if state.view=='delete'then state.download_face.label:SetText(pcl15171_to_text('Conjure'))end end
        if state.view=='delete'and state.import_swap then pcl151762_restore_swap(state.import_swap);state.import_swap=nil;state.import_submit:SetVisibility(1)end
        for _,name in ipairs({'DownloadButton','MagicWordTextBox'})do
            local widget=state.home[name]
            if is_valid(widget)then
                if state.native_visibility[name]==nil then state.native_visibility[name]=widget:GetVisibility()end
                widget:SetVisibility(state.native_visibility[name])
                if state.view=='delete'and name=='DownloadButton'and state.download_interaction~=nil then widget:SetIsInteractionEnabled(state.download_interaction);widget:SetIsFocusable(state.download_focusable)end
            end
        end
        if state.view~='delete' and not state.import_swap then
            if state.download_interaction==nil then state.download_interaction=state.home.DownloadButton:IsInteractionEnabled();state.download_focusable=state.home.DownloadButton:GetIsFocusable()end
            state.home.DownloadButton:SetIsInteractionEnabled(false);state.home.DownloadButton:SetIsFocusable(false)
            state.import_submit=pcl151762_button(state,nil,'Add to library','home_submit');pcl151762_remove_native_chrome(state.import_submit)
            if state.download_face then state.import_submit:SetRenderOpacity(.001);state.download_face.label:SetText(pcl15171_to_text('Add to library'))end
            state.import_swap=pcl151762_swap_button(state.home.DownloadButton,state.import_submit)
        end
    end
end
function pcl151762_render(state)
    pcl151762_restore_cards(state)
    local _,original=pcl151762_context(state);state.original_collection=original
    local control=state.home.PieceItemsCollection
    if state.view=='delete'then
        state.inventory,state.fingerprint=pcl151762_snapshot(state)
        state.heading:SetText(pcl15171_to_text('CREATIVE MODE SWORDS / MULTI-DELETE'))
        control:Bind(original)
    else
        local entries=pcl151762_display_entries(state)
        local fingerprint={};for _,entry in ipairs(entries)do fingerprint[#fingerprint+1]=entry.mode..':'..#entry.code..':'..entry.code..':'..#entry.name..':'..entry.name end
        fingerprint=table.concat(fingerprint,'\n')
        state.collection_cache=state.collection_cache or {};local cached=state.collection_cache[state.view]
        if cached and cached.fingerprint==fingerprint and is_valid(cached.collection)then
         state.library_collection=cached.collection;state.piece_codes=cached.codes;state.view_codes={};state.piece_entries=cached.entries;state.library_items=cached.items;state.piece_previews=cached.previews
        else
         local collection=StaticConstructObject(StaticFindObject('/Script/Bladesong.ObservableCollection'),state.home);pcl151731_fresh(collection)
         assert(is_valid(collection),'Library display collection unavailable')
         local piececlass=StaticFindObject('/Script/Bladesong.Piece');assert(is_valid(piececlass),'Library display data unavailable')
         state.piece_codes={};state.view_codes={};state.piece_previews={};state.piece_entries={};state.library_items={};state.library_collection=collection
         for _,entry in ipairs(entries)do
          local code=entry.code;local piece=StaticConstructObject(piececlass,collection);pcl151731_fresh(piece);assert(is_valid(piece),'Library display entry unavailable')
          piece.Name=pcl15171_to_text(entry.name);state.piece_codes[piece:GetAddress()]=code;state.piece_entries[piece:GetAddress()]=entry
          state.library_items[#state.library_items+1]={id=entry.mode..':'..code,code=code,mode=entry.mode};state.piece_previews[piece:GetAddress()]=entry.preview
          collection:AddObject(piece)
         end
         state.collection_cache[state.view]={fingerprint=fingerprint,collection=collection,codes=state.piece_codes,entries=state.piece_entries,items=state.library_items,previews=state.piece_previews}
        end
        for address,entry in pairs(state.piece_entries)do
         state.piece_previews[address]=state.preview_cache and state.preview_cache[entry.mode]and state.preview_cache[entry.mode][entry.code]or entry.preview
        end
        pcl151762_queue_previews(state,entries)
        state.heading:SetText(pcl15171_to_text('PRECONSTRUCTION LIBRARY / '..state.view:upper()))
        state.patching=true
        local bound,why=pcall(function()control:Bind(state.library_collection)end)
        state.patching=false;assert(bound,why)
    end
    pcl151762_patch_cards(state);pcl151762_controls(state)
    pcl15179_schedule(1,function()if PCL151762_HOME==state then pcl151762_refresh_native_images(state)end end)
end
function pcl151762_open(state,mode)
    local started=os.clock()
    if state.story_open then pcl151762_close(state)end
    pcl151762_context(state);state.open=true
    if PCL151762_IMPORT then mode=PCL151762_IMPORT.mode else pcl151762_mode(state,mode)end
    pcl151762_native_view(state,false);pcl151762_input(state,true)
    log('BMF_LIBRARY_OPEN_MS '..math.floor((os.clock()-started)*1000)..' view='..tostring(state.view))
end
function pcl151762_close(state)
    if state.busy then return end
    state.open=false;state.confirm=nil;state.library_selecting=nil;state.selected={};pcl151762_native_view(state,true);state.form:SetVisibility(1);pcl151762_controls(state);pcl151762_input(state,false)
end
function pcl151762_create_home(home)
    local toolbar=pcl15171_create_widget(home,PCL15171_ENTRY_CLASS_OBJ);assert(is_valid(toolbar),'Creative toolbar unavailable')
    local reference={LeaveForgeModeButton=home.DownloadButton,AbilityHistoryPlaceholderText=home.PieceItemsCollectionHeadline}
    assert(is_valid(reference.LeaveForgeModeButton)and is_valid(reference.AbilityHistoryPlaceholderText),'Creative styles unavailable')
    local state={home=home,catalogue=home,panel=home,toolbar=toolbar,buttons={},row_buttons={},selected={},native_cards={},native_visibility={},view=PCL151761_MODE,open=false}
    PCL151762_HOME=state;PCL151723_UI[home:GetAddress()]={reference=reference,controls={}}
    state.heading=home.PieceItemsCollectionHeadline;state.original_heading=state.heading:GetText();state.input=home.MagicWordTextBox
    local root=pcl15171_widget_by_name(toolbar,'PCL_EntryRoot');root:SetWidthOverride(1200);root:SetMaxDesiredWidth(1200)
    local body=pcl151723_new(home,'VerticalBox');root:SetContent(body)
    local navigation=pcl151723_new(home,'CanvasPanel')
    state.folder_tabs={}
    local tab_width=0
    for _,definition in ipairs(PCL_FOLDER_TABS.list())do
        local button=pcl151762_folder_tab(state,navigation,definition.label,'home_folder_tab',tab_width,definition)
        if definition.id=='creative'then state.close=button elseif definition.id=='preconstruction'then state.nav_library=button end
        tab_width=tab_width+definition.width
    end
    root:SetWidthOverride(tab_width);root:SetMaxDesiredWidth(tab_width)
    pcl151762_create_delete_action(state)
    local tabbox=pcl151723_new(home,'SizeBox');tabbox:SetHeightOverride(80);tabbox:SetContent(navigation)
    pcl151723_vadd(body,tabbox,0,0)
    local controls=pcl151723_new(home,'HorizontalBox')
    state.all=pcl151762_outline_action(state,controls,'All','home_all',180)
    state.parts=pcl151762_outline_action(state,controls,'Parts','home_parts',180);state.blades=pcl151762_outline_action(state,controls,'Blades','home_blades',180)
    state.select_all=pcl151762_outline_action(state,controls,'Select all','home_select_all',210);state.clear=pcl151762_outline_action(state,controls,'Clear selection','home_clear',260)
    state.remove=pcl151762_outline_action(state,controls,'Delete selected (0)','home_delete',340);state.cancel_confirm=pcl151762_outline_action(state,controls,'Cancel review','home_cancel_confirm',260)
    local tools=pcl15171_create_widget(home,PCL15171_ENTRY_CLASS_OBJ);state.tools=tools
    local toolsroot=pcl15171_widget_by_name(tools,'PCL_EntryRoot');toolsroot:SetWidthOverride(1200);toolsroot:SetMaxDesiredWidth(1200)
    local toolsbody=pcl151723_new(home,'VerticalBox');toolsroot:SetContent(toolsbody)
    pcl151723_vadd(toolsbody,controls,0,4)
    state.message=pcl151723_label(home,'',20,false);pcl151723_vadd(toolsbody,state.message,0,0)
    state.form=pcl151723_label(home,'Enter a Magic Word in the existing field below, then choose Add to library.',20,false);state.form:SetVisibility(1);pcl151723_vadd(toolsbody,state.form,0,0)
    state.hidden=pcl151723_new(home,'VerticalBox');state.hidden:SetVisibility(1);pcl151723_vadd(body,state.hidden,0,0)
    tools:SetVisibility(1)
    state.heading_opacity=state.heading:GetRenderOpacity();state.heading_visibility=state.heading:GetVisibility();state.heading:SetVisibility(2)
    toolbar:AddToViewport(91);toolbar:SetDesiredSizeInViewport({X=1200,Y=84});toolbar:SetPositionInViewport({X=0,Y=0},false);toolbar:SetAnchorsInViewport({Minimum={X=.10,Y=.035},Maximum={X=.10,Y=.035}});toolbar:SetAlignmentInViewport({X=0,Y=0})
    pcl151762_controls(state);pcl151762_mount_folder_tabs(state);pcall(pcl151762_align_toolbar,state)
    if BMF_CREATIVE_HAS_PROVIDER then
     pcl15179_schedule(1,function()
      if PCL151762_HOME~=state then return end
      local view=state.view;state.view='all';local entries=pcl151762_display_entries(state);state.view=view
      pcl151762_queue_previews(state,entries)
     end)
    end
    log('PCL15_17_62_CREATIVE_TOOLS_READY native_grid=true separate_library_collection=true story_unchanged=true')
    return state
end
function pcl151762_cleanup_home()
    local state=PCL151762_HOME;if not state then return end
    local request=PCL151762_IMPORT
    if request and request.state==state then request.bridge.cancel();PCL151762_IMPORT=nil end
    state.open=false;pcall(pcl151762_native_view,state,true);pcall(pcl151762_input,state,nil)
    pcl151762_restore_home_layout(state)
    pcl151762_forget_buttons(state.buttons);pcl151762_forget_buttons(state.row_buttons)
    if is_valid(state.toolbar)then state.toolbar:RemoveFromParent()end
    if is_valid(state.section_heading)then state.section_heading:SetVisibility(state.section_heading_visibility or 0)end
    if state.section_layout and is_valid(state.section_layout.widget)then
        local entry=state.section_layout
        if entry.spec.padding then entry.widget.Slot:SetPadding(entry.spec.padding);if entry.spec.size then entry.widget.Slot:SetSize(entry.spec.size)end elseif entry.spec.kind=='canvas'then entry.widget.Slot:SetAnchors(entry.spec.anchors);entry.widget.Slot:SetOffsets(entry.spec.offsets)end
    end
    if state.search_swap then
        if is_valid(state.search_swap.original)then state.search_swap.original:RemoveFromParent()end
        pcall(pcl151762_restore_swap,state.search_swap)
    end
    if state.frame_content and state.frame_swap and is_valid(state.frame_swap.original)then
        state.frame_content:RemoveFromParent();state.frame_swap.original:SetContent(state.frame_content)
    end
    if state.frame_swap then
        if is_valid(state.frame_swap.original)then state.frame_swap.original:RemoveFromParent()end
        pcall(pcl151762_restore_swap,state.frame_swap)
    end
    if is_valid(state.tools)then state.tools:RemoveFromParent()end
    if is_valid(state.delete_toolbar)then state.delete_toolbar:RemoveFromParent()end
    if is_valid(state.heading)then state.heading:SetRenderOpacity(state.heading_opacity or 1);state.heading:SetVisibility(state.heading_visibility or 0)end
    PCL151723_UI[state.home:GetAddress()]=nil;PCL151762_HOME=nil
end
function pcl151762_native_changed(context)
    local state=PCL151762_HOME;if not state or not state.open or state.patching then return end
    local control=pcl15171_unwrap(context)
    if is_valid(control)and control:GetAddress()==state.home.PieceItemsCollection:GetAddress()then pcl151762_patch_cards(state)end
end
function pcl151762_install_native_grid_hooks()
for _,path in ipairs({'/Script/Bladesong.ItemsControl:OnBound','/Script/Bladesong.UWPieceInventory:SetFilter'})do
    local ok,err=pcall(function()RegisterHook(path,function()end,pcl151762_native_changed)end)
    log('PCL15_17_62_NATIVE_GRID_HOOK path='..path..' installed='..tostring(ok)..(not ok and (' error='..tostring(err))or ''))
end
end
pcl151762_install_native_grid_hooks()

function pcl151762_refresh_native_images(state)
    if not state or not state.open or state.view=='delete'then return end
    state.home.PieceItemsCollection.InstantiatedViewModels:ForEach(function(_,value)
        local view=pcl151114_unwrap(value);local piece=is_valid(view)and view.BoundPiece or nil
        if not is_valid(piece)then return end
        local code=(state.piece_codes and state.piece_codes[piece:GetAddress()])or (state.view_codes and state.view_codes[view:GetAddress()])
        local preview=(is_valid(piece)and state.piece_previews and state.piece_previews[piece:GetAddress()])or(code and PCL151724_PREVIEWS[code])
        if preview and is_valid(preview.texture)and is_valid(view.Image)then view.Image:SetVisibility(0);view.Image:SetBrushFromTexture(preview.texture,true)end
    end)
end
pcall(function()
    RegisterHook('/Script/Bladesong.ViewModel:NotifyChanged',function()end,function(context)
        local state=PCL151762_HOME
        if state and state.open and state.view~='delete'then
            local view=pcl151114_unwrap(context);local piece=is_valid(view)and view.BoundPiece or nil
            local code=(is_valid(piece)and state.piece_codes and state.piece_codes[piece:GetAddress()])or (is_valid(view)and state.view_codes and state.view_codes[view:GetAddress()])
            local preview=(is_valid(piece)and state.piece_previews and state.piece_previews[piece:GetAddress()])or(code and PCL151724_PREVIEWS[code])
            if preview and is_valid(preview.texture)and is_valid(view.Image)then view.Image:SetVisibility(0);view.Image:SetBrushFromTexture(preview.texture,true)end
        end
    end)
end)

-- Follow the existing menu heading instead of floating at the top of the screen.
function pcl151762_align_toolbar(state)
    state.heading:SetVisibility(2)
    pcl151762_position_forge(state)
    if is_valid(state.section_heading)then state.section_heading:SetVisibility(1)end
end

-- Folder lips share the native panel's upper rule. Only the selected lip opens
-- into the panel; the others retain a bottom rule and sit eighteen units lower.
function pcl151762_tab_rect(state,parent,x,y,w,h,color,angle)
    local rect=pcl151723_new(state.home,'Border');rect:SetBrushColor(color);rect:SetVisibility(3)
    if state.forge_canvas and parent==state.forge_canvas then
        local list=color.R<.05 and state.forge_faces or state.forge_rules;list[#list+1]=rect
    end
    local slot=parent:AddChildToCanvas(rect);slot:SetPosition({X=x,Y=y});slot:SetSize({X=w,Y=h})
    if angle then rect:SetRenderTransformPivot({X=0,Y=0});rect:SetRenderTransformAngle(angle)end
    return rect,slot
end
function pcl151762_folder_tab(state,parent,caption,kind,x,definition)
    local width=definition and definition.width or 400
    local canvas=pcl151723_new(state.home,'CanvasPanel');local slot=parent:AddChildToCanvas(canvas)
    slot:SetPosition({X=x,Y=18});slot:SetSize({X=width,Y=62})
    local bg={R=.008,G=.008,B=.006,A=1};local edge={R=.20,G=.19,B=.13,A=1}
    -- Fill the entire chamfered cap, including the triangles under both slopes.
    for y=0,18,2 do pcl151762_tab_rect(state,canvas,20-y,y,width-40+2*y,2,bg)end
    local fill,fill_slot=pcl151762_tab_rect(state,canvas,0,20,width,42,bg)
    pcl151762_tab_rect(state,canvas,20,0,width-40,2,edge)
    pcl151762_tab_rect(state,canvas,0,20,29,2,edge,-45)
    pcl151762_tab_rect(state,canvas,width-20,0,29,2,edge,45)
    local left,left_slot=pcl151762_tab_rect(state,canvas,0,20,2,42,edge)
    local right,right_slot=pcl151762_tab_rect(state,canvas,width-2,20,2,42,edge)
    local bottom,bottom_slot=pcl151762_tab_rect(state,canvas,0,60,width,2,edge)
    local button,visual=pcl151762_visual_action(state,caption,kind,definition and {tab_id=definition.id}or nil)
    state.action_visuals[button:GetAddress()].folder_tab=true
    local button_slot=canvas:AddChildToCanvas(visual);button_slot:SetPosition({X=0,Y=0});button_slot:SetSize({X=width,Y=62})
    state.folder_tabs[#state.folder_tabs+1]={kind=kind,id=definition and definition.id,width=width,x=x,slot=slot,fill=fill_slot,left=left_slot,right=right_slot,bottom=bottom,bottom_slot=bottom_slot,button=button,button_slot=button_slot}
    return button
end
function pcl151762_update_folder_tabs(state)
    local active=(not state.open or state.view=='delete')and 'home_close'or 'home_libraries'
    for _,tab in ipairs(state.folder_tabs or {})do
        local selected=tab.id and PCL_FOLDER_TABS.is_active(tab.id,state)or(not tab.id and tab.kind==active)
        local hovered=is_valid(tab.button)and tab.button:IsHovered()
        local height=selected and 80 or(hovered and 64 or 54);local width=tab.width or 400
        if state.tab_opacity_dirty or tab.drawn_height~=height or tab.drawn_selected~=selected then
            tab.drawn_height=height;tab.drawn_selected=selected
            tab.slot:SetPosition({X=tab.x or(tab.kind=='home_close'and 0 or(tab.kind=='home_libraries'and 400 or 800)),Y=80-height})
            tab.slot:SetSize({X=width,Y=height})
            tab.fill:SetSize({X=width,Y=height-18});tab.left:SetSize({X=2,Y=height-20});tab.right:SetSize({X=2,Y=height-20})
            tab.bottom_slot:SetPosition({X=0,Y=height-2});tab.bottom:SetVisibility(selected and 1 or 3)
            tab.button_slot:SetPosition({X=0,Y=0});tab.button_slot:SetSize({X=width,Y=height})
            pcl151762_action_opacity(state,tab.button,selected and 1 or(hovered and .70 or .40))
        end
    end
    state.tab_opacity_dirty=false
end

function pcl151762_create_delete_action(state)
    local widget=pcl15171_create_widget(state.home,PCL15171_ENTRY_CLASS_OBJ);state.delete_toolbar=widget
    local root=pcl15171_widget_by_name(widget,'PCL_EntryRoot');root:SetWidthOverride(84);root:SetMaxDesiredWidth(84);root:SetHeightOverride(80)
    local canvas=pcl151723_new(state.home,'CanvasPanel');root:SetContent(canvas)
    state.nav_delete=pcl151762_text_action(state,nil,'','home_multi_delete');state.nav_delete:SetToolTipText(pcl15171_to_text(''))
    local hit=canvas:AddChildToCanvas(state.action_visuals[state.nav_delete:GetAddress()].widget);hit:SetPosition({X=0,Y=24});hit:SetSize({X=84,Y=56})
    local bg={R=.008,G=.008,B=.006,A=1};local edge={R=.20,G=.19,B=.13,A=1};local ink={R=.56,G=.51,B=.35,A=1}
    -- Decorative, non-interactive strokes stay above the transparent native hit area.
    pcl151762_tab_rect(state,canvas,12,24,60,2,edge);pcl151762_tab_rect(state,canvas,0,36,17,2,edge,-45);pcl151762_tab_rect(state,canvas,72,24,17,2,edge,45)
    pcl151762_tab_rect(state,canvas,0,36,2,44,edge);pcl151762_tab_rect(state,canvas,82,36,2,44,edge)
    state.trash_strokes={};state.cancel_strokes={}
    for _,line in ipairs({{28,44,28,2},{35,39,14,2},{35,39,2,6},{47,39,2,6},{31,48,2,21},{51,48,2,21},{31,68,22,2},{38,52,2,12},{44,52,2,12}})do
        state.trash_strokes[#state.trash_strokes+1]=pcl151762_tab_rect(state,canvas,line[1],line[2],line[3],line[4],ink)
    end
    for _,angle in ipairs({45,-45})do
        local stroke=pcl151762_tab_rect(state,canvas,25,54,34,2,ink,angle);stroke:SetRenderTransformPivot({X=.5,Y=.5});stroke:SetVisibility(1);state.cancel_strokes[#state.cancel_strokes+1]=stroke
    end
end

-- Attach the lips to the actual native frame, so viewport scaling or a later
-- native layout pass cannot open a gap between the tabs and the panel.
function pcl151762_mount_folder_tabs(state)
    local frame=state.home.PieceItemsCollection:GetParent()
    for _=1,24 do
        if not is_valid(frame)then break end
        if pcl151762_class(frame,'Border')then break end
        frame=frame:GetParent()
    end
    assert(is_valid(frame)and pcl151762_class(frame,'Border'),'Native library frame unavailable for folder tabs')
    local section=frame:GetOuter():GetOuter()
    if is_valid(section)and is_valid(section.HeadlineText)then
        state.section_heading=section.HeadlineText;state.section_heading_visibility=section.HeadlineText:GetVisibility();section.HeadlineText:SetVisibility(1)
        local spec=pcl151762_slot_spec(section);state.section_layout={widget=section,spec=spec}
        -- Allocate the tab strip upward, keeping the native panel's bottom and
        -- card space. The whole section owns the tab hit region.
        if spec.padding then
            local padding=pcl151762_margin(spec.padding);padding.Top=padding.Top-56
            section.Slot:SetPadding(padding)
        elseif spec.kind=='canvas'then
            local offsets=pcl151762_margin(spec.offsets);offsets.Top=offsets.Top-56
            if spec.anchors.Minimum.Y==spec.anchors.Maximum.Y then offsets.Bottom=offsets.Bottom+56 end
            section.Slot:SetOffsets(offsets)
        end
    end
    local layer=pcl151723_new(state.home,'Overlay');state.forge_layer=layer
    local overlay=pcl151723_new(state.home,'VerticalBox')
    local body=layer:AddChildToOverlay(overlay);body:SetHorizontalAlignment(0);body:SetVerticalAlignment(0)
    state.frame_swap=pcl151762_swap_button(frame,layer)
    state.toolbar:RemoveFromParent()
    local head=pcl151723_new(state.home,'HorizontalBox')
    pcl151723_hadd(head,state.toolbar,false,0);pcl151723_hadd(head,pcl151723_new(state.home,'Spacer'),true,0);pcl151723_hadd(head,state.delete_toolbar,false,0)
    pcl151723_vadd(overlay,head,0,0)
    local content=overlay:AddChildToVerticalBox(frame);content:SetSize({Value=1,SizeRule=1});content:SetHorizontalAlignment(0)
    state.toolbar:SetRenderTranslation({X=0,Y=2})
    state.frame_content=frame:GetContent()
    assert(is_valid(state.frame_content),'Native frame content unavailable')
    state.frame_content:RemoveFromParent()
    local stack=pcl151723_new(state.home,'VerticalBox');frame:SetContent(stack)
    pcl151723_vadd(stack,state.tools,12,8)
    local content_slot=stack:AddChildToVerticalBox(state.frame_content);content_slot:SetSize({Value=1,SizeRule=1});content_slot:SetHorizontalAlignment(0)
    pcl151762_mount_home_footer(state,overlay,stack,section)
    pcl151762_hide_story_sidebar(state)
    log('PCL15_17_62_FOLDER_TABS native_frame_attached=true frame='..safe_full_name(frame))
end

-- Keep real native click events while the visible face contains text only.
function pcl151762_visual_action(state,caption,kind,extra)
    local button=pcl151762_button(state,nil,'',kind,extra);button:SetStyle(pcl151762_transparent_style());pcl151762_remove_native_chrome(button);button:SetRenderOpacity(.001);button:SetMinDimensions(0,44);button:SetToolTipText(pcl15171_to_text(''))
    local visual=pcl151723_new(state.home,'Overlay')
    local hit=visual:AddChildToOverlay(button);hit:SetHorizontalAlignment(0);hit:SetVerticalAlignment(0)
    local label=pcl151723_label(state.home,caption,24,false);label:SetAutoWrapText(false);label:SetJustification(1);label:SetVisibility(3)
    local text=visual:AddChildToOverlay(label);text:SetHorizontalAlignment(2);text:SetVerticalAlignment(2)
    state.action_visuals=state.action_visuals or {};state.action_visuals[button:GetAddress()]={widget=visual,label=label,button=button,rest_opacity=.55}
    label:SetRenderOpacity(.55)
    return button,visual
end
function pcl151762_action_opacity(state,button,opacity)
    if not is_valid(button)then return end
    local visual=state.action_visuals and state.action_visuals[button:GetAddress()]
    if visual then button:SetRenderOpacity(.001);visual.rest_opacity=opacity;visual.hover_opacity=nil;visual.label:SetRenderOpacity(opacity)else button:SetRenderOpacity(opacity)end
end
function pcl151762_text_action(state,parent,caption,kind)
    local button,visual=pcl151762_visual_action(state,caption,kind)
    if parent then
        local box=pcl151723_new(state.home,'SizeBox');box:SetWidthOverride(180);box:SetHeightOverride(44);box:SetContent(visual)
        pcl151723_hadd(parent,box,false,16);state.action_visuals[button:GetAddress()].container=box
    end
    return button
end

function pcl151762_action_visibility(state,button,visibility)
    local face=state.action_visuals and state.action_visuals[button:GetAddress()]
    local target=face and (face.container or face.widget)or button;target:SetVisibility(visibility)
end
function pcl151762_action_caption(state,button,caption)
    button:SetCaption(pcl15171_to_text(caption))
    local face=state.action_visuals and state.action_visuals[button:GetAddress()]
    if face then face.label:SetText(pcl15171_to_text(caption))end
end
function pcl151762_outline_action(state,parent,caption,kind,width)
    local button,visual=pcl151762_visual_action(state,caption,kind)
    local box=pcl151723_new(state.home,'SizeBox');box:SetWidthOverride(width);box:SetHeightOverride(56)
    box:SetContent(pcl151762_input_outline(state,visual,width,56,true));pcl151723_hadd(parent,box,false,12)
    state.action_visuals[button:GetAddress()].container=box
    return button
end

BMF_CREATIVE_LIBRARY_CACHE=assert(loadfile(BMF_CREATIVE_ROOT..'ui/library_cache.lua'))()
function pcl151762_display_entries(state)
 local entries={};local snapshots={}
 for _,mode in ipairs(state.view=='all'and {'parts','blades'}or {state.view})do
  local directory=mode=='blades'and PCL151761_BLADE_DIR or PCL151761_PARTS_DIR
  local list,snapshot=BMF_CREATIVE_LIBRARY_CACHE.entries(mode,directory,mode=='parts'and PCL151761_PARTS_PATH or directory..'library.index')
  snapshots[#snapshots+1]=snapshot
  state.preview_cache=state.preview_cache or {};state.preview_cache[mode]=state.preview_cache[mode]or {}
  for _,entry in ipairs(list)do
   local preview=state.preview_cache[mode][entry.code]
   if not preview and PCL151761_MODE==mode then preview=PCL151724_PREVIEWS[entry.code]end
   if preview and is_valid(preview.texture)then state.preview_cache[mode][entry.code]=preview end
   entries[#entries+1]={code=entry.code,mode=mode,name=entry.name..(state.view=='all'and(mode=='blades'and ' [Blade]'or ' [Parts]')or ''),preview=preview}
  end
 end
 state.library_snapshots=snapshots
 return entries
end
function pcl151762_queue_previews(state,entries)
 state.preview_cache=state.preview_cache or {};state.preview_queued=state.preview_queued or {};state.preview_jobs=state.preview_jobs or {}
 for _,entry in ipairs(entries)do
  local key=entry.mode..':'..entry.code
  local preview=state.preview_cache[entry.mode]and state.preview_cache[entry.mode][entry.code]
  if (not preview or not is_valid(preview.texture))and not state.preview_queued[key]then state.preview_queued[key]=true;state.preview_jobs[#state.preview_jobs+1]=entry end
 end
 if state.preview_loading or #state.preview_jobs==0 then return end;state.preview_loading=true
 local function step()
  if PCL151762_HOME~=state or not pcl151762_visible(state.home)then state.preview_loading=false;return end
  local entry=table.remove(state.preview_jobs,1)
  if not entry then state.preview_loading=false;state.preview_queued={};return end
  local cache=state.preview_cache[entry.mode]or {};state.preview_cache[entry.mode]=cache
  local preview=cache[entry.code]
  if not preview or not is_valid(preview.texture)then
   local names={'PCL151761_MODE','PCL15171_LIBRARY_DIR','PCL15171_LIBRARY_PATH','PCL151724_PREVIEWS'};local saved={}
   for _,name in ipairs(names)do saved[name]=_G[name]end
   PCL151761_MODE=entry.mode;PCL15171_LIBRARY_DIR=entry.mode=='blades'and PCL151761_BLADE_DIR or PCL151761_PARTS_DIR
   PCL15171_LIBRARY_PATH=entry.mode=='parts'and PCL151761_PARTS_PATH or PCL15171_LIBRARY_DIR..'library.index';PCL151724_PREVIEWS=cache
   local started=os.clock()
   local ok,why=pcall(function()if not pcl151727_load_preview(entry.code,state.home)and pcl151726_has_cache(entry.code)then pcl151762_preview_from_cache(entry.code,state.home)end end)
   preview=cache[entry.code]
   for _,name in ipairs(names)do _G[name]=saved[name]end
   if not ok then log('BMF_PREVIEW_LOAD_FAILED '..tostring(why))end
   local elapsed=(os.clock()-started)*1000;if elapsed>20 then log('BMF_PREVIEW_LOAD_MS '..math.floor(elapsed)..' mode='..entry.mode)end
  end
  if preview and is_valid(preview.texture)then
   for address,record in pairs(state.piece_entries or {})do if record.code==entry.code and record.mode==entry.mode then state.piece_previews[address]=preview end end
   for _,record in ipairs(state.native_cards or {})do
    local item=state.piece_entries and state.piece_entries[record.piece:GetAddress()]
    if item and item.code==entry.code and item.mode==entry.mode and is_valid(record.view.Image)then
     record.view.Image:SetBrushFromTexture(preview.texture,true);record.view.Image:SetVisibility(0)
     pcl151751_image_tooltip(state.panel,record.view.Image,preview.texture)
    end
   end
  end
  pcl15179_schedule(16,step)
 end
 pcl15179_schedule(1,step)
end

function pcl151762_show_story(state)
    pcl151762_close(state)
    local gs=pcl151762_context(state);local control=state.home.PieceItemsCollection
    local story=state.home.RecentStoryModeSwordsItemsCollection
    assert(is_valid(story)and is_valid(gs.RecentStoryModeSwordsInventory),'Story swords unavailable')
    state.creative_template=state.creative_template or control.ItemTemplate
    state.original_collection=gs.PieceInventory
    state.story_open=true;control.ItemTemplate=story.ItemTemplate
    control:Bind(gs.RecentStoryModeSwordsInventory)
    pcl151762_controls(state)
end
function pcl151762_hide_story_sidebar(state)
    local story=state.home.RecentStoryModeSwordsItemsCollection
    if not is_valid(story)then return end
    local frame=story:GetParent()
    for _=1,24 do if not is_valid(frame)or pcl151762_class(frame,'Border')then break end;frame=frame:GetParent()end
    if not is_valid(frame)then return end
    local section=frame:GetOuter():GetOuter();if not is_valid(section)or not is_valid(section.HeadlineText)then return end
    local target=section
    while is_valid(target:GetParent())and pcl151762_class(target:GetParent(),'SizeBox')do target=target:GetParent()end
    state.story_sidebar=target;state.story_sidebar_visibility=target:GetVisibility();target:SetVisibility(1)
    local main=state.section_layout and state.section_layout.widget
    if is_valid(main)and is_valid(main:GetParent())and is_valid(target:GetParent())and main:GetParent():GetAddress()==target:GetParent():GetAddress()then
        local spec=state.section_layout.spec
        if spec.kind=='horizontal'then
            main.Slot:SetSize({Value=1,SizeRule=1});state.expanded_main=true
        elseif spec.kind=='canvas'then
            local story_spec=pcl151762_slot_spec(target)
            local anchors={Minimum=spec.anchors.Minimum,Maximum={X=story_spec.anchors.Maximum.X,Y=spec.anchors.Maximum.Y}}
            local offsets=pcl151762_margin(main.Slot:GetOffsets());offsets.Right=story_spec.offsets.Right
            main.Slot:SetAnchors(anchors);main.Slot:SetOffsets(offsets);state.expanded_main=true
        end
    end
    log('PCL15_17_62_STORY_SIDEBAR hidden=true widget='..safe_full_name(target))
end
function pcl151762_footer_move(state,widget,parent,width,height)
    assert(is_valid(widget),'Native footer control unavailable')
    local spec=pcl151762_slot_spec(widget)
    local placeholder=pcl151723_new(state.home,'SizeBox');placeholder:SetHeightOverride(0);placeholder:SetWidthOverride(0)
    widget:RemoveFromParent();pcl151762_attach_slot(placeholder,spec)
    state.footer_moves=state.footer_moves or {};state.footer_moves[#state.footer_moves+1]={original=widget,replacement=placeholder,spec=spec}
    if width then
        local box=pcl151723_new(state.home,'SizeBox');box:SetWidthOverride(width);if height then box:SetHeightOverride(height)end
        if widget:GetAddress()==state.home.DownloadButton:GetAddress()then
            local face=pcl151762_native_text_face(state,widget,'Conjure');state.download_face=face
            box:SetContent(pcl151762_input_outline(state,face.widget,width,height or 64,true))
        elseif widget:GetAddress()==state.home.MagicWordTextBox:GetAddress()or widget:GetAddress()==state.home.FilterText:GetAddress()or widget:GetAddress()==state.home.ClearButton:GetAddress()then
            box:SetContent(pcl151762_input_outline(state,widget,width,height or 64,widget:GetAddress()==state.home.ClearButton:GetAddress()))
        else box:SetContent(widget)end
        if widget:GetAddress()==state.home.DownloadButton:GetAddress()or widget:GetAddress()==state.home.MagicWordTextBox:GetAddress()then
            state.magic_footer_boxes=state.magic_footer_boxes or {};state.magic_footer_boxes[#state.magic_footer_boxes+1]=box
            if widget:GetAddress()==state.home.MagicWordTextBox:GetAddress()then pcl151762_move_magic_tip(state,box)end
        end
        pcl151723_hadd(parent,box,false,12)
    else pcl151723_hadd(parent,widget,false,12)end
    return widget
end
function pcl151762_move_magic_tip(state,fieldbox)
    local anchor=state.home.MagicWordTooltipAnchor
    if not is_valid(anchor)then return end
    state.magic_tip_placement=anchor.Placement;state.magic_tip_visibility=anchor:GetVisibility()
    local placeholder=pcl151723_new(state.home,'SizeBox');placeholder:SetWidthOverride(0);placeholder:SetHeightOverride(0)
    local swap=pcl151762_swap_button(anchor,placeholder);state.footer_moves[#state.footer_moves+1]=swap
    local field=fieldbox:GetContent();field:RemoveFromParent()
    local overlay=pcl151723_new(state.home,'Overlay')
    local content=overlay:AddChildToOverlay(field);content:SetHorizontalAlignment(0);content:SetVerticalAlignment(0)
    local tip=overlay:AddChildToOverlay(anchor);tip:SetHorizontalAlignment(0);tip:SetVerticalAlignment(0)
    anchor:SetVisibility(4);anchor:SetPlacement(5) -- Native right-hand callout, beside the relocated input.
    fieldbox:SetContent(overlay)
end
function pcl151762_magic_footer_visibility(state)
    for _,box in ipairs(state.magic_footer_boxes or {})do box:SetVisibility(state.story_open and 1 or 0)end
    if state.story_open and is_valid(state.home.MagicWordTooltipAnchor)then state.home.MagicWordTooltipAnchor:Close()end
end

function pcl151762_mount_home_footer(state,outer,inside,section)
    local bar=pcl151723_new(state.home,'VerticalBox');state.footer_bar=bar
    local rule=pcl151723_new(state.home,'Border');rule:SetBrushColor({R=.20,G=.19,B=.13,A=1});rule:SetVisibility(3)
    local line=pcl151723_new(state.home,'SizeBox');line:SetHeightOverride(2);line:SetContent(rule);pcl151723_vadd(bar,line,0,0)
    local row=pcl151723_new(state.home,'HorizontalBox')
    local row_area=pcl151723_new(state.home,'Overlay');local row_slot=row_area:AddChildToOverlay(row);row_slot:SetHorizontalAlignment(0);row_slot:SetVerticalAlignment(2)
    row:SetRenderTranslation({X=0,Y=14})
    local row_fill=pcl151723_vadd(bar,row_area,0,0);row_fill:SetSize({Value=1,SizeRule=1})
    pcl151762_style_magic_words(state)
    pcl151762_footer_move(state,state.home.DownloadButton,row,220,64)
    pcl151762_footer_move(state,state.home.MagicWordTextBox,row,560,64)
    local spacer=pcl151723_new(state.home,'Spacer');pcl151723_hadd(row,spacer,true,0)
    pcl151762_footer_move(state,state.home.FilterText,row,320,64)
    state.clear_tooltip=state.home.ClearButton.ToolTipText;state.home.ClearButton:SetToolTipText(pcl15171_to_text(''))
    pcl151762_footer_move(state,state.home.ClearButton,row,64,64)
    local barbox=pcl151723_new(state.home,'SizeBox');barbox:SetHeightOverride(104);barbox:SetContent(bar)
    pcl151723_vadd(inside,barbox,0,0)
    -- Match the requested broad, plain folder lip: a dark field, strong label,
    -- one muted gold outline and clipped lower corners, meeting the footer rule.
    local canvas=pcl151723_new(state.home,'CanvasPanel');local box=pcl151723_new(state.home,'SizeBox');box:SetWidthOverride(1120);box:SetHeightOverride(208);box:SetContent(canvas)
    local reserve=pcl151723_new(state.home,'SizeBox');reserve:SetHeightOverride(208);pcl151723_vadd(outer,reserve,0,0)
    local exit_row=pcl151723_new(state.home,'HorizontalBox');reserve:SetContent(exit_row)
    pcl151723_hadd(exit_row,pcl151723_new(state.home,'Spacer'),true,0)
    state.exit_button=pcl151762_outline_action(state,exit_row,'Close','home_exit',240)
    local exit_box=state.action_visuals[state.exit_button:GetAddress()].container
    exit_box.Slot:SetVerticalAlignment(3);exit_box.Slot:SetPadding({Left=0,Top=0,Right=0,Bottom=12})
    -- Draw and hit-test Forge last, above the frame/footer that it overlaps.
    local lip=state.forge_layer:AddChildToOverlay(box);lip:SetHorizontalAlignment(2);lip:SetVerticalAlignment(3);box:SetRenderTranslation({X=0,Y=-132})
    local native=state.home.ForgeButton;state.forge_opacity=native:GetRenderOpacity();state.forge_style=native:GetStyle():GetClass()
    state.forge_content_visibility=native.Content:GetVisibility();native.Content:SetVisibility(1)
    native:SetStyle(pcl151762_transparent_style());native:SetRenderOpacity(.001)
    local holder=pcl151723_new(state.home,'HorizontalBox');pcl151762_footer_move(state,native,holder)
    native:RemoveFromParent();local hit=canvas:AddChildToCanvas(native);hit:SetPosition({X=0,Y=0});hit:SetSize({X=1120,Y=208})
    state.forge_canvas=canvas;state.forge_faces={};state.forge_rules={}
    local bg={R=.008,G=.008,B=.006,A=1};local edge={R=.20,G=.19,B=.13,A=1}
    pcl151762_tab_rect(state,canvas,0,0,1120,164,bg)
    for inset=0,42,2 do pcl151762_tab_rect(state,canvas,inset+1,164+inset,1118-2*inset,2,bg)end
    pcl151762_tab_rect(state,canvas,0,0,1120,3,edge)
    pcl151762_tab_rect(state,canvas,0,0,3,164,edge);pcl151762_tab_rect(state,canvas,1117,0,3,164,edge)
    pcl151762_tab_rect(state,canvas,0,164,63,3,edge,45);pcl151762_tab_rect(state,canvas,1076,208,63,3,edge,-45)
    pcl151762_tab_rect(state,canvas,44,205,1032,3,edge)
    local label=pcl151723_label(state.home,'Forge Blade',72,false);label:SetAutoWrapText(false);label:SetJustification(1);label:SetVisibility(3)
    state.forge_label=label
    local font=label.Font;font.TypefaceFontName=FName('Bold',EFindName.FNAME_Find);label:SetFont(font)
    local text=canvas:AddChildToCanvas(label);text:SetPosition({X=50,Y=44});text:SetSize({X=1020,Y=112})
    -- Use the space formerly occupied by the native footer beneath the panel.
    if state.section_layout then
        local spec=state.section_layout.spec
        if spec.padding then
            local padding=pcl151762_margin(section.Slot.Padding);padding.Bottom=padding.Bottom-312;section.Slot:SetPadding(padding)
        elseif spec.kind=='canvas'then
            local offsets=pcl151762_margin(section.Slot:GetOffsets())
            if spec.anchors.Minimum.Y==spec.anchors.Maximum.Y then offsets.Bottom=offsets.Bottom+312 else offsets.Bottom=offsets.Bottom-312 end
            section.Slot:SetOffsets(offsets)
        end
    end
    pcl151762_float_forge(state,box,canvas)
    pcl151762_start_forge_hover(state)
    log('PCL15_17_62_HOME_FOOTER native_controls_moved=true downward_forge_lip=true')
end
function pcl151762_restore_home_layout(state)
    if is_valid(state.forge_viewport)then state.forge_viewport:RemoveFromParent()end
    pcl151762_restore_magic_words(state)
    if state.story_open then state.story_open=false;state.home.PieceItemsCollection.ItemTemplate=state.creative_template end
    if is_valid(state.story_sidebar)then state.story_sidebar:SetVisibility(state.story_sidebar_visibility or 0)end
    if state.forge_opacity~=nil and is_valid(state.home.ForgeButton)then
        state.home.ForgeButton:SetRenderOpacity(state.forge_opacity)
        if is_valid(state.forge_style)then state.home.ForgeButton:SetStyle(state.forge_style)end
        if state.forge_content_visibility~=nil then state.home.ForgeButton.Content:SetVisibility(state.forge_content_visibility)end
    end
    for i=#(state.footer_moves or {}),1,-1 do
        local swap=state.footer_moves[i]
        if is_valid(swap.original)then swap.original:RemoveFromParent()end
        pcall(pcl151762_restore_swap,swap)
    end
    state.footer_moves={}
end

function pcl151762_transparent_style()
    if is_valid(PCL151762_TRANSPARENT_STYLE)then return PCL151762_TRANSPARENT_STYLE end
    local path='/Game/UI/Style/ButtonStyle_Transparent.ButtonStyle_Transparent_C'
    local style=StaticFindObject(path)
    if not is_valid(style)then style=pcl15174_load_object(path)end
    assert(is_valid(style),'Native transparent button style unavailable')
    PCL151762_TRANSPARENT_STYLE=style;return style
end

function pcl151762_style_magic_words(state)
    local input=state.home.MagicWordTextBox;local style=input.WidgetStyle
    state.magic_style_backup={padding=pcl151762_margin(style.Padding),brushes={}}
    for _,name in ipairs({'BackgroundImageNormal','BackgroundImageHovered','BackgroundImageFocused','BackgroundImageReadOnly'})do
        state.magic_style_backup.brushes[name]=style[name].DrawAs;style[name].DrawAs=0
    end
    style.Padding.Left=0;style.Padding.Top=0;style.Padding.Right=0;style.Padding.Bottom=0
    state.magic_justification=input.Justification;input:SetJustification(0)
    state.search_translation={X=state.home.FilterText.RenderTransform.Translation.X,Y=state.home.FilterText.RenderTransform.Translation.Y}
    state.home.FilterText:SetRenderTranslation({X=state.search_translation.X,Y=state.search_translation.Y+6})
    state.search_justification=state.home.FilterText.Justification;state.home.FilterText:SetJustification(0)
    state.magic_hint=input.HintText;input:SetHintText(pcl15171_to_text('Magic Words...'))
    state.download_style=state.home.DownloadButton:GetStyle():GetClass();state.download_opacity=state.home.DownloadButton:GetRenderOpacity()
    state.home.DownloadButton:SetStyle(pcl151762_transparent_style());pcl151762_remove_native_chrome(state.home.DownloadButton)
end
function pcl151762_restore_magic_words(state)
    if state.search_translation and is_valid(state.home.FilterText)then state.home.FilterText:SetRenderTranslation(state.search_translation)end
    if state.magic_tip_placement~=nil and is_valid(state.home.MagicWordTooltipAnchor)then state.home.MagicWordTooltipAnchor:Close();state.home.MagicWordTooltipAnchor:SetPlacement(state.magic_tip_placement);state.home.MagicWordTooltipAnchor:SetVisibility(state.magic_tip_visibility)end
    if state.clear_tooltip~=nil and is_valid(state.home.ClearButton)then state.home.ClearButton:SetToolTipText(state.clear_tooltip)end
    if state.magic_style_backup and is_valid(state.home.MagicWordTextBox)then
        local style=state.home.MagicWordTextBox.WidgetStyle
        for name,value in pairs(state.magic_style_backup.brushes)do style[name].DrawAs=value end
        for name,value in pairs(state.magic_style_backup.padding)do style.Padding[name]=value end
        state.home.MagicWordTextBox:SetHintText(state.magic_hint)
        state.home.MagicWordTextBox:SetJustification(state.magic_justification or 0)
        if is_valid(state.home.FilterText)then state.home.FilterText:SetJustification(state.search_justification or 0)end
    end
    if is_valid(state.home.DownloadButton)then
        if is_valid(state.download_style)then state.home.DownloadButton:SetStyle(state.download_style)end
        if state.download_opacity~=nil then state.home.DownloadButton:SetRenderOpacity(state.download_opacity)end
        if PCL151762_CHROMELESS then PCL151762_CHROMELESS[state.home.DownloadButton:GetAddress()]=nil end
    end
end

function pcl151762_input_outline(state,input,width,height,button_face)
    local overlay=pcl151723_new(state.home,'Overlay')
    local inset=pcl151723_new(state.home,'Border');inset:SetBrushColor({R=0,G=0,B=0,A=0});inset:SetPadding(button_face and {Left=0,Top=0,Right=0,Bottom=0}or {Left=12,Top=4,Right=12,Bottom=4});inset:SetHorizontalAlignment(0);inset:SetVerticalAlignment(0);inset:SetContent(input)
    if input:GetAddress()==state.home.FilterText:GetAddress()then
        -- UEditableText fills its old native height even when its parent is centered.
        -- Give the line an explicit font-sized height, then center that line in the frame.
        input:RemoveFromParent()
        local line=pcl151723_new(state.home,'SizeBox');line:SetHeightOverride(math.ceil(input:GetFont().Size*1.35));line:SetContent(input)
        inset:SetContent(line);inset:SetVerticalAlignment(2)
    end
    local content=overlay:AddChildToOverlay(inset);content:SetHorizontalAlignment(0);content:SetVerticalAlignment(0)
    local lines=pcl151723_new(state.home,'CanvasPanel');lines:SetVisibility(3)
    local edge={R=.20,G=.19,B=.13,A=1}
    for _,spec in ipairs({
        {0,0,1,0,{Left=0,Top=0,Right=0,Bottom=2}},
        {0,1,1,1,{Left=0,Top=-2,Right=0,Bottom=2}},
        {0,0,0,1,{Left=0,Top=0,Right=2,Bottom=0}},
        {1,0,1,1,{Left=-2,Top=0,Right=2,Bottom=0}},
    })do
        local line=pcl151723_new(state.home,'Border');line:SetBrushColor(edge);line:SetVisibility(3)
        local slot=lines:AddChildToCanvas(line)
        slot:SetAnchors({Minimum={X=spec[1],Y=spec[2]},Maximum={X=spec[3],Y=spec[4]}});slot:SetOffsets(spec[5])
    end
    local strokes=overlay:AddChildToOverlay(lines);strokes:SetHorizontalAlignment(0);strokes:SetVerticalAlignment(0)
    return overlay
end

function pcl151762_remove_native_chrome(button)
    for _,name in ipairs({'NormalStyle','SelectedStyle','DisabledStyle','LockedStyle'})do
        for _,brush in ipairs({'Normal','Hovered','Pressed','Disabled'})do button[name][brush].DrawAs=0 end
    end
    local root=button.WidgetTree and button.WidgetTree.RootWidget
    if is_valid(root)and pcl151762_class(root,'Button')then
        for _,brush in ipairs({'Normal','Hovered','Pressed','Disabled'})do root.WidgetStyle[brush].DrawAs=0 end
    end
    PCL151762_CHROMELESS=PCL151762_CHROMELESS or {};PCL151762_CHROMELESS[button:GetAddress()]=button
end
function pcl151762_install_chrome_hooks()
    for _,path in ipairs({'/Script/CommonUI.CommonButtonBase:BP_OnHovered','/Script/CommonUI.CommonButtonBase:BP_OnUnhovered'})do
        pcall(function()RegisterHook(path,function()end,function(context)
            local button=pcl151114_unwrap(context)
            if is_valid(button)and PCL151762_CHROMELESS and PCL151762_CHROMELESS[button:GetAddress()]then pcl151762_remove_native_chrome(button)end
        end)end)
    end
end
pcl151762_install_chrome_hooks()

function pcl151762_native_text_face(state,button,caption)
    -- A positive sub-pixel opacity keeps native Slate hit testing enabled while
    -- making its blueprint-refreshed rectangular brush visually negligible.
    button:SetRenderOpacity(.001);button:SetToolTipText(pcl15171_to_text(''))
    local overlay=pcl151723_new(state.home,'Overlay')
    local hit=overlay:AddChildToOverlay(button);hit:SetHorizontalAlignment(0);hit:SetVerticalAlignment(0)
    local label=pcl151723_label(state.home,caption,24,false);label:SetAutoWrapText(false);label:SetJustification(1);label:SetVisibility(3)
    local text=overlay:AddChildToOverlay(label);text:SetHorizontalAlignment(2);text:SetVerticalAlignment(2)
    label:SetRenderOpacity(.55)
    return {widget=overlay,label=label,button=button}
end

function pcl151762_update_action_hover(state)
    for _,face in pairs(state.action_visuals or {})do
        if is_valid(face.button)and not face.folder_tab then
            local active=face.button:IsHovered()and face.button:GetIsEnabled()
            local opacity=face.rest_opacity or .55
            if face.button==state.all or face.button==state.parts or face.button==state.blades then
                -- Selected filter stays bright; the others brighten on hover.
                opacity=math.min(opacity,.55)
                if (face.button==state.all and state.view=='all')or(face.button==state.parts and state.view=='parts')or(face.button==state.blades and state.view=='blades')then opacity=1 end
            elseif face.button~=state.close and face.button~=state.nav_library then opacity=.55 end
            if active then opacity=1 end
            if face.hover_opacity~=opacity then face.label:SetRenderOpacity(opacity);face.hover_opacity=opacity end
        end
    end
    if state.download_face then
        local button=is_valid(state.import_submit)and state.import_swap and state.import_submit or state.home.DownloadButton
        local opacity=button:IsHovered()and button:GetIsEnabled()and 1 or .55
        if state.download_face.hover_opacity~=opacity then state.download_face.label:SetRenderOpacity(opacity);state.download_face.hover_opacity=opacity end
    end
    if is_valid(state.nav_delete)then
        local opacity=state.nav_delete:IsHovered()and state.nav_delete:GetIsEnabled()and 1 or .55
        if state.trash_hover_opacity~=opacity then
            for _,list in ipairs({state.trash_strokes or {},state.cancel_strokes or {}})do for _,stroke in ipairs(list)do stroke:SetRenderOpacity(opacity)end end
            state.trash_hover_opacity=opacity
        end
    end
end

function pcl151762_float_forge(state,placeholder,canvas)
    -- The native frame's border straddles this lip. Give the existing button its
    -- own viewport surface, so no sibling or ancestor in that frame can eat hits.
    local host=pcl15171_create_widget(state.home,PCL15171_ENTRY_CLASS_OBJ)
    assert(is_valid(host),'Forge button viewport unavailable')
    local root=pcl15171_widget_by_name(host,'PCL_EntryRoot')
    root:SetWidthOverride(1120);root:SetMaxDesiredWidth(1120);root:SetHeightOverride(208)
    canvas:RemoveFromParent();root:SetContent(canvas)
    placeholder:SetVisibility(4);state.forge_placeholder=placeholder;state.forge_viewport=host
    host:SetDesiredSizeInViewport({X=1120,Y=208});host:SetAnchorsInViewport({Minimum={X=0,Y=0},Maximum={X=0,Y=0}});host:SetAlignmentInViewport({X=0,Y=0})
    local layout=StaticFindObject('/Script/UMG.Default__WidgetLayoutLibrary');assert(is_valid(layout),'Viewport layout unavailable')
    local viewport,scale=layout:GetViewportSize(state.home),layout:GetViewportScale(state.home)
    host:SetPositionInViewport({X=viewport.X/scale*.5-580,Y=viewport.Y/scale*.9-276},false)
    host:SetVisibility(0);host:AddToViewport(92)
end
function pcl151762_position_forge(state)
    if not is_valid(state.forge_viewport)or not is_valid(state.forge_placeholder)then return end
    local slate=StaticFindObject('/Script/UMG.Default__SlateBlueprintLibrary')
    local layout=StaticFindObject('/Script/UMG.Default__WidgetLayoutLibrary')
    assert(is_valid(slate)and is_valid(layout),'Forge layout libraries unavailable')
    local geometry=state.footer_bar:GetCachedGeometry();local size=slate:GetLocalSize(geometry)
    if size.X<=0 or size.Y<=0 then return end
    local point=slate:LocalToAbsolute(geometry,{X=size.X/2-560,Y=0})
    local position=slate:AbsoluteToLocal(layout:GetViewportWidgetGeometry(state.home),point)
    if state.forge_position_x~=position.X or state.forge_position_y~=position.Y then
        state.forge_viewport:SetPositionInViewport(position,false);state.forge_position_x=position.X;state.forge_position_y=position.Y
    end
    state.forge_viewport:SetVisibility(0)
    if not state.forge_position_logged then state.forge_position_logged=true;log('PCL_FORGE_VIEWPORT_READY x='..position.X..' y='..position.Y)end
end

function pcl151762_start_forge_hover(state)
    local function tick()
        if PCL151762_HOME~=state or not is_valid(state.home)or not state.home:IsVisible()then return end
        local ok,err=pcall(function()
            pcl151762_position_forge(state)
            pcl151762_update_folder_tabs(state)
            pcl151762_update_action_hover(state)
            local hovered=state.home.ForgeButton:IsHovered()
            if state.forge_hovered==hovered then return end
            state.forge_hovered=hovered
            local fill=hovered and {R=.018,G=.018,B=.012,A=1}or {R=.008,G=.008,B=.006,A=1}
            local edge=hovered and {R=.50,G=.44,B=.27,A=1}or {R=.20,G=.19,B=.13,A=1}
            local text=hovered and {R=.86,G=.79,B=.55,A=1}or {R=.56,G=.51,B=.35,A=1}
            for _,rect in ipairs(state.forge_faces or {})do if is_valid(rect)then rect:SetBrushColor(fill)end end
            for _,rect in ipairs(state.forge_rules or {})do if is_valid(rect)then rect:SetBrushColor(edge)end end
            if is_valid(state.forge_label)then state.forge_label:SetColorAndOpacity({SpecifiedColor=text,ColorUseRule=0})end
        end)
        if not ok then log('PCL_FORGE_HOVER_ERROR '..tostring(err));return end
        pcl15179_schedule(50,tick)
    end
    pcl15179_schedule(50,tick)
end
-- Separate, versioned save snapshots; never modify the source saves.
PCL151762_SAVE_BACKUP=nil
function pcl151762_backup_mkdir(path)
    PCL151762_BACKUP_DIRS=PCL151762_BACKUP_DIRS or {}
    if PCL151762_BACKUP_DIRS[path]or path:match('^%a:/$')then return end
    local parent=path:match('^(.*)/[^/]+$')
    if parent and parent~=''and not parent:match('^%a:$')then pcl151762_backup_mkdir(parent)end
    local args={#path};for i=1,#path do args[#args+1]=path:byte(i)end
    assert(pcl151761_bridge().mkdir(table.unpack(args))==1,'Could not create save backup directory')
    PCL151762_BACKUP_DIRS[path]=true
end
function pcl151762_start_save_backup()
    if PCL151762_SAVE_BACKUP then return end
    local request={status='starting',files={},index=1,bytes=0};PCL151762_SAVE_BACKUP=request
    local ok,err=pcall(function()
        local paths=StaticFindObject('/Script/Engine.Default__BlueprintPathsLibrary');assert(is_valid(paths),'Save path utilities unavailable')
        local saved=pcl151762_text(paths:ProjectSavedDir())
        saved=pcl151762_text(paths:ConvertRelativePathToFull(saved,'')):gsub('\\','/'):gsub('/$','')
        assert(saved~=''and not saved:find('["&|<>%%!%^\r\n]'),'Unsupported save directory')
        request.source=saved..'/SaveGames';request.target=saved..'/BMF_SaveBackups/'..os.date('%Y%m%d_%H%M%S')..'_'..math.floor(os.clock()*1000)
        request.status='listing'
    end)
    local function fail(message)
        if request.input then request.input:close();request.input=nil end
        if request.output then request.output:close();request.output=nil end
        if request.verify then request.verify:close();request.verify=nil end
        request.status='failed';request.error=tostring(message)
        log('PCL15_17_62_SAVE_BACKUP_FAILED '..request.error)
    end
    if not ok then fail(err);return end
    local function step()
        local success,message=pcall(function()
            local file=request.files[request.index]
            if not file then
                local manifest=assert(io.open(request.target..'/BACKUP_COMPLETE.txt','wb'))
                assert(manifest:write('Bladesong Mod Framework verified save backup\r\nSource: '..request.source..'\r\n'))
                for _,entry in ipairs(request.files)do assert(manifest:write(entry.relative..'\t'..entry.bytes..' bytes\r\n'))end
                assert(manifest:close());request.status='complete'
                log('PCL15_17_62_SAVE_BACKUP_COMPLETE files='..#request.files..' bytes='..request.bytes..' path='..request.target);return
            end
            if not request.input then
                local target=request.target..'/'..file.relative
                pcl151762_backup_mkdir(target:match('^(.*)/[^/]+$'))
                local existing=io.open(target,'rb');if existing then existing:close();error('Refusing to overwrite an existing backup')end
                request.input=assert(io.open(file.source,'rb'));request.output=assert(io.open(target,'wb'));file.target=target;file.bytes=0
            end
            if request.status=='copying'then
                local chunk=request.input:read(1024*1024)
                if chunk then assert(request.output:write(chunk));file.bytes=file.bytes+#chunk;return end
                assert(request.output:close());request.output=nil;request.input:close()
                request.input=assert(io.open(file.source,'rb'));request.verify=assert(io.open(file.target,'rb'));request.status='verifying'
            end
            local source,copy=request.input:read(1024*1024),request.verify:read(1024*1024)
            assert(source==copy,'Source changed or backup verification failed: '..file.relative)
            if not source then
                request.input:close();request.verify:close();request.input=nil;request.verify=nil
                request.bytes=request.bytes+file.bytes;request.index=request.index+1;request.status='copying'
            end
        end)
        if not success then fail(message);return end
        if request.status~='complete'then pcl15179_schedule(5,step)end
    end
    BMF_CREATIVE_FRAMEWORK.StartJob('list-saves',{source=request.source},function(response)
        local success,why=pcall(function()
            assert(response.status=='complete',response.error or 'Could not enumerate saves')
            for _,entry in ipairs(response.files or {})do
                local name=entry.source:gsub('\\','/')
                assert(name:sub(1,#request.source+1):lower()==(request.source..'/'):lower(),'Save enumeration escaped SaveGames')
                request.files[#request.files+1]={source=name,relative=name:sub(#request.source+2)}
            end
            assert(#request.files>0,'No existing save files found')
            pcl151762_backup_mkdir(request.target);request.status='copying'
            pcl15179_schedule(1,step)
        end)
        if not success then fail(why)end
    end)
end
function pcl151762_require_save_backup()
    pcl151762_start_save_backup()
    local backup=PCL151762_SAVE_BACKUP
    assert(backup and backup.status=='complete',backup and backup.status=='failed'and ('Save backup failed: '..backup.error)or 'Creating a safety backup of your saves. Try again in a moment.')
end
function pcl151762_register_folder_tabs()
PCL_FOLDER_TABS=PCL_FOLDER_TABS or assert(loadfile(BMF_CREATIVE_ROOT..'ui/folder_tabs.lua'))()
PCL_FOLDER_TABS.register{id='creative',label='Creative library',order=0,on_select=function(state)pcl151762_close(state)end,is_active=function(state)return (not state.active_tab_id or state.active_tab_id=='creative'or state.active_tab_id=='preconstruction')and not state.story_open and(not state.open or state.view=='delete')end}
PCL_FOLDER_TABS.register{id='story',label='Story swords',order=5,on_select=function(state)pcl151762_show_story(state)end,is_active=function(state)return state.story_open end}
if BMF_CREATIVE_HAS_PROVIDER then PCL_FOLDER_TABS.register{id='preconstruction',label='Preconstruction Library',order=10,on_select=function(state)pcl151762_open(state,state.last_library_view or 'all')end,is_active=function(state)return (not state.active_tab_id or state.active_tab_id=='creative'or state.active_tab_id=='preconstruction')and state.open and state.view~='delete'end} end
if not PCL_FOLDER_TABS_ADAPTERS_LOADED then
    PCL_FOLDER_TABS_ADAPTERS_LOADED=true
    local ok,modules=pcall(function()return assert(loadfile(BMF_CREATIVE_ROOT..'../../BladesongModFramework/Scripts/creative_tabs_config.lua'))()end)
    if ok and type(modules)=='table'then
        for _,name in ipairs(modules)do
            local success,message=pcall(function()assert(type(name)=='string'and name:match('^[%w_%-]+$'),'Invalid adapter module name');assert(loadfile(BMF_CREATIVE_ROOT..'../../BladesongModFramework/Scripts/'..name..'.lua'))()(PCL_FOLDER_TABS)end)
            if not success then log('PCL_FOLDER_TAB_ADAPTER_ERROR '..tostring(message))end
        end
    end
end

end
pcl151762_register_folder_tabs()
