#pragma once
#include "stdafx.h"
#include <array>
#include <memory>
#include <mutex>

#include "Logger.h"

namespace PvzCoblessBot {

class Mouse;

namespace Memory{

enum class PlantType : int32_t {
    PeaShooter = 0,
    Sunflower = 1,
    Cherry = 2,
    WallNut = 3,
    Potato = 4,
    SnowPea = 5,
    Chomper = 6,
    Repeater = 7,
    PuffShroom = 8,
    SunShroom = 9,
    FumeShroom = 10,
    GraveBuster = 11,
    HypnoShroom = 12,
    ScaredyShroom = 13,
    IceShroom = 14,
    DoomShroom = 15,
    LilyPad = 16,
    Squash = 17,
    Threepeater = 18,
    TangleKelp = 19,
    Jalapeno = 20,
    SpikeWeed = 21,
    Torchwood = 22,
    TallNut = 23,
    SeaShroom = 24,
    Plantern = 25,
    Cactus = 26,
    Blover = 27,
    SplitPea = 28,
    Starfruit = 29,
    Pumpkin = 30,
    MagnetShroom = 31,
    CabbagePult = 32,
    FlowerPot = 33,
    KernelPult = 34,
    CoffeeBean = 35,
    Garlic = 36,
    UmbrellaLeaf = 37,
    Marigold = 38,
    MelonPult = 39,
    GatlingPea = 40,
    TwinSunflower = 41,
    GloomShroom = 42,
    Cattail = 43,
    WinterMelon = 44,
    GoldMagnet = 45,
    Spikerock = 46,
    CobCanon = 47,
    Imitater = 48
};

static const char *PlantName[] = {
    "�㶹����", "���տ�", "ӣ��ը��", "���", "��������", "��������",
    "���컨", "˫������", "С�繽", "���⹽", "���繽", "Ĺ��������",
    "�Ȼ�", "��С��", "������", "����", "��Ҷ", "�ѹ�", "��������",
    "����ˮ��", "����", "�ش�", "�����׮", "�߼��", "��Ģ��", "������",
    "������", "��Ҷ��", "��������", "����", "�ϹϿ�", "������", "���Ĳ�",
    "����", "����Ͷ��", "���ȶ�", "����", "ݫ��", "��յ��", "����Ͷ��",
    "����������", "˫�����տ�", "����Ģ��", "����", "����Ͷ��", "�����",
    "�ش���", "���׼�ũ��", "ģ����",

    "�����㶹����", "�������տ�", "����ӣ��ը��", "���Ƽ��", "������������", "���ƺ�������",
    "���ƴ��컨", "����˫������", "����С�繽", "�������⹽", "���ƴ��繽", "����Ĺ��������",
    "�����Ȼ�", "���Ƶ�С��", "���ƺ�����", "���ƻ���", "���ƺ�Ҷ", "�����ѹ�", "������������",
    "���Ʋ���ˮ��", "��������", "���Ƶش�", "���ƻ����׮", "���Ƹ߼��", "���ƺ�Ģ��", "���Ƶ�����",
    "����������", "������Ҷ��", "���Ʒ�������", "��������", "�����ϹϿ�", "���ƴ�����", "���ƾ��Ĳ�",
    "���ƻ���", "��������Ͷ��", "���ƿ��ȶ�", "���ƴ���", "����ݫ��", "���ƽ�յ��", "��������Ͷ��",
};

#define PLANT_TYPE_TO_NAME(type) ((static_cast<int>(type) <= 48)?\
(::PvzCoblessBot::Memory::PlantName[static_cast<int>(type)]):\
(::PvzCoblessBot::Memory::PlantName[static_cast<int>(type) - 49]))

struct Plant {
    int32_t hp;
    int32_t row;
    int32_t col;
    int32_t x;
    int32_t y;
    PlantType type;
};

enum class ZombieType : int32_t {
    Normal = 0,
    Flag = 1,
    ConeHead = 2,
    PoleVaulting = 3,
    BucketHead = 4,
    NewsPaper = 5,
    ScreenDoor = 6,
    Football = 7,
    Dancing = 8,
    BackupDancer = 9,
    DucyTube = 10,
    Snorkel = 11,
    Zomboni = 12,
    BobsledTeam = 13,
    Dophin = 14,
    Jack = 15,
    Balloon = 16,
    Digger = 17,
    Pogo = 18,
    Yeti = 19,
    Bungee = 20,
    Ladder = 21,
    Catapult = 22,
    Gargantuar = 23,
    Imp = 24,
    DrZomboss = 25,
    Peashooter = 26,
    WallNut = 27,
    Jalapeno = 28,
    GatlingPea = 29,
    Squash = 30,
    TallNut = 31,
    GigaGargantuar = 32
};

struct Zombie {
    int32_t spawnedAt;
    int32_t hp;
    int32_t row;
    float x;
    float y;
    ZombieType type;
    bool eating;
};

struct Crater {
    int32_t row;
    int32_t col;
    int32_t timeout;
};

struct Item {
    float x;
    float y;
};

struct Card {
    int32_t index;
    int32_t coldDown;
    int32_t totalColdDown;
    PlantType type;
    PlantType imitaterType;
    bool available;
};

struct Context {
    uint32_t spawnSeed;
    int32_t gameTime;
    int32_t spawnCountdown;
    int32_t currentFlag;
    int32_t currentWave;
    int32_t currentScene;

