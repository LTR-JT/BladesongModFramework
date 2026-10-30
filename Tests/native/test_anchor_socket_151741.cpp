#include "../../NativeSource/25940006/pcl_anchor_socket_151741.cpp"
static unsigned char row[512], slots[96], state[96], ci[32], func[96], result[32];
static void prepare(u64 name=23456,u64 primary=1) {
    wr<u64>((u64)state+0x20,(u64)ci); wr<u64>((u64)state+0x10,(u64)result);
    wr<u64>((u64)ci,(u64)func);
    wr<u64>((u64)func+16,(u64)row); wr<u8>((u64)func+24,3);
    wr<u64>((u64)func+32,0x123450); wr<u8>((u64)func+40,3);
    wr<u64>((u64)func+48,name); wr<u8>((u64)func+56,3);
    wr<u64>((u64)func+64,primary); wr<u8>((u64)func+72,3);
}
extern "C" int main() {
 wr<u8>((u64)row+0xD9,0xA5);
    wr<u8>((u64)row+0x20,2); wr<u8>((u64)row+0x21,2); wr<u8>((u64)row+0xDB,1);
    wr<u64>((u64)row+0x130,(u64)slots); wr<u32>((u64)row+0x138,2); wr<u32>((u64)row+0x13C,2);
    for (u32 i=0;i<96;++i) wr<u8>((u64)slots+i,0xAB);
    prepare(); pcl_anchor_set_socket_row(state);
    if (rd<i64>((u64)result)!=1 || check_socket_row((u64)row,0x123450,23456,1)!=1) return 1;
    if (rd<u32>((u64)row+0x138)!=1 || rd<u8>((u64)row+0xDB)!=1) return 2;
    if (rd<u64>((u64)slots)!=23456 || rd<double>((u64)slots+8)!=0.0 ||
        rd<double>((u64)slots+16)!=0.0 || rd<double>((u64)slots+24)!=0.0) return 3;
    if (rd<u8>((u64)slots+32) || rd<u8>((u64)slots+33)) return 4;
    prepare(); pcl_anchor_set_socket_row(state);
    if (rd<i64>((u64)result)!=1) return 5;
    wr<double>((u64)slots+8,-1.0);
    if (check_socket_row((u64)row,0x123450,23456,1)!=-8) return 6;
    prepare(); pcl_anchor_set_socket_row(state);
    if (rd<i64>((u64)result)!=1) return 7;
    wr<u64>((u64)slots,99);
    if (check_socket_row((u64)row,0x123450,23456,1)!=-7) return 8;
    prepare(0); pcl_anchor_set_socket_row(state);
    if (rd<i64>((u64)result)!=-2 || rd<u64>((u64)slots)!=99) return 9;
    wr<u32>((u64)row+0x138,3); wr<u32>((u64)row+0x13C,3);
    prepare(); pcl_anchor_set_socket_row(state);
    if (rd<i64>((u64)result)!=-4 || rd<u32>((u64)row+0x138)!=3) return 10;
    wr<u32>((u64)row+0x138,1); wr<u32>((u64)row+0x13C,2);
    prepare(23456,0); pcl_anchor_set_socket_row(state);
    if (rd<i64>((u64)result)!=1 || rd<u8>((u64)row+0xDB)!=0) return 11;
    if (check_socket_row((u64)row,0x123450,23456,0)!=1) return 12;
    prepare(23456,1); pcl_anchor_set_socket_row(state);
    if (rd<i64>((u64)result)!=1 || rd<u8>((u64)row+0xDB)!=1) return 13;
    prepare(23456,2); pcl_anchor_set_socket_row(state);
    if (rd<i64>((u64)result)!=-2 || rd<u8>((u64)row+0xDB)!=1) return 14;
    if(rd<u8>((u64)row+0xD9)!=0xA5)return 15;
    return 0;
}
