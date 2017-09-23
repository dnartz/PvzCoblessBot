local PumpkinFixer = {}

PumpkinFixer.__index = PumpkinFixer

function PumpkinFixer:New (fixList)
    local pf = {
        lookUp = {},
        fixList = fixList
    }

    for row = 1, 6 do
        pf.lookUp[row] = {}
        for col = 1, 9 do
            pf.lookUp[row][col] = false
        end
    end

    for _, pos in pairs(fixList) do
        pf.lookUp[pos[1] + 1][pos[2] + 1] = true
    end

    setmetatable(pf, self)
    return pf
end

function PumpkinFixer:Run ()
    OnTick(function ()
        if not IsCardAvailable(Plants.Pumpkin) then
            return
        end

        local minHp = 4000
        local row, col
        local pumpkinPos = {{}, {}, {}, {}, {}, {}}

        Plants.ForEach(function (p)
            if p.type == Plants.Pumpkin then
                pumpkinPos[p.row + 1][p.col + 1] = true

                if self.lookUp[p.row + 1][p.col + 1] and
                   p.hp < minHp
                then
                    minHp = p.hp
                    row = p.row
                    col = p.col
                end
            end
        end)

        local used = false
        for _, pos in pairs(self.fixList) do
            if not pumpkinPos[pos[1] + 1][pos[2] + 1] then
                GrowPlant(Plants.Pumpkin, pos[1], pos[2])
                used = true
            end
        end

        if minHp < 2333 and not used then
            GrowPlant(Plants.Pumpkin, row, col)
        end
    end)
end

local MinPoolCrater = function ()
    local craterColdDown = {
        [3] = {
            [7] = 0,
            [8] = 0,
            [9] = 0
        },
        [4] = {
            [7] = 0,
            [8] = 0,
            [9] = 0
        }
    }

    Craters.ForEach(function (c)
        if c.row == 2 or c.row == 3 then
            craterColdDown[c.row + 1][c.col + 1] = c.timeout
        end
    end)

    local min = 301
    local mRow, mCol
    for col = 9, 7, -1 do
        for row = 3, 4 do
            if craterColdDown[row][col] == 0 then
                return 0, row - 1, col - 1
            elseif craterColdDown[row][col] < min then
                min = craterColdDown[row][col]
                mRow = row
                mCol = col
            end
        end
    end

    return min, row, col
end

local MinPoolCraterColdDown = function ()
    local min, _, _ = MinPoolCrater()
    return min
end

local IsFastZombieLineup = function (wave)
    return not Zombies.Find(function (z)
        return z.spawnedAt == wave and (
            z.type == Zombies.GigaGargantuar or
            z.type == Zombies.Gargantuar
        )
    end)
end

local GrowCherry = function()
    GrowInstantPlant(Plants.Cherry, 0, 6)
    WaitNextTick()
    -- ���7�в��ܷ�ӣ�ң��ͷ���6�С�
    if IsCardAvailable(Plants.Cherry) then
        GrowInstantPlant(Plants.Cherry, 0, 5)
    end
end

local GrowJalapeno = function()
     GrowInstantPlant(Plants.Jalapeno, 5, 5)
     WaitNextTick()
     -- ���6�в��ܷ��������ͷ���5�С�
     if IsCardAvailable(Plants.Jalapeno) then
         GrowInstantPlant(Plants.Jalapeno, 5, 4)
         -- ���ǲ��У�����4000�С�
         WaitNextTick()
         if IsCardAvailable(Plants.Jalapeno) then
             GrowInstantPlant(Plants.Jalapeno, 5, 3)
         end
     end
end

local CherryAndJalapeno = {
    Name = "ͬ��ӣ��������",
    Logger = Logger:New("ͬ��ӣ��������", 10),
    CastTime = 100
}

function CherryAndJalapeno:New()
    local o = {cancel = false}
    setmetatable(o, {__index = CherryAndJalapeno})
    return o
end

function CherryAndJalapeno:ColdDown()
    local cd = math.max(
        GetCardColdDown(Plants.Cherry),
        GetCardColdDown(Plants.Jalapeno)
    )

    if cd > 0 then
        self.Logger:Info("ӣ����������ȴ��" .. cd)
    else
        self.Logger:Info("ӣ���������Ѿ�����")
    end
    
    return cd
end

