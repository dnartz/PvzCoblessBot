#include "stdafx.h"
#include "EventLoop.h"

using PvzCoblessBot::EventLoop;
using PvzCoblessBot::BasicLogger;

int main() {
    auto& logger = BasicLogger::GetInstance();
    if (logger.IsInitFail()) {
        printf("日志系统初始化失败，请尝试重启挂机程序！\n");
        system("pause");
        return 0;
    }

    auto& loop = EventLoop::GetInstance();
    loop.Loop();

    system("pause");
    return 0;
}
