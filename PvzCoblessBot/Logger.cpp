#include "stdafx.h"
#include <string>

#include "Logger.h"
#include "GameMemory.h"
#include "EventLoop.h"
#include "windows.h"

namespace PvzCoblessBot {

    using Memory::MemoryScanner;

BasicLogger::BasicLogger() {
    consoleHandle = GetStdHandle(STD_OUTPUT_HANDLE);
}

void BasicLogger::GetTimeStamp(char *buf, bool usingGameTime) {
    if (usingGameTime) {
        static auto& ms = MemoryScanner::GetInstance();
        static auto& loop = EventLoop::GetInstance();

        auto t = ms.GetGameTime() - loop.levelBeginAt,
             minute = t / 6000,
             second = (t % 6000) / 100,
             centisecond = t % 100;

        sprintf_s(buf, 25, "[%d-%d %02d:%02d.%02d]",
                ms.GetCurrentFlag(),
                ms.GetCurrentWave(),
                minute,
                second,
                centisecond);
    } else {
        time_t t;
        time(&t);
        struct tm timeInfo;
        localtime_s(&timeInfo, &t);

        char tbuf[15];
        strftime(tbuf, sizeof(tbuf), "%m/%d %H:%M:%S", &timeInfo);
        sprintf_s(buf, 25, "[%s]", tbuf);
    }
}

void BasicLogger::Info(
    WORD color,
    bool usingGameTime,
    const std::string &m,
    const std::string &log)
{
    char strTime[25];
    GetTimeStamp(strTime, usingGameTime);

    SetConsoleTextAttribute(consoleHandle, color);
    printf("[»’÷æ]%s[%s]%s\n", strTime, m.c_str(), log.c_str());
}

void BasicLogger::Warn(
    WORD color,
    bool usingGameTime,
    const std::string &m,
    const std::string &log)
{
    char strTime[25];
    GetTimeStamp(strTime, usingGameTime);

    SetConsoleTextAttribute(consoleHandle, color);
    printf("[æØ∏Ê]%s[%s]%s\n", strTime, m.c_str(), log.c_str());
}

void BasicLogger::Error(
    WORD color,
    bool usingGameTime,
    const std::string &m,
    const std::string &log)
{
    char strTime[25];
    GetTimeStamp(strTime, usingGameTime);

    SetConsoleTextAttribute(consoleHandle, color);
    printf("[¥ÌŒÛ]%s[%s]%s\n", strTime, m.c_str(), log.c_str());
}

BasicLogger& BasicLogger::GetInstance() {
    static BasicLogger logger{};
    return logger;
}

Logger::Logger(std::string &&moduleName):
moduleName(moduleName),
colorInfo(11),
colorWarn(14),
colorError(12)
{ }

Logger::Logger(
    std::string &&moduleName,
    WORD info,
    WORD warn,
    WORD err):
moduleName(moduleName),
colorInfo(info),
colorWarn(warn),
colorError(err)
{ }

void Logger::Logger::Info(const std::string &log, bool usingGameTime) {
    static auto& bl = BasicLogger::GetInstance();
    bl.Info(colorInfo, usingGameTime, moduleName, log);
}

void Logger::Warn(const std::string &log, bool usingGameTime) {
    static auto& bl = BasicLogger::GetInstance();
    bl.Warn(colorWarn, usingGameTime, moduleName, log);
}

void Logger::Error(const std::string &log, bool usingGameTime) {
    static auto& bl = BasicLogger::GetInstance();
    bl.Error(colorError, usingGameTime, moduleName, log);
}

[[noreturn]]
void Logger::ErrorHalt(const std::string &log, bool usingGameTime) {
    static auto& bl = BasicLogger::GetInstance();
    bl.Error(colorError, usingGameTime, moduleName, log);
    system("pause");
    exit(1);
}

} // namespace PvzCoblessBot