function CherryAndJalapeno:Run(cs)
    if type(cs) == 'number' then
        Wait(cs)
    end

    if self.cancel then
        self.Logger:Info("ͬ��ӣ����������ȡ����")
        return
    end
    GrowCherry()
    GrowJalapeno()
    self.Logger:Info("ͬ��ӣ���������ͷ���ϡ�")
end

local CherryAndDelayedJalapeno = {
    Name = "ӣ�����ӳ�����",
    Logger = Logger:New("ӣ�����ӳ�����", 21),
    CastTime = 100
}

function CherryAndDelayedJalapeno:New()
    local o = {cancel = false}
    setmetatable(o, {__index = CherryAndDelayedJalapeno})
    return o
end

function CherryAndDelayedJalapeno:ColdDown()
    local cd = math.max(
        GetCardColdDown(Plants.Cherry),
        math.max(0, GetCardColdDown(Plants.Jalapeno) - 800)
    )

    if cd > 0 then
        self.Logger:Info("ӣ�����ӳ���������ʣ�ࣺ" .. cd)
    else
        self.Logger:Info("ӣ�����ӳ������Ѿ���")
    end

    return cd
end

function CherryAndDelayedJalapeno:Run(cs)
    if type(cs) == 'number' then
        Wait(cs)
    end

    if self.cancel then
        self.Logger:Info("ӣ�����ӳ�������ȡ����")
        return
    end
    GrowCherry()
    self.Logger:Info("ӣ���ͷ���ϡ�")

    Wait(800)

    if self.cancel then
        self.Logger:Info("�ӳ�������ȡ����")
        return
    end
    GrowJalapeno()
    self.Logger:Info("�ӳ������ͷ���ϡ�")
end

local PoolDoomShroom = {
    Name = "ˮ·����",
    Logger = Logger:New("ˮ·����", 8),
    CastTime = 100
}

function PoolDoomShroom:New()
    local o = {cancel = false}
    setmetatable(o, {__index = PoolDoomShroom})
    return o
end

function PoolDoomShroom:ColdDown ()
    local cd = math.max(
        MinPoolCraterColdDown(),
        GetCardColdDown(Plants.DoomShroom),
        GetCardColdDown(Plants.LilyPad)
    )

    if cd > 0 then
        self.Logger:Info("ˮ·������ȴʣ�ࣺ" .. cd)
    else
        self.Logger:Info("ˮ·�����Ѿ�������")
    end

    return cd
end

function PoolDoomShroom:Run (cs)
    if type(cs) == 'number' then
        Wait(cs)
    end

    if self.cancel then
        self.Logger:Info("�����ͷ���ȡ����")
        return
    end

    for col = 6, 8 do
        for row = 2, 3 do
            if Context.gridGrowable[row][col] then
                WaitUntilCardAvailable(Plants.DoomShroom)
                GrowPlant(Plants.LilyPad, row, col)
                GrowPlant(Plants.DoomShroom, row, col)
                self.Logger:Info("ˮ·�����ͷ���ϡ�")
                return
            end
        end
    end
end

local PoolImitaterDoomShroom = {
    Name = "ˮ·���ƺ���",
    Logger = Logger:New("ˮ·���ƺ���", 15),
    CastTime = 100 + 320 + 100
}

function PoolImitaterDoomShroom:New()
    local o = {cancel = false}
    setmetatable(o, {__index = PoolImitaterDoomShroom})
    return o
end

function PoolImitaterDoomShroom:ColdDown ()
    local imitaterDoomShroomCd = math.max(
        0,
        GetCardColdDown(Plants.Imitater) - 100
    )

    local lilyPadCd = math.max(
        0,
        GetCardColdDown(Plants.LilyPad) - 100
    )

    local cd = math.max(
        MinPoolCraterColdDown(),
        GetCardColdDown(Plants.IceShroom),
        imitaterDoomShroomCd,
        lilyPadCd
    )

    if cd > 0 then
        self.Logger:Info("ˮ·���ƺ������ʣ�ࣺ" .. cd)
    else
        self.Logger:Info("ˮ·�����Ѿ�����")
    end

    return cd
end

