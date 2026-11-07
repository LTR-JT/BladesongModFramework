// Main 26433453: isolated prefab cache. Exact-build guards precede native calls.
typedef unsigned char u8;
typedef unsigned int u32;
typedef unsigned long long u64;
typedef long long i64;
extern "C" __declspec(dllimport) void* __stdcall GetModuleHandleW(const void*);
extern "C" __declspec(dllimport) u32 __stdcall GetCurrentThreadId();
template<class T> static T rd(u64 p) { return *(volatile T*)p; }
template<class T> static void wr(u64 p,T v) { *(volatile T*)p=v; }
static bool ptr(u64 p) { return p>=0x10000 && p<0x800000000000ull; }
static bool same(u64 p,const u8* b,u32 n) {
    for(u32 i=0;i<n;++i) if(rd<u8>(p+i)!=b[i]) return false;
    return true;
}
static bool arg(void* L,int n,u64& v) {
    if(!L) return false;
    u64 ci=rd<u64>((u64)L+0x20); if(!ptr(ci)) return false;
    u64 f=rd<u64>(ci); if(!ptr(f)) return false;
    u64 tv=f+16ull*n;
    if(rd<u8>(tv+8)!=3) return false; // integer, not a float payload
    v=rd<u64>(tv); return true;
}
static int result(void* L,i64 v) {
    if(!L) return 0;
    u64 top=rd<u64>((u64)L+0x10); if(!ptr(top)) return 0;
    wr<i64>(top,v); wr<u8>(top+8,3); wr<u64>((u64)L+0x10,top+16); return 1;
}
static u64 image=0;
static bool busy=false;
static u32 owner_thread=0;
static bool live(u64 p) {
    if(!ptr(p)) return false;
    struct Weak {u32 index,serial;} weak={};
    ((void(*)(Weak*,u64*))(image+0x1499320))(&weak,&p);
    const u64 objects=image+0x865C7D0;
    u32 index=weak.index;
    if(index>=rd<u32>(objects+0x24)) return false;
    u64 chunks=rd<u64>(objects+0x10);
    if(!ptr(chunks)) return false;
    u64 chunk=rd<u64>(chunks+8ull*(index>>16));
    if(!ptr(chunk)) return false;
    u64 item=chunk+24ull*(index&0xFFFF);
    return rd<u64>(item+8)==p && !(rd<u32>(item+4)&0x10200000u) && weak.serial!=0 && rd<u32>(item+0x10)==weak.serial;
}
static const u8 weak_assign_guard[]={0x40,0x53,0x48,0x83,0xEC,0x20,0x48,0x8B,0x12,0x48,0x8B,0xD9,0x48,0x85,0xD2,0x74};
static const u8 weak_array_guard[]={0x48,0x8D,0x0D,0x93,0x34,0x1C,0x07,0xE8,0xFE,0x19,0xFE,0xFF};
static const u8 weak_layout_guard[]={0x3B,0x51,0x24,0x7D,0x1C,0x4C,0x8B,0x41,0x10,0x44,0x8B,0xCA,0x0F,0xB7,0xC2,0x49,0xC1,0xE9,0x10,0x48,0x8D,0x14,0x40,0x4B,0x8B,0x04,0xC8,0x48,0x8D,0x3C,0xD0,0xEB,0x02,0x33,0xFF,0x8B,0x47,0x10,0x85,0xC0};
static int guard() {
    image=(u64)GetModuleHandleW(0);
    if(!ptr(image)||rd<unsigned short>(image)!=0x5A4D)return -2;
    const u64 pe=image+rd<u32>(image+0x3C);
    if(rd<u32>(pe)!=0x4550||rd<u32>(pe+24+56)!=0x90AE000)return -3;
    if(!same(image+0x1499320,weak_assign_guard,sizeof(weak_assign_guard))||
       !same(image+0x1499336,weak_array_guard,sizeof(weak_array_guard))||
       !same(image+0x147AD46,weak_layout_guard,sizeof(weak_layout_guard)))return -4;
    if(!owner_thread)owner_thread=GetCurrentThreadId();
    return owner_thread==GetCurrentThreadId()?1:-5;
}
static const u8 cache_save[]={0x48,0x89,0x5C,0x24,0x18,0x48,0x89,0x6C,0x24,0x20,0x48,0x89,0x54,0x24,0x10,0x56,0x57,0x41,0x56,0x48,0x83,0xEC,0x40,0x48};
static const u8 cache_grow[]={0x48,0x89,0x74,0x24,0x18,0x48,0x89,0x7C,0x24,0x20,0x41,0x54,0x41,0x56,0x41,0x57,0x48,0x83,0xEC,0x30,0x41,0x8B,0x31,0x4D};
static const u8 cache_rebuild[]={0x48,0x8B,0xC4,0x48,0x89,0x58,0x10,0x48,0x89,0x70,0x18,0x48,0x89,0x78,0x20,0x55,0x41,0x56,0x41,0x57,0x48,0x8D,0x68,0xC8};
static const u8 cache_decode[]={0x48,0x89,0x5C,0x24,0x08,0x48,0x89,0x6C,0x24,0x10,0x48,0x89,0x74,0x24,0x18,0x57,0x48,0x83,0xEC,0x30,0x41,0x0F,0xB6,0xE8};
static const u8 cache_load[]={0x48,0x89,0x5C,0x24,0x10,0x48,0x89,0x6C,0x24,0x18,0x48,0x89,0x74,0x24,0x20,0x57,0x48,0x83,0xEC,0x20,0x48,0x8B,0xD9,0x48,0x8B,0xFA,0x48,0x83,0xC1,0x30,0xE8,0x1D};
static int cache_guard() {
    int status=guard();if(status!=1)return status;
    if(!same(image+0x45A2770,cache_save,sizeof(cache_save)) ||
       !same(image+0x10EE720,cache_grow,sizeof(cache_grow)) ||
       !same(image+0x45B8550,cache_rebuild,sizeof(cache_rebuild)) ||
       !same(image+0x11DB8E0,cache_decode,sizeof(cache_decode)) ||
       !same(image+0x45BB590,cache_load,sizeof(cache_load)))return -26;
    return 1;
}
extern "C" __declspec(dllexport) int pcl_cache_probe(void* L) {return result(L,cache_guard());}
extern "C" __declspec(dllexport) int pcl_cache_store(void* L) {
    u64 save=0,piece=0,saveclass=0,piececlass=0;
    if(!arg(L,1,save)||!arg(L,2,piece)||!arg(L,3,saveclass)||!arg(L,4,piececlass))return result(L,-1);
    int status=cache_guard();if(status!=1)return result(L,status);
    if(busy||!live(save)||!live(piece)||!live(saveclass)||!live(piececlass))return result(L,-7);
    if(rd<u64>(save+0x10)!=saveclass||rd<u64>(piece+0x10)!=piececlass ||
       rd<u64>(save+0x30)||rd<u64>(save+0x38)||rd<u32>(piece+0xD0)<1 || rd<u32>(piece+0xD0)>6000)return result(L,-27);
    busy=true;
    __try {
        // Engine TArray grow: element size, alignment, allocator, capacity.
        // Num stays zero until GetSaveData constructs the complete element.
        ((int(*)(u32,u32,u64,u64))(image+0x10EE720))(0x1A8,8,save+0x30,save+0x3C);
        u64 data=rd<u64>(save+0x30);
        if(!ptr(data)||rd<u32>(save+0x3C)<1)status=-28;
        else {
            ((u64(*)(u64,u64))(image+0x45A2770))(piece,data);
            wr<u32>(save+0x38,1);status=1;
        }
    } __except(1){status=-29;}
    busy=false;return result(L,status);
}
extern "C" __declspec(dllexport) int pcl_cache_restore(void* L) {
    u64 save=0,piece=0,saveclass=0,piececlass=0;
    if(!arg(L,1,save)||!arg(L,2,piece)||!arg(L,3,saveclass)||!arg(L,4,piececlass))return result(L,-1);
    int status=cache_guard();if(status!=1)return result(L,status);
    if(busy||!live(save)||!live(piece)||!live(saveclass)||!live(piececlass))return result(L,-7);
    u64 data=rd<u64>(save+0x30);
    if(rd<u64>(save+0x10)!=saveclass||rd<u64>(piece+0x10)!=piececlass||
       rd<u32>(save+0x38)!=1||!ptr(data)||rd<u32>(piece+0xD0)!=0)return result(L,-30);
    u32 count=rd<u32>(data+0xA0);
    if(count<1||count>6000||!ptr(rd<u64>(data+0x98)))return result(L,-31);
    busy=true;
    __try {
        u32 length=rd<u32>(data+0x180);
        if(length>32*1024*1024 || (length && !ptr(rd<u64>(data+0x178))))status=-37;
        else {
            // The stock download factory uses this loader for save data and preview decode.
            ((void(*)(u64,u64))(image+0x45BB590))(piece,data);
            status=(rd<u32>(piece+0xD0)==count)?1:-32;
        }
    } __except(1){status=-33;}
    busy=false;return result(L,status);
}
extern "C" __declspec(dllexport) int pcl_cache_rebuild(void* L) {
    u64 host=0,piece=0,active=0,gm=0;
    if(!arg(L,1,host)||!arg(L,2,piece)||!arg(L,3,active)||!arg(L,4,gm))return result(L,-1);
    int status=cache_guard();if(status!=1)return result(L,status);
    if(busy||!live(host)||!live(piece)||!live(active)||!live(gm))return result(L,-7);
    if(host==active||rd<u64>(host+0x10)!=rd<u64>(active+0x10)||rd<u64>(host+0x428)!=piece||
       rd<u64>(active+0x428)==piece||rd<u64>(gm+0x448)!=active)return result(L,-34);
    busy=true;
    __try {((void(*)(u64,u64))(image+0x45B8550))(host,piece);status=1;}
    __except(1){status=-35;}
    busy=false;return result(L,status);
}

