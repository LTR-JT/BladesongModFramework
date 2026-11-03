#include "../../NativeSource/26400894/pcl_anchor_reload_151756.cpp"

static u8 piece[0x200], table[0x20], parts[2 * 0x120];

extern "C" int main() {
    const u64 piece_address = (u64)piece;
    const u64 table_address = (u64)table;
    const u64 anchor = 12345;
    const u64 regular_part = (u64)parts + 0x120;
    wr<u64>(piece_address + 0x10, 0x10000);
    wr<u64>(table_address + 0x10, 0x20000);
    wr<u64>(piece_address + 0xC8, (u64)parts);
    wr<u32>(piece_address + 0xD0, 2);
    wr<u32>(piece_address + 0xD4, 2);
    wr<u64>((u64)parts, anchor);
    wr<u64>(regular_part, 54321);
    wr<u64>(regular_part + 0xF8, 0x30000);
    wr<u64>((u64)parts + 0xD0, 0x40000);
    if (rebind_piece(piece_address, 0x10000, table_address, 0x20000, anchor) != 1) return 1;
    if (rd<u64>((u64)parts + 0xF8) != table_address || rd<u64>((u64)parts + 0x100) != anchor) return 2;
    if (rd<u64>(regular_part + 0xF8) != 0x30000 || rd<u64>((u64)parts + 0xD0) != 0x40000) return 3;
    if (rebind_piece(piece_address, 0x10000, table_address, 0x20000, anchor) != 0) return 4;
    if (rebind_piece(piece_address, 0x30000, table_address, 0x20000, anchor) != -3) return 5;
    return 0;
}
