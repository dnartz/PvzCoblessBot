#include "stdafx.h"
#include <time.h>
#include <stdint.h>
#include <string.h>
#include <sstream>
#include <lua.hpp>

#include "Mouse.h"
#include "EventLoop.h"

// 如果没有选到足够多的卡，那么按一下ESC，退掉卡槽里所有的卡，然后再选一遍。
#define SELECT_CARD_RETRY do {\
    mouse.PressESC();\
    for (int i = 0; i <= 15; i++) {\
        mouse.LeftClick(100, 40);\
        Sleep(100);\
    }\
    memset(selected, 0, sizeof(selected));\
    goto again;\
} while(0)

extern "C" {

using PvzCoblessBot::Mouse;
using PvzCoblessBot::Logger;
using PvzCoblessBot::EventLoop;
using PvzCoblessBot::DelayCoroutine;
using PvzCoblessBot::Memory::PlantType;
using PvzCoblessBot::Memory::MemoryScanner;

__declspec(dllexport) void SelectCard(int len, int *cards) {
    static auto& mouse = Mouse::GetInstance();
    static auto& ms = MemoryScanner::GetInstance();
    static auto& loop = EventLoop::GetInstance();
    static Logger logger("卡片选取");

    bool selected[49] = { 0 };
    if (ms.GetCardsSelected() > 0) {
        SELECT_CARD_RETRY;
    }

    again:
    for (int i = 0; i < len; i++) {
        if (cards[i] < static_cast<int>(PlantType::Imitater) &&
            selected[cards[i]] ||
            cards[i] > static_cast<int>(PlantType::Imitater) &&
            selected[static_cast<int>(PlantType::Imitater)])
        {
            logger.ErrorHalt("选卡错误，有重复植物存在。", false);
        } else if (cards[i] > static_cast<int>(PlantType::Imitater)) {
            selected[static_cast<int>(PlantType::Imitater)] = true;
        } else {
            selected[cards[i]] = true;
        }

        int32_t row = cards[i] / 8,
                col = cards[i] % 8;
        if (static_cast<PlantType>(cards[i]) > PlantType::Imitater) {
            auto realType = cards[i] - static_cast<int>(PlantType::Imitater);
            if (realType >= static_cast<int>(PlantType::GatlingPea)) {
                logger.ErrorHalt("选卡错误，模仿者不能模仿紫卡。", false);
            }

            row = realType / 8;
            col = realType % 8;

            mouse.MoveTo(489, 538);
            Sleep(100);
            mouse.LeftClick(489, 538);
            Sleep(100);
            mouse.LeftClick(215 + 50 * col, 155 + 70 * row);
        } else {
            mouse.LeftClick(46 + 50 * col, 157 + 70 * row);
        }
    }

    Sleep(200);
    auto nCards = ms.GetCardsSelected();
    if (nCards == -1) {
        logger.ErrorHalt("无法获取当前已选取卡片数，请重启程序。", false);
    } else if (nCards < len) {
        SELECT_CARD_RETRY;
    }

    mouse.MoveTo(227, 567);
    Sleep(200);
    mouse.LeftClick(227, 567);

    int32_t gameBefore = ms.GetGameTime(), gameAfter;
    time_t before, after;
    time(&before);
    while (true) {
        gameAfter = ms.GetGameTime();
        if (gameAfter == -1) {
            logger.ErrorHalt("内存读取发生异常，无法确定游戏状态，请重启程序。", false);
        }

        if (gameAfter > gameBefore) {
            loop.levelBeginAt = gameBefore;
            loop.context.reset(ms.GetContext());
            return;
        }

        time(&after);
        if (after - before >= 7) {
            SELECT_CARD_RETRY;
        }
    }
}

int Delay(lua_State *L) {
    static auto& loop = EventLoop::GetInstance();

    auto cs = static_cast<int32_t>(luaL_checkinteger(L, 1));
    loop.delayCoroutines.emplace_back(
        loop.context->currentFlag,
        loop.context->gameTime + cs,
        L
    );
    return lua_yield(L, 0);
}

int WaitUntilSpawn(lua_State *L) {
    static auto& loop = EventLoop::GetInstance();

    int nargs, wave, delay = 0, timeout = -1;
    nargs = lua_gettop(L);
    if (nargs == 0) {
        wave = loop.context->currentWave + 1;
        if (wave > 20) {
            return 0;
        }
    } else if (nargs > 0 && nargs <= 3) {
        wave = static_cast<int32_t>(luaL_checkinteger(L, 1));
        if (!(0 < wave && wave < 21)) {
            lua_pushstring(L, "WaitUntilSpawn函数错误：传入的刷新波次参数不在取值范围中。");
            lua_error(L);
        }

        if (nargs == 2) {
            delay = luaL_checkinteger(L, 2);
        }

        if (nargs == 3) {
            timeout = luaL_checkinteger(L, 3) + loop.context->gameTime;
        }
    } else {
        lua_pushstring(L, "WaitUntilSpawn函数错误：传入了过多参数。");
        lua_error(L);
    }

    loop.spawnCoroutines.emplace_back(
        loop.context->currentFlag, wave, delay, timeout, L
    );
    return lua_yield(L, 0);
}

int WaitBeforeSpawn(lua_State *L) {
    static auto &loop = EventLoop::GetInstance();

    auto nargs = lua_gettop(L);
    if (nargs < 1) {
        lua_pushstring(L, "WaitBeforeSpawn函数错误：应至少传入一个参数。");
        lua_error(L);
    }

    int32_t countdown = luaL_checkinteger(L, 1);
    int32_t wave = loop.context->currentWave + 1;
    int32_t timeout = -1;
    if (nargs > 1) {
        wave = luaL_checkinteger(L, 2);
    }

    if (nargs > 2) {
        timeout = loop.context->gameTime + luaL_checkinteger(L, 3);
    }

    if (wave > 20) {
        lua_pushstring(L, "WaitBeforeSpawn函数错误：不可以等待超过20的波次。");
        lua_error(L);
    }

    if (wave <= loop.context->currentWave ||
        wave == loop.context->currentWave + 1 &&
        countdown >= loop.context->spawnCountdown)
    {
        return 0;
    }
    loop.spawnCountdownCoroutines.emplace_back(
        loop.context->currentFlag, wave, countdown, timeout, L
    );
    return lua_yield(L, 0);
}

bool __declspec(dllexport)
GrowPlant(int type, int row, int col, bool brutal, bool remove) {
    static Logger logger{"植物种植"};
    static auto& loop = EventLoop::GetInstance();
    static auto& mouse = Mouse::GetInstance();

    if (!brutal &&
        !remove &&
        // 如果此时修补的是南瓜，那么也就意味着那个位置可以种植植物。
        type != static_cast<int>(PlantType::Pumpkin) &&
        !loop.context->gridGrowable[row][col])
    {
        std::stringstream ss;
        ss << "第" << row + 1 << "行，第" << col + 1 << "列无法种植植物！";
        logger.Warn(ss.str());
        return false;
    }

    auto& cards = loop.context->cards;
    for (int i = 0; i < 10; i++) {
        if (cards[i].type == static_cast<PlantType>(type)) {
            if (!cards[i].available) {
                std::stringstream ss;
                ss << PLANT_TYPE_TO_NAME(cards[i].type) << "还在冷却中！";
                logger.Warn(ss.str());
                return false;
            }

            if (remove && !brutal && !loop.context->gridGrowable[col][row]) {
                mouse.LeftClick(638, 41);
                mouse.LeftClick(80 + 80 * col, 130 + 85 * row);
            }
            mouse.LeftClick(103 + 51 * i, 42);
            cards[i].available = false;
            cards[i].coldDown = 0;
            goto grow;
        }
    }

    {
        std::stringstream ss;
        if (type < 89) {
            ss << "卡槽内没有植物" << type << "请检查你的程序。";
        } else {
            ss << "卡槽内没有" << PLANT_TYPE_TO_NAME(type) << "请检查你的程序。";
        }
        logger.ErrorHalt(ss.str());
        return false;
    }

    grow:
    if (brutal) {
        for (int row = 0; row < 6; ++row) {
            for (int col = 0; col < 9; ++col) {
                mouse.LeftClick(80 + 80 * col, 130 + 85 * row);
            }
        }
    } else {
        mouse.LeftClick(80 + 80 * col, 130 + 85 * row);
    }

    mouse.Reset();

    return true;
}

int WaitUntilCardAvailable(lua_State *L) {
    static Logger logger("等待卡片CD");
    static auto& loop = EventLoop::GetInstance();

    auto plant = static_cast<PlantType>(luaL_checkint(L, 1));
    for (int i = 0; i < 10; i++) {
        const auto& card = loop.context->cards[i];
        if (card.type == plant) {
            if (card.available) {
                return 0;
            } else {
                std::stringstream ss;
                ss << PLANT_TYPE_TO_NAME(card.type)
                   << "尚未准备好，剩余冷却："
                   << (card.totalColdDown - card.coldDown)
                   << "。";
                logger.Warn(ss.str());

                loop.cardCoroutines.emplace_back(
                    loop.context->currentFlag, i, L
                );
                return lua_yield(L, 0);
            }
        }
    }

    lua_pushstring(L, "WaitUntilCardAvailable函数错误：传入的植物类型不在卡槽中。");
    lua_error(L);
    return 0;
}

int SetTickCoroutine(lua_State *L) {
    static auto& loop = EventLoop::GetInstance();
    loop.tickCouroutine = lua_tothread(L, -1);
    return 0;
}

__declspec(dllexport) bool IsCardAvailable(int plant) {
    static auto& loop = EventLoop::GetInstance();

    for (const auto& card : loop.context->cards) {
        if (static_cast<int>(card.type) == plant && card.available) {
            return true;
        }
    }

    return false;
}

__declspec(dllexport) PvzCoblessBot::Memory::Context *GetGameContext() {
    static auto& loop = EventLoop::GetInstance();
    return loop.context.get();
}

__declspec(dllexport) bool *GetZombieLineup() {
    static auto& ms = MemoryScanner::GetInstance();
    return ms.GetZombieLineup();
}

__declspec(dllexport) uint32_t *GetZombieSpawnList() {
    static auto& ms = MemoryScanner::GetInstance();
    return reinterpret_cast<uint32_t *>(ms.GetZombieSpawnList());
}

__declspec(dllexport) int GetCardColdDown(int plant) {
    static Logger logger("卡片CD查询");
    static auto& loop = EventLoop::GetInstance();

    for (const auto& card : loop.context->cards) {
        if (static_cast<int>(card.type) == plant) {
            if (card.available) {
                return 0;
            } else {
                return card.totalColdDown - card.coldDown;
            }
        }
    }

    std::stringstream ss;
    if (plant < 89) {
        ss << PLANT_TYPE_TO_NAME(plant) << "不存在于卡槽中。";
    } else {
        ss << "不存在的卡片：" << plant;
    }
    logger.ErrorHalt(ss.str());
    return 0;
}

__declspec(dllexport) void *NewLogger(
    const char *name,
    unsigned short info,
    unsigned short warn,
    unsigned short error
) {
    return new Logger(name, info, warn, error);
}

__declspec(dllexport) void FreeLogger(void *logger) {
    delete static_cast<Logger *>(logger);
}

__declspec(dllexport) void LogInfo(void *p, const char *log) {
    auto &logger = *static_cast<Logger *>(p);
    logger.Info(log);
}

__declspec(dllexport) void LogWarn(void *p, const char *log) {
    auto &logger = *static_cast<Logger *>(p);
    logger.Warn(log);
}

__declspec(dllexport) void LogError(void *p, const char *log) {
    auto &logger = *static_cast<Logger *>(p);
    logger.Error(log);
}

__declspec(dllexport) void LogErrorHalt(void *p, const char *log) {
    auto &logger = *static_cast<Logger *>(p);
    logger.Error(log);
}
}