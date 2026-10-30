#include "../../NativeSource/25940006/pcl_blade_library_151761.cpp"
static u8 active_mem[0x200],source_mem[0x200],merged_mem[0x200],backup_mem[0x200];
static u8 pool[64][64];static u32 used=0,copies=0,refreshes=0;
static bool fail_refresh=false,bad_merge=false;
static u64 destinations[8];
static void copy_fixture(u64 dest,const void* source) {
    destinations[copies++]=dest;
    const u8* src=(const u8*)source;
    for(u32 i=0;i<0x100;++i)wr<u8>(dest+i,src[i]);
    for(u32 offset=0x88;offset<=0x98;offset+=0x10) {
        u32 count=rd<u32>(dest+offset+8);u64 from=rd<u64>(dest+offset);
        if(count) {
            u64 to=(u64)pool[used++];
            for(u32 j=0;j<count;++j)wr<u8>(to+j,rd<u8>(from+j));
            wr<u64>(dest+offset,to);
        }
    }
    if(bad_merge&&dest==(u64)merged_mem+0x30)wr<u32>(dest+0xA0,99);
}
static void refresh_fixture(u64,u64 piece) {
    ++refreshes;
    if(piece!=(u64)active_mem)*(volatile int*)0=1;
    if(fail_refresh){fail_refresh=false;*(volatile int*)0=1;}
}
static void reset() {
    used=copies=refreshes=0;fail_refresh=bad_merge=false;
    for(u32 i=0;i<0x200;++i){active_mem[i]=(u8)(i+17);source_mem[i]=(u8)(i+91);merged_mem[i]=backup_mem[i]=0;}
    wr<u32>((u64)active_mem+0x98,4);
    for(u32 offset=0x88;offset<=0x98;offset+=0x10) {
        u64 data=(u64)pool[used++];
        for(u32 j=0;j<7;++j)wr<u8>(data+j,(u8)(offset+j));
        wr<u64>((u64)active_mem+0x30+offset,data);
        wr<u32>((u64)active_mem+0x38+offset,7);wr<u32>((u64)active_mem+0x3C+offset,7);
    }
}
static bool logical_equal(u64 a,u64 b) {
    for(u32 i=0;i<0x100;++i) {
        if((i>=0x88&&i<0x90)||(i>=0x98&&i<0xA0))continue;
        if(rd<u8>(a+0x30+i)!=rd<u8>(b+0x30+i))return false;
    }
    for(u32 offset=0x88;offset<=0x98;offset+=0x10) {
        u32 count=rd<u32>(a+0x38+offset);
        for(u32 j=0;j<count;++j)if(rd<u8>(rd<u64>(a+0x30+offset)+j)!=rd<u8>(rd<u64>(b+0x30+offset)+j))return false;
    }
    return true;
}
static int replace() {return blade_replace((u64)active_mem,(u64)source_mem,(u64)merged_mem,(u64)backup_mem,123,&copy_fixture,&refresh_fixture);}
extern "C" int main() {
    reset();u8 view[0x100];blade_view(view,(u64)source_mem,0);
    if(rd<u32>((u64)view+0x68)!=0xFFFFFFFF)return 1;
    for(u32 i=0;i<0x100;++i) {
        if(i>=0x68&&i<0x6C)continue;
        if(i>=0x88&&i<0xA8){if(view[i])return 2;}
        else if(view[i]!=source_mem[0x30+i])return 3;
    }
    // Exact blade fields from source, both attachment arrays and root from active.
    blade_view(view,(u64)source_mem,(u64)active_mem);
    if(replace()!=1||refreshes!=1||copies!=3)return 4;
    if(destinations[0]!=(u64)backup_mem+0x30||destinations[1]!=(u64)merged_mem+0x30||destinations[2]!=(u64)active_mem+0x30)return 5;
    if(!logical_equal((u64)active_mem,(u64)merged_mem)||rd<u32>((u64)active_mem+0x98)!=4)return 6;
    if(rd<u64>((u64)active_mem+0xB8)==rd<u64>((u64)backup_mem+0xB8))return 7;
    if(rd<u8>((u64)active_mem+0x30)!=source_mem[0x30])return 8;
    reset();bad_merge=true;
    if(replace()!=-75||copies!=2||refreshes||!logical_equal((u64)active_mem,(u64)backup_mem))return 9;
    reset();fail_refresh=true;
    if(replace()!=-82||copies!=4||refreshes!=2||!logical_equal((u64)active_mem,(u64)backup_mem))return 10;
    return 0;
}
