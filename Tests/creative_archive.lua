local root = os.getenv('BMF_TEST_ROOT') .. '/Framework/shared/BladesongFramework/'
local archive = assert(loadfile(root .. 'ui/creative_archive.lua'))(root)
local journal = os.tmpname()
local slots, objects = {}, {}
local function object(fields)
    local id = #objects + 1
    fields.GetAddress = function() return id end
    objects[id] = fields
    return fields
end
local saveclass, piececlass = object({}), object({})
local function new_save()
    local pieces = {}
    function pieces:ForEach(fn)
        for i, item in ipairs(self) do fn(i - 1, {get = function() return item end}) end
    end
    return object({GetClass = function() return saveclass end, Pieces = pieces})
end
local function new_piece(id, name, parts)
    return object({
        PieceId = id, Name = name, GetPieceNameWithFallback = function(self) return self.Name end,
        WeaponDesignDefinition = {AppliedSwordParts = parts}
    })
end
local write_success = true
local services = {
    statics = {
        CreateSaveGameObject = new_save,
        DoesSaveGameExist = function(_, slot) return slots[slot] ~= nil end,
        SaveGameToSlot = function(_, save, slot)
            if not write_success then return false end
            slots[slot] = save
            return true
        end,
        LoadGameFromSlot = function(_, slot) return slots[slot] end,
    },
    saveclass = saveclass, piececlass = piececlass, valid = function(value) return value ~= nil end,
    construct = function() return new_piece(0, '', {}) end,
    text = function(value) return value end, to_text = function(value) return value end,
    bridge = {
        store = function(save, piece)
            local source = objects[piece]
            objects[save].Pieces[1] = {PieceId = source.PieceId, Name = source.Name,
                WeaponDesignDefinition = source.WeaponDesignDefinition}
            return 1
        end,
        restore = function(save, piece)
            objects[piece].WeaponDesignDefinition = objects[save].Pieces[1].WeaponDesignDefinition
            return 1
        end,
    },
}
local blade = new_piece(4611686018427387899, 'Blade only', {})
local sword = new_piece(12, 'Test | sword\nname', {'guard', 'pommel'})
local blade_entry = archive.store(journal, services, blade)
local sword_entry = archive.store(journal, services, sword)
assert(blade_entry.slot ~= sword_entry.slot and blade_entry.parts == 0 and sword_entry.parts == 2)
assert(#archive.available(journal, {[archive.id(blade)]=true,[archive.id(sword)]=true}) == 0)
local deleted = archive.available(journal, {})
assert(#deleted == 2 and deleted[1].slot == sword_entry.slot and deleted[2].slot == blade_entry.slot)
local recovered = archive.load(services, {}, deleted[2])
assert(recovered.PieceId == blade.PieceId and recovered.Name == blade.Name and #recovered.WeaponDesignDefinition.AppliedSwordParts == 0)
local remaining = archive.available(journal, {[archive.id(recovered)]=true})
assert(#remaining == 1 and remaining[1].slot == sword_entry.slot)
assert(archive.load(services, {}, remaining[1]).Name == sword.Name)

local interrupted = assert(io.open(journal, 'ab'))
interrupted:write('{"id":')
interrupted:close()
sword.Name = 'Updated sword'
local latest = archive.store(journal, services, sword)
assert(#archive.available(journal, {}) == 2 and archive.journal(journal)[1].slot == latest.slot)
assert(archive.load(services, {}, latest).Name == 'Updated sword')
write_success = false
assert(not pcall(archive.store, journal, services, new_piece(15, 'Could not save', {})))
assert(#archive.journal(journal) == 2)
slots[latest.slot].Pieces[1].PieceId = 123
assert(not pcall(archive.load, services, {}, latest))
assert(os.remove(journal))
print('PASS: individual archive readback, zero-part and large IDs, failed saves, incomplete journal writes, re-delete, and duplicate prevention')