// Read the four native fixed-array ALineRenderer pointers. The SDK property
// has ArrayDim=4, not a TArray header; never interpret it as dynamic array data.
extern "C" __declspec(dllexport) int pcl_cache_lines(void* L) {
    u64 interaction=0,host=0,frontend=0;
    int status=cache_guard();u64 lines[4]={};
    if(!arg(L,1,interaction)||!arg(L,2,host)||!arg(L,3,frontend))status=-1;
    if(status==1) {
        __try {
            if(!live(interaction)||!live(host)||!live(frontend) ||
               rd<u64>(interaction+0x30)!=host || rd<u64>(interaction+0x38)!=frontend ||
               rd<u64>(host+0x2F8)!=frontend)status=-38;
            else for(u32 i=0;i<4;++i) {
                u64 actor=rd<u64>(interaction+0xC0+8ull*i);
                if(live(actor))lines[i]=actor;
            }
        } __except(1){status=-39;}
    }
    result(L,status);
    for(u32 i=0;i<4;++i)result(L,status==1?(i64)lines[i]:0);
    return 5;
}

// Read-only UObject identity query. Unlike UE4SS IsValid, every dereference is
// protected by SEH. No StaticFindObject/path lookup and no UObject mutation.
extern "C" __declspec(dllexport) int pcl_cache_valid(void* L) {
    u64 object=0;
    int status=guard();
    if(status!=1)return result(L,status);
    if(!arg(L,1,object)||!ptr(object))return result(L,0);
    i64 serial=0;
    __try {
        const u64 objects=image+0x865C7D0;
        u32 index=rd<u32>(object+0xC); // verified UObjectBase::InternalIndex_Private
        if(index<rd<u32>(objects+0x24)) {
            u64 chunks=rd<u64>(objects+0x10);
            if(ptr(chunks)) {
                u64 chunk=rd<u64>(chunks+8ull*(index>>16));
                if(ptr(chunk)) {
                    u64 item=chunk+24ull*(index&0xFFFF);
                    if(rd<u64>(item+8)==object && !(rd<u32>(item+4)&0x10200000u)) {
                        serial=rd<u32>(item+0x10);
                        // Assign a serial only for a confirmed live object,
                        // through the same engine API used by existing bridges.
                        if(!serial) {
                            struct Weak {u32 index,serial;} weak={};
                            ((void(*)(Weak*,u64*))(image+0x1499320))(&weak,&object);
                            serial=weak.serial;
                        }
                    }
                }
            }
        }
    } __except(1){serial=0;}
    return result(L,serial);
}

