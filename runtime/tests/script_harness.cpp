// Host-only API contract/logic test. This does not emulate TOTK or verify ABI offsets.
#include <angelscript.h>
#include <scriptstdstring.h>
#include <scriptmath.h>
#include <cassert>
#include <cmath>
#include <fstream>
#include <iostream>
#include <iterator>
#include <string>
#include <vector>
using namespace AngelScript;
struct Vec { float x, y, z; };
struct Mat { float a[9]={1,0,0,0,1,0,0,0,1}; };
struct Actor { std::string name="SpObj_Cart_A_01"; Vec pos{10,20,30}; Mat rot; } player, cart;
struct Body { Vec vel{0,-2,0}; } body;
Actor* resident=&player;
Actor* watched=nullptr;
bool paused=false, bodyExists=true, spawnWorks=true;
int sleeps=0, writes=0, rotations=0, spawns=0;
int freezes=0, unfreezes=0;
int pins=0,padReads=0,padExitAfter=61,padX=5000,padY=32767,pauseAfter=-1,padHeldReads=0;
bool invalidBridge=false;
int residentStopAfter=-1,heldButtonMask=0x2300,loadingAfter=-1;bool expectedAbort=false;
constexpr uint64_t padAddress=0x14000000+0x3d90b8;
std::vector<Vec> velocities;
void message(const asSMessageInfo* m, void*) {
    std::cerr<<m->section<<":"<<m->row<<":"<<m->col<<": "<<m->message<<"\n";
}
void noop(asIScriptGeneric*) {}
void generic(asIScriptGeneric* g) {
    const auto name=std::string(g->GetFunction()->GetName());
    if(name=="get") { g->SetReturnAddress(watched); }
    else if(name=="clearSlot") { watched=nullptr; }
    else if(name=="isPauseRequest" || name=="isPauseTarget") { g->SetReturnByte(paused || (loadingAfter>=0 && sleeps>=loadingAfter)); }
    else if(name=="getName") { new(g->GetAddressOfReturnLocation()) std::string(static_cast<Actor*>(g->GetObject())->name); }
    else if(name=="getMainRigidBody") { g->SetReturnAddress(bodyExists ? &body : nullptr); }
    else if(name=="get_vel") { new(g->GetAddressOfReturnLocation()) Vec(body.vel); }
    else if(name=="setVel") {
        body.vel={g->GetArgFloat(0),g->GetArgFloat(1),g->GetArgFloat(2)};
        velocities.push_back(body.vel); writes++;
    }
    else if(name=="setRot") { rotations++; for(int i=0;i<9;i++) cart.rot.a[i]=g->GetArgFloat(i); }
    else if(name=="get_rot") { new(g->GetAddressOfReturnLocation()) Mat(cart.rot); }
    else if(name=="setPos") { pins++; }
    else if(name=="sleep") { sleeps++; if(sleeps==pauseAfter) paused=true; if(sleeps==residentStopAfter) asGetActiveContext()->Abort(); }
    else if(name=="createAndWatch") { spawns++; if(spawnWorks) watched=&cart; }
    else if(name=="freeze" || name=="freezeAtActorWatcher") { freezes++; }
    else if(name=="toggleFreeze") { unfreezes++; }
    else if(name=="ptr_from_ActorBase") { g->SetReturnQWord(0x1000); }
    else if(name=="ptr_from_sym") { g->SetReturnQWord(0x10000000); }
    else if(name=="ptr_deref_u32") {
        auto p=g->GetArgQWord(0);
        if(p==0x10000000) g->SetReturnDWord(invalidBridge ? 0 : 0x950196e0);
        else if(p==0x14065b80) g->SetReturnDWord(0xf0001382);
        else if(p==0x14065b84) g->SetReturnDWord(0xa9be7bfd);
        else { assert(p==0x102c || p==0x1024); g->SetReturnDWord(4); }
    }
    else if(name=="ptr_deref_u64") { assert(g->GetArgQWord(0)==padAddress); padReads++; g->SetReturnQWord(padReads<=padHeldReads ? heldButtonMask : (padReads>padExitAfter ? 2 : 0)); }
    else if(name=="ptr_deref_s32") {
        auto p=g->GetArgQWord(0); assert(p==padAddress+8 || p==padAddress+12);
        g->SetReturnDWord(p==padAddress+8 ? padX : padY);
    }
    else if(name=="get_pos_x") g->SetReturnFloat(static_cast<Actor*>(g->GetObject())->pos.x);
    else if(name=="get_pos_y") g->SetReturnFloat(static_cast<Actor*>(g->GetObject())->pos.y);
    else if(name=="get_pos_z") g->SetReturnFloat(static_cast<Actor*>(g->GetObject())->pos.z);
}
void vecConstruct(asIScriptGeneric* g) { new(g->GetObject()) Vec{}; }
void vecCopy(asIScriptGeneric* g) { new(g->GetObject()) Vec(*static_cast<Vec*>(g->GetArgObject(0))); }
void matConstruct(asIScriptGeneric* g) { new(g->GetObject()) Mat{}; }
void matCopy(asIScriptGeneric* g) { new(g->GetObject()) Mat(*static_cast<Mat*>(g->GetArgObject(0))); }
void registerApi(asIScriptEngine* e) {
    RegisterStdString(e); RegisterScriptMath(e);
    assert(e->RegisterTypedef("u32", "uint")>=0);
    assert(e->RegisterTypedef("index_t", "uint64")>=0);
    assert(e->RegisterTypedef("ptr_t", "uint64")>=0);
    assert(e->RegisterObjectType("Vector3f",sizeof(Vec),asOBJ_VALUE|asOBJ_POD|asOBJ_APP_CLASS_CAK|asOBJ_APP_CLASS_ALLFLOATS)>=0);
    assert(e->RegisterObjectProperty("Vector3f","float x",asOFFSET(Vec,x))>=0);
    assert(e->RegisterObjectProperty("Vector3f","float y",asOFFSET(Vec,y))>=0);
    assert(e->RegisterObjectProperty("Vector3f","float z",asOFFSET(Vec,z))>=0);
    assert(e->RegisterObjectBehaviour("Vector3f",asBEHAVE_CONSTRUCT,"void f()",asFUNCTION(vecConstruct),asCALL_GENERIC)>=0);
    assert(e->RegisterObjectBehaviour("Vector3f",asBEHAVE_CONSTRUCT,"void f(const Vector3f &in)",asFUNCTION(vecCopy),asCALL_GENERIC)>=0);
    assert(e->RegisterObjectType("Matrix33f",sizeof(Mat),asOBJ_VALUE|asOBJ_POD|asOBJ_APP_CLASS_CAK|asOBJ_APP_CLASS_ALLFLOATS)>=0);
    for(int i=0;i<9;i++) assert(e->RegisterObjectProperty("Matrix33f",("float a"+std::to_string(i)).c_str(),i*4)>=0);
    assert(e->RegisterObjectBehaviour("Matrix33f",asBEHAVE_CONSTRUCT,"void f()",asFUNCTION(matConstruct),asCALL_GENERIC)>=0);
    assert(e->RegisterObjectBehaviour("Matrix33f",asBEHAVE_CONSTRUCT,"void f(const Matrix33f &in)",asFUNCTION(matCopy),asCALL_GENERIC)>=0);
    for(auto type:{"ActorBase","RigidBody"}) assert(e->RegisterObjectType(type,0,asOBJ_REF|asOBJ_NOCOUNT)>=0);
    auto meth=[&](const char* t,const char* d){assert(e->RegisterObjectMethod(t,d,asFUNCTION(generic),asCALL_GENERIC)>=0);};
    meth("ActorBase","string getName()"); meth("ActorBase","RigidBody@ getMainRigidBody()");
    meth("ActorBase","float get_pos_x() property"); meth("ActorBase","float get_pos_y() property"); meth("ActorBase","float get_pos_z() property");
    meth("ActorBase","void setRot(float, float, float, float, float, float, float, float, float)");
    meth("ActorBase","Matrix33f get_rot() property"); meth("ActorBase","void setPos(float,float,float)");
    meth("RigidBody","Vector3f get_vel() property"); meth("RigidBody","void setVel(float, float, float)");
    auto fun=[&](const char* ns,const char* d){e->SetDefaultNamespace(ns);assert(e->RegisterGlobalFunction(d,asFUNCTION(generic),asCALL_GENERIC)>=0);};
    e->SetDefaultNamespace(""); assert(e->RegisterGlobalProperty("ActorBase@ Player",&resident)>=0);
    assert(e->RegisterEnum("Button")>=0);
    for(auto b: {std::pair{"ZL",1<<8},std::pair{"ZR",1<<9},std::pair{"DUP",1<<13},std::pair{"DRIGHT",1<<14},std::pair{"DDOWN",1<<15},std::pair{"DLEFT",1<<12}}) assert(e->RegisterEnumValue("Button",b.first,b.second)>=0);
    fun("","void sleep(u32 duration=1)");
    fun("ActorWatcher","void pauseSlot(index_t)");
    fun("ActorWatcher","ActorBase@ get(index_t)"); fun("ActorWatcher","void clearSlot(index_t)");
    fun("ActorWatcher","void doTextWriter(index_t, bool)"); fun("ActorWatcher","void doWSLog(index_t, bool)");
    fun("actor","void createAndWatch(index_t, const string &in, float, float, float)");
    fun("pause","bool isPauseRequest(const string &in)"); fun("pause","bool isPauseTarget(const string &in)");
    fun("TextWriter","void toast(u32, const string &in)");
    fun("sys","void debugLog(const string &in)");
    fun("","ptr_t ptr_from_ActorBase(ActorBase@)");
    fun("","u32 ptr_deref_u32(ptr_t)");
    fun("","ptr_t ptr_from_sym(const string &in)");
    fun("","uint64 ptr_deref_u64(ptr_t)"); fun("","int ptr_deref_s32(ptr_t)");
    fun("camera","void freeze(float,float,float,double,double,double,double,double,double)");
    fun("camera","void toggleFreeze()");
    fun("camera","void freezeAtActorWatcher(index_t,float,const Vector3f &in,float,bool,bool)");
    fun("hotkey","void bindButtonsExecFile(uint64, const string &in)"); fun("hotkey","void setCooldown(uint8)");
    e->SetDefaultNamespace("");
}
void reset() { resident=&player; watched=&cart; cart.name="SpObj_Cart_A_01"; cart.rot=Mat{}; paused=false; bodyExists=true; spawnWorks=true; sleeps=writes=rotations=spawns=freezes=unfreezes=pins=padReads=padHeldReads=0; padExitAfter=61; padX=5000;padY=32767;pauseAfter=-1;invalidBridge=false;residentStopAfter=loadingAfter=-1;heldButtonMask=0x2300;expectedAbort=false; body.vel={0,-2,0}; velocities.clear(); }
void run(asIScriptEngine* e,const std::string& path) {
    std::ifstream file(path); assert(file.good());
    std::string src((std::istreambuf_iterator<char>(file)),{});
    assert(src.size()<8192);
    auto m=e->GetModule("test",asGM_ALWAYS_CREATE);
    assert(m->AddScriptSection(path.c_str(),src.c_str(),src.size())>=0);
    assert(m->Build()>=0);
    auto c=e->CreateContext(); assert(c->Prepare(m->GetFunctionByDecl("void main()"))>=0);
    int state=c->Execute();
    if(state!=asEXECUTION_FINISHED && !expectedAbort) std::cerr<<"Execution failed: "<<c->GetExceptionString()<<"\n";
    assert(state==(expectedAbort ? asEXECUTION_ABORTED : asEXECUTION_FINISHED)); c->Release();
}
int main(int argc,char** argv) {
    assert(argc>=2); auto e=asCreateScriptEngine();
    e->SetMessageCallback(asFUNCTION(message),nullptr,asCALL_CDECL);
    e->SetEngineProperty(asEP_ALWAYS_IMPL_DEFAULT_CONSTRUCT,2);
    e->SetEngineProperty(asEP_ALWAYS_IMPL_DEFAULT_COPY_CONSTRUCT,2);
    e->SetEngineProperty(asEP_ALWAYS_IMPL_DEFAULT_COPY,2);
    registerApi(e); std::string dir=argv[1];
    reset(); run(e,dir+"/autorun.as"); assert(spawns==0 && writes==0);
    reset(); watched=nullptr; run(e,dir+"/spawn.as"); assert(spawns==1 && watched==&cart);
    reset(); run(e,dir+"/spawn.as"); assert(spawns==0);
    reset(); watched=nullptr; spawnWorks=false; run(e,dir+"/spawn.as"); assert(sleeps==120 && watched==nullptr);
    reset(); paused=true; run(e,dir+"/spawn.as"); assert(spawns==0);
    reset(); run(e,dir+"/drive_smoke.as"); assert(writes==90 && sleeps==90 && rotations==90);
    for(auto v:velocities) { assert(v.y==-2); assert(std::isfinite(v.x)&&std::isfinite(v.z)); assert(std::hypot(v.x,v.z)<=6.001f); }
    assert(body.vel.x==0 && body.vel.z==0);
    reset(); paused=true; run(e,dir+"/drive_smoke.as"); assert(writes==0 && watched==nullptr);
    reset(); cart.name="Player"; run(e,dir+"/drive_smoke.as"); assert(writes==0);
    reset(); bodyExists=false; run(e,dir+"/drive_smoke.as"); assert(writes==0);
    reset(); watched=nullptr; run(e,dir+"/drive_smoke.as"); assert(writes==0);
    reset(); run(e,dir+"/clear.as"); assert(writes==1 && body.vel.y==-2 && watched==nullptr);
    if(argc>2) { reset(); run(e,argv[2]); assert(writes==1 && rotations==1 && body.vel.y==-2); }
    if(argc>3) {
        reset(); player.pos={-253,132,-152}; watched=nullptr;
        run(e,argv[3]); assert(spawns==1 && writes==91 && freezes==2 && unfreezes==1 && watched==nullptr);
        for(auto v:velocities) assert(v.y==-2 && std::hypot(v.x,v.z)<=6.001f);
        reset(); resident=nullptr; watched=nullptr;
        run(e,argv[3]); assert(spawns==0 && freezes==0 && sleeps==9000);
        reset(); player.pos={-253,132,-152}; watched=nullptr; bodyExists=false;
        run(e,argv[3]); assert(spawns==1 && writes==0 && freezes==0 && watched==nullptr);
        reset(); player.pos={-253,132,-152};
        run(e,argv[3]); assert(spawns==0 && writes==0 && freezes==0);
        std::cout<<"PASS: one-shot diagnostic compilation, bounds, camera cleanup, world timeout, null body and occupied slot.\n";
    }
    if(argc>4) {
        auto setup=[&](){reset();player.pos={-253,132,-152};watched=nullptr;};
        setup();run(e,argv[4]);assert(spawns==1 && pins==60 && writes==61 && freezes==2 && unfreezes==1 && watched==nullptr);
        for(auto v:velocities) assert(v.y==-2 && std::isfinite(v.x) && std::isfinite(v.z) && std::hypot(v.x,v.z)<=3.001f);
        setup();padY=-32768;run(e,argv[4]);for(auto v:velocities) assert(v.y==-2 && std::hypot(v.x,v.z)<=3.001f);
        setup();padX=padY=0;padExitAfter=2000;run(e,argv[4]);assert(pins==900 && writes==901 && watched==nullptr && freezes==2 && unfreezes==1);
        setup();invalidBridge=true;run(e,argv[4]);assert(spawns==0 && writes==0 && pins==0 && freezes==0);
        setup();paused=true;run(e,argv[4]);assert(spawns==0 && writes==0 && freezes==0);
        setup();padX=40000;run(e,argv[4]);assert(pins==0 && writes==1 && watched==nullptr && unfreezes==1);
        setup();pauseAfter=20;run(e,argv[4]);assert(pins==20 && watched==nullptr && unfreezes==1);
        setup();padHeldReads=5;run(e,argv[4]);assert(pins==55 && unfreezes==1 && watched==nullptr);
        setup();padHeldReads=1000;run(e,argv[4]);assert(spawns==0 && pins==0 && freezes==0 && sleeps==90);
        std::cout<<"PASS: native-pad driver compilation, bridge rejection, speed cap/Y preservation, B exit, timeout, input range, pause cleanup.\n";
    }
    if(argc>5) {
        auto setup=[&](){reset();player.pos={-253,132,-152};cart.pos={-253,132,-156};watched=nullptr;};
        setup();run(e,argv[5]);assert(spawns==1 && pins==60 && writes==61 && watched==nullptr && unfreezes==1);
        setup();watched=&cart;run(e,argv[5]);assert(spawns==0 && pins==60 && writes==61 && watched==nullptr && unfreezes==1);
        setup();watched=&cart;cart.pos.x+=13;run(e,argv[5]);assert(spawns==0 && writes==0 && pins==0 && freezes==0);
        setup();watched=&cart;cart.name="Player";run(e,argv[5]);assert(spawns==0 && writes==0 && pins==0);
        setup();watched=&cart;bodyExists=false;run(e,argv[5]);assert(spawns==0 && writes==0 && pins==0);
        setup();padX=padY=0;padExitAfter=10000;run(e,argv[5]);assert(pins==9000 && writes==9001 && watched==nullptr && unfreezes==1);
        setup();player.pos={1200,400,800};run(e,argv[5]);assert(spawns==1 && pins==60 && watched==nullptr);
        setup();invalidBridge=true;run(e,argv[5]);assert(spawns==0 && writes==0);
        setup();padHeldReads=1000;run(e,argv[5]);assert(spawns==0 && sleeps==90 && writes==0);
        std::cout<<"PASS: revised controller adopts nearby kart, rejects invalid/distant/bodyless kart, spawns outside Lookout, bounds duration and cleans up.\n";
    }
    if(argc>6) {
        reset();run(e,std::string(argv[6])+"/autorun.as");assert(spawns==0 && writes==0);
        reset();watched=nullptr;run(e,std::string(argv[6])+"/spawn.as");assert(spawns==1 && watched==&cart);
        reset();run(e,std::string(argv[6])+"/spawn.as");assert(spawns==0);
        std::cout<<"PASS: revised local autorun and spawn scripts compile and retain no-auto-spawn/occupied guards.\n";
    }
    if(argc>7) {
        auto setup=[&](){reset();player.pos={-253,132,-152};cart.pos={-253,132,-156};watched=&cart;};
        setup();float z=std::sqrt(0.5f);cart.rot.a[0]=z;cart.rot.a[1]=-z;cart.rot.a[3]=z;cart.rot.a[4]=z;
        run(e,argv[7]);assert(spawns==0 && pins==60 && writes==61 && watched==nullptr && unfreezes==1);
        assert(cart.rot.a[1]==0 && cart.rot.a[3]==0 && cart.rot.a[4]==1 && cart.rot.a[5]==0 && cart.rot.a[7]==0);
        assert(std::abs(cart.rot.a[0]*cart.rot.a[8]-cart.rot.a[2]*cart.rot.a[6]-1)<0.00001f);
        for(auto v:velocities)assert(v.y==-2 && std::isfinite(v.x) && std::hypot(v.x,v.z)<=0.8001f);
        setup();padY=-32768;run(e,argv[7]);for(auto v:velocities)assert(v.y==-2 && std::hypot(v.x,v.z)<=0.8001f);
        setup();padX=padY=0;padExitAfter=10000;run(e,argv[7]);assert(pins==9000 && writes==9001 && rotations==0 && unfreezes==1);
        setup();invalidBridge=true;run(e,argv[7]);assert(spawns==0 && writes==0 && pins==0);
        setup();pauseAfter=20;run(e,argv[7]);assert(pins==20 && unfreezes==1 && watched==nullptr);
        std::cout<<"PASS: flat-road controller upright orthonormal yaw, lower forward/reverse cap, idle rotation avoidance, bridge/pause guards and cleanup.\n";
    }
    if(argc>8) {
        auto setup=[&](){reset();player.pos={-253,132,-152};cart.pos={-253,132,-156};watched=nullptr;residentStopAfter=120;expectedAbort=true;};
        setup();padX=padY=0;run(e,argv[8]);assert(spawns==0 && writes==0 && pins==0 && sleeps==120);
        setup();heldButtonMask=0x4300;padHeldReads=2;run(e,argv[8]);assert(spawns==1 && pins>0 && pins<120 && unfreezes==1 && watched==nullptr);
        for(auto v:velocities)assert(v.y==-2 && std::hypot(v.x,v.z)<=0.8001f);
        setup();heldButtonMask=0x2300;padHeldReads=4;run(e,argv[8]);assert(spawns==1 && pins==0 && watched==&cart);
        setup();heldButtonMask=0x8300;padHeldReads=4;run(e,argv[8]);assert(spawns==0 && pins==0 && watched==nullptr);
        setup();heldButtonMask=0x4300;padHeldReads=2;loadingAfter=30;run(e,argv[8]);assert(pins>0 && pins<35 && watched==nullptr && unfreezes==1);
        setup();invalidBridge=true;expectedAbort=false;run(e,argv[8]);assert(spawns==0 && writes==0 && sleeps==0);
        std::cout<<"PASS: resident controller startup does not spawn; direct Up/Right/Down dispatch, input release, reduced speed, LoadingPause cleanup and signature rejection.\n";
    }
    e->ShutDownAndRelease(); std::cout<<"PASS: all four scripts compile; 11 host logic scenarios passed. Game ABI and runtime remain untested.\n";
}
