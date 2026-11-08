// Main 26433453: blade-only import, local cache and replacement.
#define PCL_BLADE_CACHE
#include "pcl_local_cache_151733.cpp"

static const u8 blade_tick_guard[]={0x40,0x53,0x48,0x83,0xEC,0x20,0x48,0x8B,0xD9,0xE8,0x92,0x30,0xEA,0xFE,0x48,0x8B,0x83,0x08,0x03,0x00,0x00,0x48,0x85,0xC0,0x74,0x34,0x8B,0x40,0x08,0x0F,0xBA,0xE0,0x1E,0x72,0x2B,0x0F,0xB6,0x83,0x10,0x03,0x00,0x00,0x3C,0xFF,0x74,0x20,0x48,0x8B,0x93,0x08,0x03,0x00,0x00,0x3C,0x01,0x48,0x8B,0xCB,0x41,0x0F,0x94,0xC0,0x48,0x83,0xC2,0x30,0xE8,0xA9,0xE1,0xFF,0xFF,0xC6,0x83,0x10,0x03,0x00,0x00,0xFF,0x48,0x83,0xC4,0x20,0x5B,0xC3};
static const u8 blade_update_guard[]={0x48,0x89,0x5C,0x24,0x20,0x44,0x88,0x44,0x24,0x18,0x48,0x89,0x54,0x24,0x10,0x55,0x56,0x57,0x41,0x54,0x41,0x55,0x41,0x56,0x41,0x57,0x48,0x8D,0x6C,0x24,0xD9,0x48,0x81,0xEC,0x00,0x01,0x00,0x00,0x48,0x8B,0xD9,0x33};
static const u8 blade_copy_guard[]={0x48,0x89,0x5C,0x24,0x08,0x48,0x89,0x6C,0x24,0x10,0x48,0x89,0x74,0x24,0x18,0x57,0x41,0x56,0x41,0x57,0x48,0x83,0xEC,0x40,0x8B,0x02,0x4C,0x8D,0x72,0x08,0x48,0x8D,0x71,0x08,0x89};
static int blade_guard(){int status=cache_guard();if(status!=1)return status;
 if(!same(image+0x458B830,blade_tick_guard,sizeof(blade_tick_guard))||
    !same(image+0x4589A20,blade_update_guard,sizeof(blade_update_guard))||
    !same(image+0x4541DD0,blade_copy_guard,sizeof(blade_copy_guard)))return -77;
 return 1;
}
static void blade_refresh(u64 blade,u64 piece){
 // Use the same full mesh regeneration as this build's ABladeMesh tick.
 ((void(*)(u64,u64,bool))(image+0x4589A20))(blade,piece+0x30,false);

 wr<u8>(blade+0x310,0xFF);
}
// Blade-only data operations. Native copy owns all spline/ability allocations;
// no scalar Lua serialization, dummy parts, or anchor actors are introduced.
static bool blade_piece(u64 piece,u64 cls) {
    return live(piece)&&live(cls)&&rd<u64>(piece+0x10)==cls;
}
static void blade_view(u8* view,u64 source,u64 attachments) {
    for(u32 i=0;i<0x100;++i)view[i]=rd<u8>(source+0x30+i);
    if(attachments) {
        for(u32 i=0x68;i<0x6C;++i)view[i]=rd<u8>(attachments+0x30+i);
        for(u32 i=0x88;i<0xA8;++i)view[i]=rd<u8>(attachments+0x30+i);
    } else {
        for(u32 i=0x68;i<0x6C;++i)view[i]=0xFF;
        for(u32 i=0x88;i<0xA8;++i)view[i]=0;
    }
}
extern "C" __declspec(dllexport) int pcl_blade_snapshot(void* L) {
    u64 source=0,dest=0,cls=0;
    if(!arg(L,1,source)||!arg(L,2,dest)||!arg(L,3,cls))return result(L,-1);
    int status=blade_guard();if(status!=1)return result(L,status);
    if(busy||source==dest||!blade_piece(source,cls)||!blade_piece(dest,cls)||rd<u32>(dest+0xD0))return result(L,-70);
    busy=true;
    __try {
        __declspec(align(16))u8 view[0x100];blade_view(view,source,0);
        ((void(*)(u64,const void*))(image+0x4541DD0))(dest+0x30,view);
        status=(rd<u32>(dest+0xD0)==0&&rd<u32>(dest+0xC0)==0)?1:-71;
    } __except(1){status=-72;}
    busy=false;return result(L,status);
}
typedef void (*BladeCopy)(u64,const void*);
typedef void (*BladeRefresh)(u64,u64);
static int blade_replace(u64 active,u64 source,u64 merged,u64 backup,u64 blade,BladeCopy copy,BladeRefresh refresh) {
    int status=-76;bool mutated=false;
    __try {
        __declspec(align(16))u8 view[0x100];blade_view(view,source,active);
        copy(backup+0x30,(const void*)(active+0x30));
        copy(merged+0x30,view);
        if(rd<u32>(merged+0xD0)!=rd<u32>(active+0xD0)||rd<u32>(merged+0xC0)!=rd<u32>(active+0xC0)||rd<u32>(merged+0x98)!=rd<u32>(active+0x98))return -75;
        mutated=true;
        copy(active+0x30,(const void*)(merged+0x30));
        refresh(blade,active);
        status=1;
    } __except(1){status=-76;}
    if(mutated&&status!=1) {
        __try {copy(active+0x30,(const void*)(backup+0x30));refresh(blade,active);status=-82;}
        __except(1){status=-83;}
    }
    return status;
}
extern "C" __declspec(dllexport) int pcl_blade_apply(void* L) {
    u64 forge=0,active=0,source=0,merged=0,backup=0,cls=0;
    if(!arg(L,1,forge)||!arg(L,2,active)||!arg(L,3,source)||!arg(L,4,merged)||!arg(L,5,backup)||!arg(L,6,cls))return result(L,-1);
    int status=blade_guard();if(status!=1)return result(L,status);
    if(busy||!live(forge)||!blade_piece(active,cls)||!blade_piece(source,cls)||!blade_piece(merged,cls)||!blade_piece(backup,cls)||
       rd<u64>(forge+0x428)!=active||rd<u32>(merged+0xD0)||rd<u32>(backup+0xD0)||
       source==active||merged==active||backup==active||merged==backup||source==merged||source==backup)return result(L,-73);
    u64 blade=rd<u64>(forge+0x308);
    if(!live(blade)||rd<u64>(blade+0x308)!=active)return result(L,-74);
    busy=true;
    status=blade_replace(active,source,merged,backup,blade,(BladeCopy)(image+0x4541DD0),&blade_refresh);
    busy=false;return result(L,status);
}

