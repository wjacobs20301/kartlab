// Host-only compile check for native controller scripts. Builds the module against the
// API surface recovered from compile_physics plus the LotusKit pointer-write functions
// (registered unconditionally in globals.cpp registerPtr). Does not execute or emulate TOTK.
#include <angelscript.h>
#include <scriptstdstring.h>
#include <scriptmath.h>
#include <cassert>
#include <fstream>
#include <iostream>
#include <iterator>
#include <string>
using namespace AngelScript;
struct Vec { float x, y, z; };
struct Mat { float a[9]; };
void message(const asSMessageInfo* m, void*) { std::cerr<<m->section<<":"<<m->row<<":"<<m->col<<": "<<m->message<<"\n"; }
void noop(asIScriptGeneric*) {}
#define OK(x) do{ if((x)<0){ std::cerr<<"register failed: "<<#x<<"\n"; return 2; } }while(0)
int main(int argc, char** argv) {
    // Optional limit: 8191 for the stock runtime, 65535 for runtime/candidates/large-script-110.
    if (argc != 2 && argc != 3) { std::cerr<<"usage: compile_wheels script.as [max_bytes=8191]\n"; return 2; }
    const unsigned long limit = argc == 3 ? std::stoul(argv[2]) : 8191;
    std::ifstream file(argv[1]); if (!file.good()) { std::cerr<<"cannot read "<<argv[1]<<"\n"; return 2; }
    std::string src((std::istreambuf_iterator<char>(file)), {});
    if (src.size() > limit) { std::cerr<<"script is "<<src.size()<<" bytes; runtime limit is "<<limit<<"\n"; return 1; }
    asIScriptEngine* e = asCreateScriptEngine();
    e->SetMessageCallback(asFUNCTION(message), nullptr, asCALL_CDECL);
    RegisterStdString(e); RegisterScriptMath(e);
    OK(e->RegisterTypedef("u32","uint")); OK(e->RegisterTypedef("index_t","uint64")); OK(e->RegisterTypedef("ptr_t","uint64")); OK(e->RegisterTypedef("u64","uint64")); OK(e->RegisterTypedef("u8","uint8")); OK(e->RegisterTypedef("s32","int"));
    OK(e->RegisterObjectType("Vector3f",sizeof(Vec),asOBJ_VALUE|asOBJ_POD|asOBJ_APP_CLASS));
    OK(e->RegisterObjectProperty("Vector3f","float x",asOFFSET(Vec,x)));
    OK(e->RegisterObjectProperty("Vector3f","float y",asOFFSET(Vec,y)));
    OK(e->RegisterObjectProperty("Vector3f","float z",asOFFSET(Vec,z)));
    OK(e->RegisterObjectType("Matrix33f",sizeof(Mat),asOBJ_VALUE|asOBJ_POD|asOBJ_APP_CLASS));
    for (int i=0;i<9;i++){ std::string d="float a"+std::to_string(i); OK(e->RegisterObjectProperty("Matrix33f",d.c_str(),i*4)); }
    OK(e->RegisterObjectType("ActorBase",0,asOBJ_REF|asOBJ_NOCOUNT));
    OK(e->RegisterObjectType("RigidBody",0,asOBJ_REF|asOBJ_NOCOUNT));
    const char* actor[]={"string getName()","RigidBody@ getMainRigidBody()","RigidBody@ getRigidBody(const string &in)",
        "float get_pos_x() property","float get_pos_y() property","float get_pos_z() property",
        "void setRot(float,float,float,float,float,float,float,float,float)","Matrix33f get_rot() property","void setPos(float,float,float)"};
    for (auto d: actor) OK(e->RegisterObjectMethod("ActorBase",d,asFUNCTION(noop),asCALL_GENERIC));
    const char* body[]={"void setAngularVel(float,float,float)","void setAngularVel(const Vector3f &in)","Vector3f get_vel() property",
        "void setVel(float,float,float)","void applyImpulse(float,float,float)"};
    for (auto d: body) OK(e->RegisterObjectMethod("RigidBody",d,asFUNCTION(noop),asCALL_GENERIC));
    static void* player=nullptr; OK(e->RegisterGlobalProperty("ActorBase@ Player",&player));
    OK(e->RegisterEnum("Button"));
    const char* names[]={"A","B","X","Y","L","R","ZL","ZR","PLUS","MINUS","DLEFT","DUP","DRIGHT","DDOWN"};
    int bits[]={0,1,2,3,6,7,8,9,10,11,12,13,14,15};
    for (int i=0;i<14;i++) OK(e->RegisterEnumValue("Button",names[i],1<<bits[i]));
    auto fun=[&](const char* ns,const char* d){ e->SetDefaultNamespace(ns); return e->RegisterGlobalFunction(d,asFUNCTION(noop),asCALL_GENERIC); };
    const char* root[]={"void sleep(u32 duration=1)","void input(uint duration=1,uint64 buttons=0,int x=0,int y=0,int rx=0,int ry=0)",
        "ptr_t ptr_from_sym(const string &in)","ptr_t ptr_from_ActorBase(ActorBase@)","ptr_t ptr_from_RigidBody(RigidBody@)",
        "u32 ptr_deref_u32(ptr_t)","uint64 ptr_deref_u64(ptr_t)","int ptr_deref_s32(ptr_t)","float ptr_deref_float(ptr_t)",
        "void ptr_write_u32(ptr_t,u32)","u64 ptr_call(ptr_t,u64,u64,u64,u64,u64,u64,u64,float,float,float,float)","float ptr_callf(ptr_t,u64,u64,u64,u64,u64,u64,u64,float,float,float,float)","void ptr_write_u64(ptr_t,uint64)","void ptr_write_float(ptr_t,float)","u8 ptr_deref_u8(ptr_t)","int16 ptr_deref_s16(ptr_t)","void ptr_write_u8(ptr_t,u8)"};
    for (auto d: root) OK(fun("",d));
    OK(fun("sys","void debugLog(const string &in)")); OK(fun("sys","ptr_t mainOffset()"));
    OK(fun("ActorWatcher","void pauseSlot(index_t)")); OK(fun("ActorWatcher","ActorBase@ get(index_t)"));
    OK(fun("ActorWatcher","void clearSlot(index_t)")); OK(fun("ActorWatcher","void doTextWriter(index_t,bool)"));
    OK(fun("ActorWatcher","void doWSLog(index_t,bool)")); OK(fun("ActorWatcher","void assignSlot(index_t,ptr_t)")); OK(fun("ActorWatcher","void assignSlotAwaitSpawn(index_t,const string &in)"));
    OK(fun("actor","void createSimple(const string &in,float,float,float)"));
    OK(fun("actor","void createAndWatch(index_t,const string &in,float,float,float)"));
    OK(fun("pause","bool isPauseRequest(const string &in)")); OK(fun("pause","bool isPauseTarget(const string &in)"));
    OK(fun("TextWriter","void toast(u32,const string &in)"));
    OK(fun("tas","void doBlockOnLoadingPause(bool)"));
    OK(fun("camera","void toggleFreeze()")); OK(fun("camera","void freeze(float, float, float, double, double, double, double, double, double)"));
    e->SetDefaultNamespace("");
    asIScriptModule* m = e->GetModule("main", asGM_ALWAYS_CREATE);
    OK(m->AddScriptSection(argv[1], src.data(), src.size()));
    if (m->Build() < 0) { std::cerr<<"BUILD FAILED: "<<argv[1]<<"\n"; return 1; }
    if (!m->GetFunctionByDecl("void main()")) { std::cerr<<"no void main()\n"; return 1; }
    std::cout<<"COMPILES: "<<argv[1]<<" ("<<src.size()<<" bytes)\n";
    e->ShutDownAndRelease();
    return 0;
}
