#pragma once
#include <lua.hpp>

#include "GameMemory.h"

extern "C" {
    __declspec(dllexport) void SelectCard(int len, int *cards);

    __declspec(dllexport) bool
    GrowPlant(int type, int row, int col, bool brutal, bool remove);

    int Delay(lua_State *L);
    int WaitUntilSpawn(lua_State *L);
    int WaitBeforeSpawn(lua_State *L);

    int SetTickCoroutine(lua_State *L);
    int WaitUntilCardAvailable(lua_State *L);

    __declspec(dllexport) PvzCoblessBot::Memory::Context *GetGameContext();

    __declspec(dllexport) bool IsCardAvailable(int plant);
    __declspec(dllexport) int GetCardColdDown(int plant);

    __declspec(dllexport) bool *GetZombieLineup();
    __declspec(dllexport) uint32_t *GetZombieSpawnList();

    __declspec(dllexport) void *NewLogger(
        const char *name,
        unsigned short info,
        unsigned short warn,
        unsigned short error
    );
    __declspec(dllexport) void FreeLogger(void *logger);
    __declspec(dllexport) void LogInfo(void *p, const char *log);
    __declspec(dllexport) void LogWarn(void *p, const char *log);
    __declspec(dllexport) void LogError(void *p, const char *log);
    __declspec(dllexport) void LogErrorHalt(void *p, const char *log);
}
