local ffi = require('ffi')

ffi.cdef[[
struct Item {
    float x;
    float y;
};

struct Crater {
    int32_t row;
    int32_t col;
    int32_t timeout;
};

struct Zombie {
    int32_t spawnedAt;
    int32_t hp;
    int32_t row;
    float x;
    float y;
    int32_t type;
    bool eating;
};

struct Plant {
    int32_t hp;
    int32_t row;
    int32_t col;
    int32_t x;
    int32_t y;
    int32_t type;
};

struct Card {
    int32_t index;
    int32_t coldDown;
    int32_t totalColdDown;
    int32_t type;
    int32_t imitaterType;
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

void SelectCard(int, int *);
bool GrowPlant(int type, int row, int col, bool brutal, bool remove);

struct Context *GetGameContext();

bool IsCardAvailable(int p);
int GetCardColdDown(int plant);

bool *GetZombieLineup();
uint32_t *GetZombieSpawnList();

void *NewLogger(
    const char *name,
    unsigned short info,
    unsigned short warn,
    unsigned short error
);
void FreeLogger(void *logger);
void LogInfo(void *p, const char *log);
void LogWarn(void *p, const char *log);
void LogError(void *p, const char *log);
void LogErrorHalt(void *p, const char *log);
]]

Logger = {}

Logger.__index = Logger

function Logger:Info (log)
    assert(type(log) == 'string')
    ffi.C.LogInfo(self._logger, log)
end

function Logger:Warn (log)
    assert(type(log) == 'string')
    ffi.C.LogWarn(self._logger, log)
end

function Logger:Error (log)
    assert(type(log) == 'string')
    ffi.C.LogError(self._logger, log)
end

function Logger:ErrorHalt (log)
    assert(type(log) == 'string')
    ffi.C.LogErrorHalt(self._logger, log)
end

function Logger:New(name, ...)
    local arguments = {...}
    local infoC, warnC, errorC = 11, 14, 12

    if type(arguments[1]) == 'number' then
        infoC = arguments[1]
    end

    if type(arguments[2]) == 'number' then
        warnC = arguments[2]
    end

    if type(arguments[3]) == 'number' then
        errorC = arguments[3]
    end

    local logger = ffi.C.NewLogger(name, infoC, warnC, errorC)
    ffi.gc(logger, ffi.C.FreeLogger)

    local o = {
        _logger = logger,
        Name = name
    }

    setmetatable(o, Logger)

    return o
end

Context = nil

Zombies = {
    Normal = 0, Flag = 1, ConeHead = 2, PoleVaulting = 3, BucketHead = 4,
    NewsPaper = 5, ScreenDoor = 6, Football = 7, Dancing = 8, BackupDancer = 9,
    DucyTube = 10, Snorkel = 11, Zomboni = 12, BobsledTeam = 13, Dophin = 14,
    Jack = 15, Balloon = 16, Digger = 17, Pogo = 18, Yeti = 19,
    Bungee = 20, Ladder = 21, Catapult = 22, Gargantuar = 23, Imp = 24,
    DrZomboss = 25, Peashooter = 26, WallNut = 27, Jalapeno = 28, GatlingPea = 29,
    Squash = 30, TallNut = 31, GigaGargantuar = 32,

    Find = function(cb)
        for i = 0, Context.nZombies - 1 do
            if cb(Context.zombies[i]) then
                return Context.zombies[i]
            end
        end
        return nil
    end,

    ForEach = function(cb)
        for i = 0, Context.nZombies - 1 do
            cb(Context.zombies[i])
        end
    end
}

ZombieLineup = {
    Update = (function ()
        local enum2Zombies = {}
        local zombieLineup = ffi.C.GetZombieLineup()
        for k, v in pairs(Zombies) do
            if type(v) == 'number' then
                enum2Zombies[v] = k
            end
        end

        return function()
            for k, v in pairs(Zombies) do
                if type(v) == 'number' then
                    ZombieLineup[k] = false
                end
            end
            for i = 0, 32 do
                if zombieLineup[i] then
                    ZombieLineup[enum2Zombies[i]] = true
                end
            end
        end
    end)()
}

(function()

local zsl
ZombieSpawnList = {
    Wave = function(w)
        assert(w > 0 and w < 21)

        local o = {
            Find = function(ztype)
                assert(ztype >= 0 and ztype <= 32)
                for i = 50 * (w - 1), 50 * (w - 1) + 49 do
                    if zsl[i] == ztype then
                        return true
                    end
                end

                return false
            end,

            ForEach = function(cb)
                for i = 50 * (w - 1), 50 * (w - 1) + 49 do
                    cb(zsl[i])
                end
            end
        }

        setmetatable(o, {
            __index = function(table, key)
                if type(key) == 'number' and key < 50 and key >= 0 then
                    return zsl[(50 * (w - 1)) + key]
                else
                    return nil
                end
            end
        })

        return o
    end,

    Update = function()
        zsl = ffi.C.GetZombieSpawnList()
    end
}

setmetatable(ZombieSpawnList, {
    __index = function(table, key)
        if type(key) == 'number' and key < 1000 and key >= 0 then
            return zsl[key]
        else
            return nil
        end
    end
})

end)()

setmetatable(Zombies, {
    __index = function (table, key)
        if type(key) == 'number' and key >= 0 and key < Context.nZombies then
            return Context.zombies[key]
        else
            return nil
        end
    end
})

Plants = {
    PeaShooter = 0, Sunflower = 1, Cherry = 2, WallNut = 3, Potato = 4,
    SnowPea = 5, Chomper = 6, Repeater = 7, PuffShroom = 8, SunShroom = 9,
    FumeShroom = 10, GraveBuster = 11, HypnoShroom = 12, ScaredyShroom = 13,
    IceShroom = 14, DoomShroom = 15, LilyPad = 16, Squash = 17,
    Threepeater = 18, TangleKelp = 19, Jalapeno = 20, SpikeWeed = 21,
    Torchwood = 22, TallNut = 23, SeaShroom = 24, Plantern = 25,
    Cactus = 26, Blover = 27, SplitPea = 28, Starfruit = 29, Pumpkin = 30,
    MagnetShroom = 31, CabbagePult = 32, FlowerPot = 33, KernelPult = 34,
    CoffeeBean = 35, Garlic = 36, UmbrellaLeaf = 37, Marigold = 38,
    MelonPult = 39, GatlingPea = 40, TwinSunflower = 41, GloomShroom = 42,
    Cattail = 43, WinterMelon = 44, GoldMagnet = 45, Spikerock = 46,
    CobCanon = 47, Imitater = 48,

    Find = function (fn)
        for i = 0, Context.nPlants - 1 do
            if fn(Context.plants[i]) then
                return true
            end
        end

        return false
    end,

    ForEach = function(fn)
        for i = 0, Context.nPlants - 1 do
            fn(Context.plants[i])
        end
    end
}

setmetatable(Plants, {
    __index = function (table, key)
        if type(key) == 'number' and key >= 0 and key < Context.nPlants then
            return Context.plants[key]
        else
            return nil
        end
    end
})

Craters = {
    ForEach = function(fn)
        for i = 0, Context.nCraters - 1 do
            fn(Context.craters[i])
        end
    end
}

setmetatable(Craters, {
    __index = function (table, key)
        if type(key) == 'number' and key >= 0 and key < Context.nCraters then
            return Context.craters[key]
        else
            return nil
        end
    end
})

SelectCard = function (...)
    local plants = {...}

    local len, Imitater =
          table.getn(plants),
          Plants.Imitater

    local cards = ffi.new('int[?]', len)

    for i = 0, len - 1 do
        cards[i] = plants[i + 1]
    end

    ffi.C.SelectCard(len, cards)

    WaitNextTick()
    ZombieLineup.Update()
end

ImitatePlantType = function (type)
    return type + Plants.Imitater
end

GrowPlant = function (...)
    local arguments = {...}
    local plant, row, col, brutal, remove

    if #arguments == 1 then
        if type(arguments[1]) == 'table' then
            local tab = arguments[1]
            plant, row, col, brutal, remove =
                tab.plant,
                tab.row,
                tab.col,
                tab.brutal,
                tab.remove

            if type(plant) ~= 'number' then
                error('GrowPlant 函数参数错误，没有传入植物类型。')
            end

            if type(row) ~= 'number' and type(col) ~= 'number' then
                brutal = true
                remove = false
            end

            if brutal then
                row = 0
                col = 0
                remove = false
            end

            return ffi.C.GrowPlant(plant, row, col, brutal, remove)
        elseif type(arguments[1]) == 'number' then
            return ffi.C.GrowPlant(arguments[1], 0, 0, true, false)
        else
            error('GrowPlant 函数参数错误。')
        end
    elseif #arguments >= 3 and #arguments <= 5 then
        plant, row, col = arguments[1], arguments[2], arguments[3]
        brutal = arguments[4] or false

        if #arguments >= 5 and not brutal then
            remove = arguments[5] or false
        else
            remove = false
        end

        return ffi.C.GrowPlant(plant, row, col, brutal, remove)
    else
        error('GrowPlant 函数参数错误。')
    end
end

GrowInstantPlant = function (plant, ...)
    local pos = {...}
    assert(plant ~= 0)
    WaitUntilCardAvailable(plant)
    if #pos == 2 then
        return GrowPlant(plant, pos[1], pos[2], false, true)
    else
        return GrowPlant(plant)
    end
end

IsCardAvailable = ffi.C.IsCardAvailable
GetCardColdDown = ffi.C.GetCardColdDown

WaitNextTick = function () Wait(1) end
TickCoroutine = nil
ClearTickHandler = nil
OnTick = (function ()
    local tickHandlers = {}

    TickCoroutine = coroutine.create(function ()
        while true do
            Context = ffi.C.GetGameContext()

            for _, f in pairs(tickHandlers) do
                f()
            end
            coroutine.yield()
        end
    end)
    SetTickCoroutine(TickCoroutine)

    ClearTickHandler = function (...)
        local arguments = {...}
        if #arguments == 0 then
            tickHandlers = {}
        end
    end

    return function (fn)
        table.insert(tickHandlers, coroutine.wrap(function ()
            while true do
                fn()
                coroutine.yield()
            end
        end))
    end
end)()

function InstanceOf (subject, super)
	super = tostring(super)
    print(super)
	local mt = getmetatable(subject)

	while true do
		if mt == nil then return false end
		if tostring(mt) == super then return true end

		mt = getmetatable(mt)
	end	
end