extern "C" __declspec(dllexport) int pcl_blade_refresh(void* L){
 u64 forge=0,piece=0;if(!arg(L,1,forge)||!arg(L,2,piece))return result(L,-1);
 int status=blade_guard();if(status!=1)return result(L,status);
 if(busy||!live(forge)||!live(piece)||rd<u64>(forge+0x428)!=piece)return result(L,-78);
 u64 blade=rd<u64>(forge+0x308);if(!live(blade)||rd<u64>(blade+0x308)!=piece)return result(L,-74);
 busy=true;__try{blade_refresh(blade,piece);status=1;}__except(1){status=-79;}busy=false;return result(L,status);
}

extern "C" __declspec(dllexport) int pcl_blade_probe(void* L){return result(L,blade_guard());}
extern "C" __declspec(dllimport) int __stdcall CreateDirectoryW(const unsigned short*,void*);
extern "C" __declspec(dllimport) u32 __stdcall GetLastError();
extern "C" __declspec(dllimport) int __stdcall MultiByteToWideChar(u32,u32,const char*,int,unsigned short*,int);
extern "C" __declspec(dllexport) int pcl_blade_mkdir(void* L){
 u64 n=0;if(!arg(L,1,n)||!n||n>2048)return result(L,-1);
 static char bytes[2049];static unsigned short path[2049];
 for(u32 i=0;i<n;++i){u64 v=0;if(!arg(L,2+i,v)||!v||v>255)return result(L,-1);bytes[i]=(char)v;}
 int length=MultiByteToWideChar(65001,8,bytes,(int)n,path,2048);if(length<=0)return result(L,-80);
 path[length]=0;return result(L,CreateDirectoryW(path,0)||GetLastError()==183?1:-81);
}
