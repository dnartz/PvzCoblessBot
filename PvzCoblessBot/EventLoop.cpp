#include "stdafx.h"
#include <thread>
#include <fstream>
#include <sstream>
#include <algorithm>
#include "lua.hpp"

#include "Mouse.h"
#include "EventLoop.h"
#include "GameMemory.h"
#include "LuaInterface.h"

namespace PvzCoblessBot {

using Memory::Context;
using Memory::MemoryScanner;

EventLoop::EventLoop(): logger("事件循环") { 
    L = luaL_newstate();
    if (L == nullptr) {
        logger.ErrorHalt("无法创建lua_State对象，内存可能不足。", false);
    }

    luaL_openlibs(L);
}

void EventLoop::InitLua() {
    lua_register(L, "Wait", Delay);
    lua_register(L, "WaitUntilSpawn", WaitUntilSpawn);
    lua_register(L, "WaitBeforeSpawn", WaitBeforeSpawn);
    lua_register(L, "SetTickCoroutine", SetTickCoroutine);
    lua_register(L, "WaitUntilCardAvailable", WaitUntilCardAvailable);

    if (luaL_dostring(L, "package.path = '?.lua'") != 0 ||
        luaL_dofile(L, "Config.lua") != 0)
    {
        std::stringstream ss;
        ss << "初始化Lua环境失败。" << lua_tostring(L, -1);
        logger.ErrorHalt(ss.str().c_str(), false);
    }
}

void EventLoop::LoadLua(const char *file) {
    std::ostringstream ss;

    switch (luaL_loadfile(L, file)) {
        case 0: return;

        case LUA_ERRSYNTAX:
            ss << "Lua脚本" << file << "编译失败：" << lua_tostring(L, -1);
            break;

        case LUA_ERRMEM:
            ss << "Lua脚本" << file << "加载失败，内存不足。";
            break;

        case LUA_ERRERR:
            ss << "Lua脚本" << file << "加载失败，无法读取。";
            break;

        default:
            ss << "Lua脚本" << file << "加载失败。";
    }

    logger.ErrorHalt(ss.str().c_str(), false);
}

void EventLoop::RunLua(lua_State *co) {
    auto result = lua_resume(co, 0);

    if (result != 0 && result != LUA_YIELD) {
        lua_getglobal(co, "debug");
        lua_getfield(co, -1, "traceback");
        lua_pushvalue(co, -3);
        lua_call(co, 1, 1);

        std::stringstream ss;
        ss << "Lua脚本运行错误：" << lua_tostring(co, -1);
        logger.ErrorHalt(ss.str().c_str(), false);
    }
}

void EventLoop::RunLua() {
    RunLua(L);
}

static void PickUpItems(struct Context *context) {
    static auto& mouse = Mouse::GetInstance();
    for (int32_t i = 0; i < context->nItems; i++) {
        mouse.LeftClick(
            static_cast<uint32_t>(context->items[i].x),
            static_cast<uint32_t>(context->items[i].y));
        mouse.Reset();
    }
}

void EventLoop::Loop() {
    InitLua();

    static auto &ms = MemoryScanner::GetInstance();
    ms.WaitUntilGameProcessOpened();
    ms.WaitUntilInGame();

    std::thread memoryScanThread(&MemoryScanner::ScanLoop, &ms);

    while (context == nullptr) {
        context.reset(ms.GetContext());
    }

    LoadAndRunLua("Common.lua");
    LoadAndRunLua("main.lua");

    currentWave = 0;
    while (true) {
        context.reset(ms.GetContext());

        if (currentWave < context->currentWave) {
            currentWave = context->currentWave;

            std::stringstream ss;
            ss << "==========第" << currentWave << "波==========";
            logger.Info(ss.str());
        }

        PickUpItems(context.get());

        RunLua(tickCouroutine);

        cardCoroutines.remove_if([&](struct CardCoroutine &co) {
            if (context->cards[co.cardIndex].available) {
                RunLua(co.L);
                return true;
            } else {
                return false;
            }
        });

        spawnCountdownCoroutines.remove_if(
        [&](struct SpawnCountdownCoroutine &co) {
            if (context->currentWave >= co.wave ||
                co.timeout != -1 && co.timeout <= context->gameTime ||
                co.wave == context->currentWave + 1 &&
                co.countdown >= context->spawnCountdown)
            {
                RunLua(co.L);
                return true;
            } else {
                return false;
            }
        });

        delayCoroutines.remove_if([&](struct DelayCoroutine &co) {
            if (co.wakeUpAt <= context->gameTime) {
                RunLua(co.L);
                return true;
            } else {
                return false;
            }
        });

        spawnCoroutines.remove_if([&](struct SpawnCoroutine &co) {
            if (co.wave <= context->currentWave) {
                if (co.delay == 0 ||
                    co.timeout != -1 &&
                    co.timeout <= context->gameTime)
                {
                    RunLua(co.L);
                } else {
                    delayCoroutines.emplace_back(
                        context->currentFlag,
                        context->gameTime + co.delay,
                        co.L
                    );
                }
                return true;
            } else {
                return false;
            }
        });
    }

    memoryScanThread.join();
    return;
}

} // namespace PvzCoblessBot