extern "C" __declspec(dllimport) int __stdcall OpenClipboard(void*);
extern "C" __declspec(dllimport) int __stdcall CloseClipboard();
extern "C" __declspec(dllimport) int __stdcall EmptyClipboard();
extern "C" __declspec(dllimport) void* __stdcall SetClipboardData(u32,void*);
extern "C" __declspec(dllimport) void* __stdcall GlobalAlloc(u32,u64);
extern "C" __declspec(dllimport) void* __stdcall GlobalLock(void*);
extern "C" __declspec(dllimport) int __stdcall GlobalUnlock(void*);
extern "C" __declspec(dllimport) void* __stdcall GlobalFree(void*);
extern "C" __declspec(dllimport) void* __stdcall GetActiveWindow();
extern "C" __declspec(dllexport) int pcl_cache_copy_word(void* L) {
    int status=guard();if(status!=1)return result(L,status);
    u64 length=0;if(!arg(L,1,length)||length<5||length>160)return result(L,-1);
    unsigned short text[161]={};u32 hyphens=0;
    for(u32 i=0;i<length;++i) {
        u64 byte=0;if(!arg(L,i+2,byte)||!((byte>='a'&&byte<='z')||(byte>='A'&&byte<='Z')||byte=='-'))return result(L,-1);
        text[i]=(unsigned short)byte;if(byte=='-')++hyphens;
    }
    if(hyphens!=2)return result(L,-1);
    void* memory=GlobalAlloc(2,(length+1)*2);if(!memory)return result(L,-40);
    unsigned short* output=(unsigned short*)GlobalLock(memory);
    if(!output){GlobalFree(memory);return result(L,-40);}
    for(u32 i=0;i<=length;++i)output[i]=text[i];
    GlobalUnlock(memory);
    // A real application window owns clipboard data; NULL ownership after
    // EmptyClipboard would cause SetClipboardData to fail on Windows.

    void* window=GetActiveWindow();
    if(!window||!OpenClipboard(window)){GlobalFree(memory);return result(L,-41);}
    bool copied=EmptyClipboard()&&SetClipboardData(13,memory)!=0; // CF_UNICODETEXT
    CloseClipboard();if(!copied)GlobalFree(memory);
    return result(L,copied?1:-42);
}