    int32_t nZombies;
    int32_t nPlants;
    int32_t nCraters;
    int32_t nItems;

    int32_t icePathX[6];
    int32_t icePathTimeout[6];

    struct Plant plants[162];
    struct Zombie zombies[512];
    struct Card cards[10];
    struct Crater craters[54];
    struct Item items[512];

    bool gridGrowable[6][9];

    bool gamePause;
};

class MemoryScanner {
private:
    friend class ::PvzCoblessBot::Mouse;

    HANDLE gameHwnd;
    Logger logger;

    uint32_t gameBaseAddress;
    uint32_t gameContextBaseAddress;

    HWND windowHwnd;
    size_t currentContextIndex;
    std::unique_ptr<struct Context> nextContext;

    std::mutex contextReadyMutex;
    std::unique_ptr<struct Context> contextReady;

    static const uint32_t STATIC_BASE_ADDR = 0x6a9ec0;

    explicit MemoryScanner();

    MemoryScanner(MemoryScanner &) = delete;
    MemoryScanner& operator=(MemoryScanner &) = delete;

public:
    template<typename RT>
    inline bool ReadMemory(RT &result, uint32_t base, uint32_t offset) {
        return 0 != ReadProcessMemory(
            gameHwnd, LPCVOID(base + offset), &result, sizeof(result), nullptr
        );
    }

    template<typename RT, typename ...TS>
    inline bool ReadMemory(
        RT &result,
        uint32_t base,
        uint32_t offset,
        TS... offsets)
    {
        uint32_t newBase;

        if (0 == ReadProcessMemory(
            gameHwnd, LPCVOID(base + offset), &newBase, sizeof(newBase), nullptr
        )) {
            return false;
        } else {
            return ReadMemory(result, newBase, offsets...);
        }
    }

    static MemoryScanner& GetInstance();

    void WaitUntilGameProcessOpened();
    
    void WaitUntilInGame();

    inline bool UpdateGameTime() {
        auto success = ReadMemory(
            nextContext->gameTime,
            gameContextBaseAddress,
            0x5568);

        if (!success) {
            logger.ErrorHalt("��ȡ��Ϸʱ���ʧ�ܡ�", false);
        }

        success = ReadMemory(
            nextContext->spawnCountdown,
            gameContextBaseAddress,
            0x559c
        );
        if (!success) {
            logger.ErrorHalt("��ȡ��ʬˢ�µ���ʱʧ�ܡ�", false);
        }

        return success;
    }

    inline bool UpdateGameContextBaseAddress() {
        return ReadMemory(gameContextBaseAddress, gameBaseAddress, 0x768);
    }

    inline bool UpdateCurrentFlag() {
        bool success = ReadMemory(
            nextContext->currentFlag,
            gameContextBaseAddress,
            0x160,
            0x6c);

        if (!success) {
            logger.Error("��ȡ��ǰF��ʧ�ܣ�", false);
        }

        return success;
    }

    inline bool UpdateCurrentWave() {
        bool success = ReadMemory(
            nextContext->currentWave,
            gameContextBaseAddress,
            0x557c);

        if (!success) {
            logger.Error("��ȡ��ǰ����ʧ�ܡ�", false);
        }

        return success;
    }

    inline bool UpdatePauseStatus() {
        bool success = ReadMemory(
            nextContext->gamePause,
            gameContextBaseAddress,
            0x164);

        if (!success) {
            logger.Error("��ȡ��Ϸ��ͣ״̬ʧ�ܡ�", false);
        }

        return success;
    }

    inline int32_t GetPauseStatus() {
        bool pause,
             success = ReadMemory(pause, gameContextBaseAddress, 0x164);
        if (success) {
            return pause;
        } else {
            return -1;
        }
    }

    inline int32_t GetCardsSelected() {
        int32_t result;
        if (ReadMemory(result, gameBaseAddress, 0x774, 0xd24)) {
            return result;
        } else {
            return -1;
        }
    }

    inline int32_t GetGameTime() {
        int32_t result;
        if (ReadMemory(result, gameContextBaseAddress, 0x5568)) {
            return result;
        } else {
            return -1;
        }
    }

    inline int32_t GetCurrentWave() {
        int32_t result;
        if (ReadMemory(result, gameContextBaseAddress, 0x557c)) {
            return result;
        } else {
            return -1;
        }
    }

    inline int32_t GetCurrentFlag() {
        int32_t result;
        int32_t wave = GetCurrentWave();
        if (ReadMemory(result, gameContextBaseAddress, 0x160, 0x6c)) {
            return wave > 10 ? result * 2 + 1 : result * 2;
        } else {
            return -1;
        }
    }

    bool UpdatePlants();
    bool UpdateZombies();
    bool UpdateCraters();
    bool UpdateItems();
    bool UpdateIcePaths();
    bool UpdateCards();
    bool UpdateGameContext();
    bool UpdateGridStatus();

    inline struct Context *GetContext() {
        struct Context* ret = nullptr;

        do {
            std::lock_guard<std::mutex> guard(contextReadyMutex);
            ret = contextReady.release();
        } while (ret == nullptr);

        return ret;
    }

    bool *GetZombieLineup();
    DWORD *GetZombieSpawnList();

    void ScanLoop();
};

}
} // namespace PvzCoblessBot::Memory