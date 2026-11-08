-- Individual Creative sword archives live beside the profile save.
-- A record is visible only while that sword ID is absent from the live library.
local root = ...
local json = assert(loadfile(root .. 'json.lua'))()
local M = {}
local sequence = 0

function M.id(piece)
    local id = math.tointeger(piece.PieceId)
    assert(id and id ~= 0, 'Sword has no persistent ID')
    return tostring(id)
end

function M.journal(path)
    local entries, seen = {}, {}
    local file = io.open(path, 'rb')
    if not file then return entries end
    for line in file:lines() do
        if #line > 0 and #line <= 8192 then
            local ok, entry = pcall(json.decode, line)
            if ok and type(entry) == 'table' and type(entry.id) == 'string' and entry.id:match('^%-?%d+$')
                and type(entry.slot) == 'string' and entry.slot:match('^BMF_Deleted_%d+_%d+$')
                and type(entry.name) == 'string' and type(entry.time) == 'number' and type(entry.parts) == 'number'
                and math.tointeger(entry.time) and math.tointeger(entry.parts)
                and entry.time >= 0 and entry.time < 4102444800 and entry.parts >= 0 then
                entries[#entries + 1] = entry
                seen[entry.id] = entry
            end
        end
    end
    file:close()
    local latest = {}
    for index = #entries, 1, -1 do
        local entry = entries[index]
        if seen[entry.id] == entry then latest[#latest + 1] = entry end
    end
    return latest
end

function M.available(path, live)
    local result = {}
    if path then
        for _, entry in ipairs(M.journal(path)) do
            if not live[entry.id] then result[#result + 1] = entry end
        end
    end
    return result
end

local function append(path, entry)
    local encoded = json.encode(entry)
    assert(#encoded <= 8192, 'Sword archive metadata is too large')
    local file = assert(io.open(path, 'ab'))
    -- The leading newline isolates a partial write left by a previous launch.
    local written, why = file:write('\n' .. encoded .. '\n')
    local closed, close_error = file:close()
    assert(written and closed, why or close_error or 'Could not record deleted sword')
end

local function readback(services, slot, entry)
    local save = services.statics:LoadGameFromSlot(slot, 0)
    assert(services.valid(save) and save:GetClass():GetAddress() == services.saveclass:GetAddress() and #save.Pieces == 1,
        'Sword archive could not be read')
    local name
    save.Pieces:ForEach(function(_, value)
        local data = value:get()
        assert(name == nil and M.id(data) == entry.id and #data.WeaponDesignDefinition.AppliedSwordParts == entry.parts,
            'Sword archive verification failed')
        name = services.text(data.Name)
    end)
    assert(name ~= nil, 'Sword archive data is missing')
    return save, name
end

function M.store(path, services, piece)
    local now, slot = os.time(), nil
    repeat
        sequence = sequence + 1
        slot = ('BMF_Deleted_%d_%d'):format(now, sequence)
    until not services.statics:DoesSaveGameExist(slot, 0)
    local entry = {id = M.id(piece), slot = slot, time = now, parts = #piece.WeaponDesignDefinition.AppliedSwordParts,
        name = services.text(piece:GetPieceNameWithFallback())}
    local save = services.statics:CreateSaveGameObject(services.saveclass)
    assert(services.valid(save), 'Could not create the sword archive')
    local result = services.bridge.store(save:GetAddress(), piece:GetAddress(), services.saveclass:GetAddress(), services.piececlass:GetAddress())
    assert(result == 1, 'Could not archive sword (' .. tostring(result) .. ')')
    assert(services.statics:SaveGameToSlot(save, slot, 0), 'Could not save the sword archive')
    readback(services, slot, entry)
    append(path, entry)
    return entry
end

function M.load(services, owner, entry)
    local save, name = readback(services, entry.slot, entry)
    local piece = services.construct(services.piececlass, owner)
    assert(services.valid(piece), 'Could not create the restored sword')
    local result = services.bridge.restore(save:GetAddress(), piece:GetAddress(), services.saveclass:GetAddress(), services.piececlass:GetAddress())
    assert(result == 1, 'Could not restore sword (' .. tostring(result) .. ')')
    piece.Name = services.to_text(name)
    piece.PieceId = assert(math.tointeger(entry.id))
    assert(M.id(piece) == entry.id and #piece.WeaponDesignDefinition.AppliedSwordParts == entry.parts, 'Restored sword data differs from the archive')
    return piece
end

return M
