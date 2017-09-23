#pragma once

#include <ctime>
#include <string>
#include <windows.h>

namespace PvzCoblessBot {

class BasicLogger
{
private:
    BasicLogger();

    BasicLogger(BasicLogger&) = delete;
    BasicLogger& operator=(BasicLogger&) = delete;

    HANDLE consoleHandle;

    void GetTimeStamp(char *buf, bool usingGameTime);

public:
    bool inline IsInitFail() {
        return consoleHandle == nullptr;
    }

    void Info(WORD color,
              bool usingGameTime,
              const std::string &m,
              const std::string &log);

    void Warn(WORD color,
              bool usingGameTime,
              const std::string &m,
              const std::string &log);

    void Error(WORD color, 
               bool usingGameTime,
               const std::string &m,
               const std::string &log);

    static BasicLogger& GetInstance();
};

class Logger {
private:
    std::string moduleName;
    WORD colorInfo;
    WORD colorWarn;
    WORD colorError;

public:
    Logger() = delete;

    Logger(std::string&& moduleName);

    Logger(std::string&& moduleName, WORD info, WORD warn = 14, WORD err = 12);

    void Info(const std::string &log, bool usingGameTime = true);

    void Warn(const std::string &log, bool usingGameTime = true);

    void Error(const std::string &log, bool usingGameTime = true);

    [[noreturn]]
    void ErrorHalt(const std::string &log, bool usingGameTime = true);
};

} // namespace PvzCoblessBot