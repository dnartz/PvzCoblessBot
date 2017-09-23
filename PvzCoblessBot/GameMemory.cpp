#include "stdafx.h"
#include <stdlib.h>
#include <utility>
#include <mutex>

#include "GameMemory.h"

namespace PvzCoblessBot {
namespace Memory {

MemoryScanner::MemoryScanner(): 
logger("�ڴ��ȡ"),
currentContextIndex(0)
{}

MemoryScanner& MemoryScanner::GetInstance() {
    static MemoryScanner ms;
    return ms;
}

void MemoryScanner::WaitUntilGameProcessOpened() {
    bool first = true;
    while (true) {
        windowHwnd = FindWindow(nullptr, L"Plants vs. Zombies");
        if (windowHwnd == nullptr) {
            windowHwnd = FindWindow(nullptr, L"ֲ���ս��ʬ���İ�");
        }

        if (first && windowHwnd == nullptr) {
            first = false;
            logger.Warn("δ��⵽��Ϸ���̣��ȴ���Ϸ���С���", false);
        }

        if (windowHwnd != nullptr) {
            break;
        }
    }

    DWORD pid;
    GetWindowThreadProcessId(windowHwnd, &pid);

    gameHwnd = OpenProcess(PROCESS_ALL_ACCESS, FALSE, pid);
    if (gameHwnd == nullptr) {
        logger.ErrorHalt("�򿪽���ʧ�ܣ��������һ�����", false);
    } else {
        logger.Info("�򿪽��̳ɹ���", false);
    }

    if (0 == ReadProcessMemory(
        gameHwnd,
        LPCVOID(0x6A9EC0),
        &gameBaseAddress,
        sizeof(gameBaseAddress),
        nullptr))
    {
        logger.ErrorHalt("�޷���ȡ��Ϸ�ڴ����ַ���������һ��������Ϸ��", false);
    }
}

// �ȴ�ֱ������ѡ������
void MemoryScanner::WaitUntilInGame() {
    bool first = true;
    gameContextBaseAddress = 0;

    while (gameContextBaseAddress == 0) {
        UpdateGameContextBaseAddress();
        if (gameContextBaseAddress == 0 && first) {
            logger.Warn("���ֶ������޾�ѡ�����桭��", false);
            first = false;
        } 
    }

    // ˯��һ���ӣ��Եȴ���Ϸ����������ɡ�
    Sleep(1000);
    // ��������Ϸ֮�󣬶�ȡ��Ϸ���������ݣ�������ģ��ʹ�á�
    UpdateGameContext();
}

bool MemoryScanner::UpdatePlants() {
    int32_t nPlants;
    bool success = ReadMemory(nPlants, gameContextBaseAddress, 0xb0);

    if (!success) {
        logger.Error("��ȡֲ������ʧ�ܣ�", false);
        return false;
    }

    uint64_t arrayPtr;
    success = ReadMemory(arrayPtr, gameContextBaseAddress, 0xac);
    if (!success) {
        logger.Error("��ȡֲ�������ַʧ�ܣ�", false);
        return false;
    }

    size_t size = 0x14c * nPlants;
    auto buffer = std::make_unique<char[]>(size);

    success = ReadProcessMemory(
        gameHwnd,
        LPCVOID(arrayPtr),
        buffer.get(),
        size,
        nullptr
    );

    if (!success) {
        logger.Error("��ȡֲ������ʧ�ܣ�", false);
        return false;
    }

    uint32_t j = 0;
    auto& plants = nextContext->plants;
    for (int32_t i = 0; i < nPlants; i++) {
        char *base = buffer.get() + 0x14c * i;

        // �����ǰֲ�ﴦ����ʧ���߱����⣬����������
        bool disappeared = *reinterpret_cast<bool *>(base + 0x141),
             flattened = *reinterpret_cast<bool *>(base + 0x142);

        if (disappeared || flattened) {
            continue;
        }

        plants[j].hp = *reinterpret_cast<int32_t *>(base + 0x40);
        plants[j].row = *reinterpret_cast<int32_t *>(base + 0x1c);
        plants[j].col = *reinterpret_cast<int32_t *>(base + 0x28);
        plants[j].x = *reinterpret_cast<int32_t *>(base + 0x8);
        plants[j].y = *reinterpret_cast<int32_t *>(base + 0xc);
        plants[j].type = *reinterpret_cast<PlantType *>(base + 0x24);

        j++;
    }
    nextContext->nPlants = j;

    return true;
}

bool MemoryScanner::UpdateZombies() {
    int32_t nZombies;
    bool success = ReadMemory(nZombies, gameContextBaseAddress, 0x94);

    if (!success) {
        logger.Error("��ȡ��ʬ����ʧ�ܣ�", false);
        return false;
    }

    uint32_t arrayPtr;
    success = ReadMemory(arrayPtr, gameContextBaseAddress, 0x90);

    if (!success) {
        logger.Error("��ȡ��ʬ�����ַʧ�ܣ�", false);
        return false;
    }

    size_t size = 0x15c * nZombies;
    auto buffer = std::make_unique<char[]>(size);

    success = ReadProcessMemory(
        gameHwnd,
        LPCVOID(arrayPtr),
        buffer.get(),
        size,
        nullptr
    );

    if (!success) {
        logger.Error("��ȡ��ʬ����ʧ�ܣ�", false);
        return false;
    }

    int32_t j = 0;
    auto &zombies = nextContext->zombies;
    for (int i = 0; i < nZombies; i++) {
        char *base = buffer.get() + 0x15c * i;

        // �����ǰ��ʬ���ڱ���������ʧ״̬����ô������
        auto hp = *reinterpret_cast<int32_t *>(base + 0xc8),
             row = *reinterpret_cast<int32_t *>(base + 0x1c),
             status = *reinterpret_cast<int32_t *>(base + 0xba);
            
        auto type = *reinterpret_cast<ZombieType *>(base + 0x24);

        bool disappeared = *reinterpret_cast<bool *>(base + 0xec),
             dying = *reinterpret_cast<bool *>(base + 0xba) == false;

        // ������������ʧ��HPΪ0���������в���ȷ�Ľ�ʬ��
        if (disappeared ||
            dying ||
            hp <= 0 ||
            row < 0 ||
            row > 5 ||

            // ��ʧ������Լ���ɱ״̬Ҳ����
            status == 1 ||
            status == 2 ||
            status == 3)
        {
            continue;
        }

        zombies[j].spawnedAt = *reinterpret_cast<int32_t *>(base + 0x6c) + 1;
        zombies[j].hp = hp;
        zombies[j].row = row;
        zombies[j].x = *reinterpret_cast<float *>(base + 0x2c);
        zombies[j].y = *reinterpret_cast<float *>(base + 0x30);
        zombies[j].type = type;
        zombies[j].eating = *reinterpret_cast<bool *>(base + 0x51);
        j++;
    }
    
    nextContext->nZombies = j;

    return true;
}

bool MemoryScanner::UpdateCraters() {
    int32_t nCraters;
    bool success = ReadMemory(nCraters, gameContextBaseAddress, 0x120);

    if (!success) {
        logger.Error("��ȡ���������Сʧ�ܣ�", false);
        return false;
    }

    int32_t arrayPtr;
    success = ReadMemory(arrayPtr, gameContextBaseAddress, 0x11c);
    if (!success) {
        logger.Error("��ȡ���������ַʧ�ܣ�", false);
        return false;
    }

    size_t size = 0xec * nCraters;
    auto buffer = std::make_unique<char[]>(size);
    success = ReadProcessMemory(
        gameHwnd,
        LPCVOID(arrayPtr),
        buffer.get(),
        size,
        nullptr
    );

    if (!success) {
        logger.Error("��ȡ��������ʧ�ܣ�", false);
        return false;
    }

    int32_t j = 0;
    auto& craters = nextContext->craters;
    for (int i = 0; i < nCraters; i++) {
        char *p = buffer.get() + 0xec * i;
        auto type = *reinterpret_cast<int32_t *>(p + 0x8);
        if (type != 2) {
            continue;
        }

        auto disappeared = *reinterpret_cast<bool *>(p + 0x20);
        if (disappeared) {
            continue;
        }

        auto timeout = *reinterpret_cast<int32_t *>(p + 0x18);
        if (timeout <= 0) {
            continue;
        }

        auto col = *reinterpret_cast<int32_t *>(p + 0x10),
             row = *reinterpret_cast<int32_t *>(p + 0x14);
        if (!(col >= 0 && col < 9 && row >= 0 && row < 6)) {
            continue;
        }

        craters[j].timeout = timeout;
        craters[j].col = col;
        craters[j].row = row;
        j++;
    }

    nextContext->nCraters = j;

    return true;
}

bool MemoryScanner::UpdateItems() {
    uint32_t arrayPtr;
    bool success = ReadMemory(arrayPtr, gameContextBaseAddress, 0xe4);
    if (!success) {
        logger.Error("��ȡ��Ʒ�����ַʧ�ܣ�", false);
        return false;
    }

    size_t size = 0xd8 * 256;
    auto buffer = std::make_unique<char[]>(size);
    success = ReadProcessMemory(
        gameHwnd,
        LPCVOID(arrayPtr),
        buffer.get(),
        size,
        nullptr
    );

    if (!success) {
        logger.Error("��ȡ��Ʒ����ʧ�ܣ�", false);
        return false;
    }

    int32_t j = 0;
    auto& items = nextContext->items;
    for (int i = 0; i < 256; ++i) {
        char *p = buffer.get() + 0xd8 * i;
        auto x = *reinterpret_cast<float *>(p + 0x24),
             y = *reinterpret_cast<float *>(p + 0x28);

        // ��Ʒû�б�������ʧ�������Σ����������ں���ķ�Χ�ڡ�
        if (!*reinterpret_cast<bool *>(p + 0x50) &&
            !*reinterpret_cast<bool *>(p + 0x38) &&
            *reinterpret_cast<bool *>(p + 0x18) &&
            x >= 1 && x <=800 &&
            y >= 100 && y <= 600)
        {
            items[j].x = x;
            items[j].y = y;
            j++;
        }
    }

    nextContext->nItems = j;

    return true;
}

bool inline MemoryScanner::UpdateIcePaths() {
    auto success = ReadMemory(
        nextContext->icePathX,
        gameContextBaseAddress,
        0x60c);

    if (!success) {
        logger.ErrorHalt("��ȡ����X����ʧ�ܣ�", false);
    }

    success = ReadMemory(
        nextContext->icePathTimeout,
        gameContextBaseAddress,
        0x624
    );
    if (!success) {
        logger.ErrorHalt("��ȡ������ʧ����ʱʧ�ܣ�", false);
    }

    return success;
}

bool MemoryScanner::UpdateCards() {
    char buffer[0x50 * 10 + 0x20];
    bool success = ReadMemory(buffer, gameContextBaseAddress, 0x144, 0);
    if (!success) {
        logger.Error("��ȡ��Ƭ����ʧ�ܣ�", false);
        return false;
    }

    auto &cards = nextContext->cards;
    for (int i = 0; i < 10; i++) {
        char *p = buffer + 0x50 * i;
        cards[i].coldDown = *reinterpret_cast<int32_t *>(p + 0x4c);
        cards[i].totalColdDown = *reinterpret_cast<int32_t *>(p + 0x50);
        cards[i].type = *reinterpret_cast<PlantType *>(p + 0x5c);
        if (cards[i].type == PlantType::Imitater) {
            cards[i].imitaterType = *reinterpret_cast<PlantType *>(p + 0x60);
        }
        cards[i].available = *reinterpret_cast<bool *>(p + 0x70);
    }

    return true;
}

bool MemoryScanner::UpdateGridStatus() {
    static const int ICE_PATH_THRESHOLD[9] = {
        108, 188, 268, 348, 428, 508, 588, 668, 751
    };

    auto& gridGrowable = nextContext->gridGrowable;
    memset(gridGrowable, true, sizeof(gridGrowable));

    const auto& icePathX = nextContext->icePathX;
    for (int row = 0; row < 6; row++) {
        for (int col = 0; col < 9; col++) {
            if (icePathX[row] < ICE_PATH_THRESHOLD[col]) {
                gridGrowable[row][col] = false;
            }
        }
    }

    const auto& craters = nextContext->craters;
    for (int i = 0; i < nextContext->nCraters; i++) {
        gridGrowable[craters[i].row][craters[i].col] = false;
    }

    const auto& plants = nextContext->plants;
    for (int i = 0; i < nextContext->nPlants; i++) {
        if (plants[i].type != PlantType::Pumpkin &&
            plants[i].type != PlantType::LilyPad &&
            plants[i].type != PlantType::FlowerPot)
        {
            gridGrowable[plants[i].row][plants[i].col] = false;
        }
    }

    return true;
}

bool MemoryScanner::UpdateGameContext() {
    nextContext = std::make_unique<struct Context>();

    return UpdateCurrentFlag() &&
           UpdateCurrentWave() &&
           UpdateGameTime() &&
           UpdatePauseStatus() &&
           UpdatePlants() &&
           UpdateZombies() &&
           UpdateCraters() &&
           UpdateItems() &&
           UpdateIcePaths() &&
           UpdateCards() &&
           UpdateGridStatus();
}

void MemoryScanner::ScanLoop() {
    while (UpdateGameContext()) {
        std::lock_guard<std::mutex> guard(contextReadyMutex);
        contextReady = std::move(nextContext);
    }
}

bool *MemoryScanner::GetZombieLineup() {
    static bool zombieLineup[33];
    auto success = ReadMemory(
        zombieLineup,
        gameContextBaseAddress,
        0x54d4);

    if (!success) {
        logger.ErrorHalt("��ȡ��ʬ���ʧ�ܣ�", false);
    }

    return zombieLineup;
}

DWORD *MemoryScanner::GetZombieSpawnList() {
    static DWORD zombies[1000];

    if (0 == ReadProcessMemory(
        gameHwnd,
        LPCVOID(gameContextBaseAddress + 0x6b4),
        zombies,
        sizeof(DWORD) * 1000,
        nullptr
    ))
    {
        logger.ErrorHalt("�޷���ȡ��ʬ�����б�", false);
    }

    return zombies;
}

}

} // namespace PvzCoblessBot::Memory