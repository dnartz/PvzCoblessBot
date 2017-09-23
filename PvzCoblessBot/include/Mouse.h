#pragma once
#include "stdafx.h"
#include <stdint.h>
#include <utility>
#include <unordered_map>
#include "GameMemory.h"

namespace PvzCoblessBot {

using Memory::PlantType;

static std::unordered_map<PlantType, std::pair<int, int>>
CardPosition = {
    {PlantType::Cherry, {0, 3}}
};

class Mouse {
private:
    Mouse() = delete;
    Mouse(Mouse &) = delete;
    Mouse &operator=(Mouse &) = delete;

    HWND windowHwnd;
    Mouse (HWND hWnd) : windowHwnd(hWnd) { }
public:
    static inline Mouse &GetInstance() {
        auto& ms = Memory::MemoryScanner::GetInstance();
        static Mouse mouse(ms.windowHwnd);
        return mouse;
    }

    inline void MoveTo(uint32_t x, uint32_t y) {
        SendMessage(windowHwnd, WM_MOUSEMOVE, 0, (y << 16) | x);
    }

    inline void LeftClick(uint32_t x, uint32_t y) {
        SendMessage(windowHwnd, WM_LBUTTONDOWN, 0, (y << 16) | x);
        SendMessage(windowHwnd, WM_LBUTTONUP, 0, (y << 16) | x);
    }

    inline void PressESC() {
        SendMessage(windowHwnd, WM_KEYDOWN, VK_ESCAPE, 0);
        SendMessage(windowHwnd, WM_KEYUP, VK_ESCAPE, 0);
    }

    inline void Reset() {
        SendMessage(windowHwnd, WM_RBUTTONDOWN, 0, (1 << 16) | 1);
        SendMessage(windowHwnd, WM_RBUTTONUP, 0, (1 << 16) | 1);
    }
};

}