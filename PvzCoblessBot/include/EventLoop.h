#pragma once
#include <stdint.h>
#include <memory>
#include <list>
#include <lua.hpp>

#include "GameMemory.h"

namespace PvzCoblessBot {

using Memory::Card;
using Memory::Zombie;
using Memory::PlantType;

struct DelayCoroutine {
    int32_t flag;
    int32_t wakeUpAt;
    lua_State *L;

    DelayCoroutine(
        int32_t flag,
        int32_t wake,
        lua_State *L
    ): flag(flag), wakeUpAt(wake), L(L) { }
};

struct CardCoroutine {
    int32_t flag;
    int32_t cardIndex;
    lua_State *L;

    CardCoroutine(
        int32_t flag,
        int32_t cardIndex,
        lua_State *L
    ): flag(flag), cardIndex(cardIndex), L(L) { }
};

struct SpawnCoroutine {
    int32_t flag;
    int32_t wave;
    int32_t delay;
    int32_t timeout;
    lua_State *L;

    SpawnCoroutine(
        int32_t flag,
        int32_t wave, 
        int32_t delay,
        int32_t timeout,
        lua_State *L
    ): flag(flag), wave(wave), delay(delay), timeout(timeout), L(L) { }
};

struct SpawnCountdownCoroutine {
    int32_t flag;
    int32_t wave;
    int32_t countdown;
    int32_t timeout;
    lua_State *L;

    SpawnCountdownCoroutine(
        int32_t flag,
        int32_t wave,
        int32_t countdown,
        int32_t timeout,
        lua_State *L
    ) : flag(flag), wave(wave), countdown(countdown), timeout(timeout), L(L) { }
};

class EventLoop {
private:
    explicit EventLoop();

    EventLoop(EventLoop &) = delete;
    EventLoop &operator=(EventLoop &) = delete;

    void InitLua();

public:
    int32_t levelBeginAt;
    int32_t currentWave;
    std::unique_ptr<struct Memory::Context> context;

    std::list<struct DelayCoroutine> delayCoroutines;
    std::list<struct SpawnCountdownCoroutine> spawnCountdownCoroutines;
    std::list<struct SpawnCoroutine> spawnCoroutines;
    std::list<struct CardCoroutine> cardCoroutines;

    lua_State *L;
    lua_State *tickCouroutine;

    Logger logger;

    static EventLoop &GetInstance() {
        static EventLoop loop{};
        return loop;
    }

    inline int32_t GetGameTime() {
        return context->gameTime;
    }

    void LoadLua(const char *file);
    void RunLua(lua_State *co);
    void RunLua();

    inline void LoadAndRunLua(const char *file) {
        LoadLua(file);
        RunLua();
    }

    void Loop();
};

} // namespace PvzCoblessBot 