function PoolImitaterDoomShroom:Run (cs, noIce)
    if type(cs) == 'number' then
        Wait(cs)
    end

    local timeout, mRow, mCol = MinPoolCrater()
    local jackRow
    if mRow == 2 then jackRow = 1 else jackRow = 4 end

    noIce = noIce or
            Context.currentWave == 9 and
            not Zombies.Find(function(z)
                return z.type == Zombies.GigaGargantuar and z.hp > 1200
            end) and
            not Zombies.Find(function (z)
                return z.type == Zombies.Jack and z.row == jackRow or
                       z.row == mRow and
                           z.type ~= Zombies.Balloon and
                           z.type ~= Zombies.Dolphin and
                           -- ���ˮ·��Ӧ�еĽ�ʬ���ڿ�ҧ��˵�����Ѿ���ҧˮ·ǰ����Ϲ��ˡ�
                           not z.eating
            end)

    if self.cancel then
        self.Logger:Info("ˮ·���ƺ����ѱ�ȡ��")
        return
    end

    if not noIce then
        GrowInstantPlant(Plants.IceShroom)
    else
        self.Logger:Info("û������в�Ľ�ʬ��������ʹ�ñ�����")
        Wait(timeout + 1)
        GrowPlant(Plants.LilyPad, mRow, mCol)
        GrowPlant(Plants.Imitater, mRow, mCol)
    end
    Wait(100)

    for col = 6, 8 do
        for row = 2, 3 do
            if Context.gridGrowable[row][col] then
                WaitUntilCardAvailable(Plants.Imitater)
                GrowPlant(Plants.LilyPad, row, col)
                GrowPlant(Plants.Imitater, row, col)
                self.Logger:Info("ˮ·���ƺ����ͷ���ϡ�")
                return
            end
        end
    end
end

local CherryAndJalapenoEnding = {
    Name = "ӣ��������β",
    Logger = Logger:New("ӣ��������β", 15),
    CastTime = 100
}

function CherryAndJalapenoEnding:ColdDown()
    return math.min(GetCardColdDown(Plants.Cherry), GetCardColdDown(Plants.Jalapeno))
end

function CherryAndJalapenoEnding:Run()
    self.coroutines = {
        coroutine.wrap(function()
            if not Zombies.Find(function(z)
                return (z.type == Zombies.Gargantuar or
                       z.type == Zombies.GigaGargantuar) and
                       (z.row == 0 or z.row == 1)
            end)
            then
                self.Logger:Info("1��2·û�о��ˣ�����ʹ��ӣ�ҡ�")
                return
            end

            GrowCherry()
            self.Logger:Info("ӣ���ͷ���ϡ�")
        end),

        coroutine.wrap(function()
            if not Zombies.Find(function(z)
                return (z.type == Zombies.Gargantuar or
                       z.type == GigaGargantuar) and
                       z.row == 5
            end)
            then
                self.Logger:Info("6·û�о��ˣ�����ʹ��������")
                return
            end

            GrowJalapeno()
            self.Logger:Info("�����ͷ���ϡ�")
        end)
    }

    self.coroutines[1]()
    self.coroutines[2]()
end

return {
GrowJalapeno = GrowJalapeno,
IsFastZombieLineup = IsFastZombieLineup,
PumpkinFixer = PumpkinFixer,
CherryAndJalapeno = CherryAndJalapeno,
CherryAndDelayedJalapeno = CherryAndDelayedJalapeno,
CherryAndJalapenoEnding = CherryAndJalapenoEnding,
PoolDoomShroom = PoolDoomShroom,
PoolImitaterDoomShroom = PoolImitaterDoomShroom,

BalloonTrack = function ()
    if not IsCardAvailable(Plants.Blover) then
        return
    end

    if Zombies.Find(function (z)
        return z.type == Zombies.Balloon and z.x <= 50
    end)
    then
        GrowPlant(Plants.Blover)
    end
end,

FumeFixer = function ()
    if not IsCardAvailable(Plants.FumeShroom) then
        return
    end

    local status = {
        [1] = {false, false},
        [2] = {false, false},
        [5] = {false, false},
        [6] = {false, false}
    }
    Plants.ForEach(function(p)
        if p.type == Plants.FumeShroom and (p.col == 3 or p.col == 4) then
            status[p.row + 1][p.col - 2] = true
        end
    end)

    for _, row in pairs({1, 6, 2, 5}) do
        for col = 4, 5 do
            if not status[row][col - 3] then
                if GrowPlant(Plants.FumeShroom, row - 1, col - 1) then
                    return
                end
            end
        end
    end
end

}

