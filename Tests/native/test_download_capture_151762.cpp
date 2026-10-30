#include "../../NativeSource/25940006/pcl_download_capture_151762.cpp"
static u8 gm_mem[0x500],active_mem[0x500],temp_mem[0x500],before_mem[0x200],piece_mem[0x200];
static int forwards=0;
static u8 array_mem[0x100],items_mem[24*7];
static u64 chunks_mem[1];
static void forward(u64,u64) { ++forwards; }
static void reset() {
    u64 gm=(u64)gm_mem,active=(u64)active_mem,temp=(u64)temp_mem,before=(u64)before_mem;
    wr<u64>(gm+0x448,active); wr<u64>(active+0x3D8,before); wr<u64>(temp+0x3D8,before);
    wr<u64>((u64)piece_mem+0x10,0x12345678); wr<u32>((u64)piece_mem+8,0);
    capture={0x56780000,gm,active,temp,before,0x12345678,GetTickCount64()+120000,GetCurrentThreadId(),1};
    object_array=(u64)array_mem;
    chunks_mem[0]=(u64)items_mem;
    wr<u64>(object_array+0x10,(u64)chunks_mem); wr<u32>(object_array+0x24,7);
    u64 objects[]={capture.widget,gm,active,temp,before,capture.piece_class};
    for(int i=0;i<6;++i) {
        weak_objects[i]={(u32)i+1,42u+(u32)i};
        wr<u64>((u64)items_mem+24ull*(i+1),0x0100000000000001ull); // UE5.7 FlagsAndRefCount
        wr<u64>((u64)items_mem+24ull*(i+1)+8,objects[i]); // Object follows flags
        wr<u32>((u64)items_mem+24ull*(i+1)+0x10,42u+(u32)i);
    }
    original=&forward; forwards=0;
}
static void fire() { receive((u64)gm_mem,(u64)piece_mem,0x56780000); }
static int stock_factory_calls=0,creates=0,loads=0,inventory=42;
static bool bad_load=false;
static u64 stock_factory(u64,u64,u8) {++stock_factory_calls;++inventory;return (u64)piece_mem;}
static u64 fake_new(u64 state){if(state!=0x12340000)return 0;++creates;return (u64)piece_mem;}
static void fake_load(u64 piece,u64 data){++loads;if(bad_load)*(volatile int*)0=1;}
static void reset_factory(){reset();original_factory=&stock_factory;create_piece=&fake_new;load_piece=&fake_load;stock_factory_calls=creates=loads=0;inventory=42;bad_load=false;}
static void reset_home(bool existing_forge=false) {
    reset_factory();capture.home=true;capture.temp=(u64)temp_mem;capture.before=(u64)before_mem;
    capture.active=existing_forge?(u64)active_mem:0;
    wr<u64>((u64)gm_mem+0x448,capture.active);
    wr<u64>((u64)temp_mem+0x10,capture.before);wr<u64>((u64)temp_mem+0x328,0);
    u64 objects[]={capture.widget,capture.gm,capture.temp,capture.before,capture.piece_class,capture.widget};
    for(int i=0;i<6;++i){weak_objects[i]={(u32)i+1,42u+(u32)i};wr<u64>((u64)items_mem+24ull*(i+1)+8,objects[i]);}
}
extern "C" int main() {
    reset_home();
    u64 downloaded=receive_factory(0x12340000,0x23450000,0,capture.widget);
    if(downloaded!=(u64)piece_mem||stock_factory_calls||inventory!=42||creates!=1||loads!=1)return 40;
    fire();if(capture.status!=2||forwards||rd<u64>((u64)temp_mem+0x328)!=(u64)piece_mem||rd<u64>((u64)gm_mem+0x448))return 41;
    reset_home(true);fire();
    if(capture.status!=2||forwards||rd<u64>((u64)gm_mem+0x448)!=(u64)active_mem||rd<u64>((u64)active_mem+0x3D8)!=(u64)before_mem)return 42;
    reset_home();capture.status=-9;fire();if(capture.status!=-8||forwards||rd<u64>((u64)temp_mem+0x328))return 43;
    reset_home();wr<u64>((u64)gm_mem+0x448,1);fire();if(capture.status!=-5||forwards||rd<u64>((u64)temp_mem+0x328))return 44;
    reset_home();wr<u32>((u64)items_mem+24*3+0x10,999);fire();if(capture.status!=-5||forwards||rd<u64>((u64)temp_mem+0x328))return 45;
    reset_home();wr<u64>((u64)temp_mem+0x328,1);fire();if(capture.status!=-5||forwards)return 46;
    reset_home();wr<u64>((u64)temp_mem+0x10,1);fire();if(capture.status!=-5||forwards)return 47;

    reset_factory();capture.status=0;
    if(receive_factory(0x12340000,0x23450000,0,capture.widget)!=(u64)piece_mem||stock_factory_calls!=1||inventory!=43)return 20;
    reset_factory();receive_factory(0x12340000,0x23450000,0,0x98760000);
    if(stock_factory_calls!=1||inventory!=43||creates||loads)return 21;
    reset_factory();
    if(receive_factory(0x12340000,0x23450000,0,capture.widget)!=(u64)piece_mem||stock_factory_calls||inventory!=42||creates!=1||loads!=1)return 22;
    fire();if(capture.status!=2||forwards||rd<u64>((u64)temp_mem+0x3D8)!=(u64)piece_mem)return 23;
    if(rd<u64>((u64)active_mem+0x3D8)!=(u64)before_mem)return 24;
    reset_factory();capture.status=-9;receive_factory(0x12340000,0x23450000,0,capture.widget);fire();
    if(capture.status!=-8||stock_factory_calls||inventory!=42)return 25;
    reset_factory();capture.deadline=0;
    if(receive_factory(0x12340000,0x23450000,0,capture.widget)||creates||loads||inventory!=42)return 26;
    reset_factory();capture.thread^=1;
    if(receive_factory(0x12340000,0x23450000,0,capture.widget)||creates||loads)return 27;
    reset_factory();wr<u32>((u64)items_mem+24*4+0x10,900);
    if(receive_factory(0x12340000,0x23450000,0,capture.widget)||creates||loads)return 28;
    reset_factory();wr<u64>((u64)piece_mem+0x10,0xFFFF);
    if(receive_factory(0x12340000,0x23450000,0,capture.widget)||loads||inventory!=42)return 29;
    reset_factory();bad_load=true;
    if(receive_factory(0x12340000,0x23450000,0,capture.widget)||inventory!=42||stock_factory_calls)return 30;
    receive((u64)gm_mem,0,capture.widget);if(capture.status!=-5||forwards)return 31;
    reset_factory();if(receive_factory(0x12340000,0,0,capture.widget)||creates||loads)return 32;

    reset(); receive((u64)gm_mem,(u64)piece_mem,0x98760000);
    if(forwards!=1 || capture.status!=1 || rd<u64>((u64)temp_mem+0x3D8)!=(u64)before_mem) return 1;
    reset(); fire();
    if(forwards || capture.status!=2 || rd<u64>((u64)temp_mem+0x3D8)!=(u64)piece_mem ||
       rd<u64>((u64)active_mem+0x3D8)!=(u64)before_mem || rd<u64>((u64)gm_mem+0x448)!=(u64)active_mem) return 2;
    reset(); capture.status=-9; fire(); if(forwards || capture.status!=-8) return 3;
    reset(); capture.deadline=0; fire(); if(forwards || capture.status!=-7) return 4;
    reset(); capture.thread^=1; fire(); if(forwards || capture.status!=-7) return 5;
    reset(); wr<u64>((u64)gm_mem+0x448,0xFFFF); fire(); if(forwards || capture.status!=-5) return 6;
    reset(); wr<u64>((u64)active_mem+0x3D8,0xFFFF); fire(); if(forwards || capture.status!=-5) return 7;
    reset(); wr<u64>((u64)temp_mem+0x3D8,0xFFFF); fire(); if(forwards || capture.status!=-5) return 8;
    reset(); wr<u64>((u64)piece_mem+0x10,0xFFFF); fire(); if(forwards || capture.status!=-5) return 9;
    reset(); wr<u32>((u64)piece_mem+8,0x40000000); fire(); if(forwards || capture.status!=-5) return 10;
    reset(); capture.status=0; fire(); if(forwards!=1 || capture.status) return 11;
    reset(); wr<u32>((u64)items_mem+24*4+0x10,900); fire(); if(forwards || capture.status!=-5) return 13;
    reset(); chunks_mem[0]=0; fire(); if(forwards || capture.status!=-5) return 14;
    reset(); wr<u32>(object_array+0x24,2); fire(); if(forwards || capture.status!=-5) return 15;
    reset(); wr<u32>((u64)items_mem+24*4+4,0x10000000); fire(); if(forwards || capture.status!=-5) return 16;
    reset(); wr<u32>((u64)items_mem+24*4+4,0x00200000); fire(); if(forwards || capture.status!=-5) return 17;
    if(image_guard()!=-3) return 12; // test EXE is not the game; refuse it
    return 0;
}
