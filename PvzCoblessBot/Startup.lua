local ZomboniProtect = function(wave, ...)
    local arguments = {...}
    local delay, row, col

    assert(#arguments >= 2)
    if #arguments == 2 then
        row, col = arguments
        delay = 0
    else
        delay, row, col = unpack(arguments)
    end
    return coroutine.wrap(function ()
        WaitUntilSpawn(wave, delay)
        if Zombies.Find(function (z)
            return z.row == row and
                   z.spawnedAt == wave and 
                   z.type == Zombies.Zomboni
        end)
        then
            local minPlant = Plants.Squash
            if GetCardColdDown(Plants.SpikeWeed) < GetCardColdDown(Plants.Squash)
            then
                minPlant = Plants.SpikeWeed
            end

            WaitUntilCardAvailable(minPlant)
            GrowInstantPlant(minPlant, row, col)
        end
    end)
end

-- 计算岸路7列的核武格子剩余CD（包括冰道以及弹坑CD）
local DoomGridCD = function(col)
    local timeout = {
        [1] = 0,
        [4] = 0
    }
    local gridCD, row
    Craters.ForEach(function (c)
        if c.col == col and (c.row == 1 or c.row == 4) then
            timeout[c.row] = c.timeout
        end
    end)

    for i = 1, 4, 3 do
        if Context.icePathX[i] < IcePathLimit[col] then
            timeout[i] = math.max(timeout[i], Context.icePathTimeout[i])
        end
        -- 如果弹坑能在下波僵尸刷新之前恢复好，那么我们不用将其CD纳入到计算中。
        timeout[i] = math.max(timeout[i] - 1100, 0)
    end

    gridCD = math.min(timeout[1], timeout[4])
    if gridCD == timeout[4] then
        row = 4
    else
        row = 1
    end

    return gridCD, row
end

local HalfDoomShroom = {
    Name = "核武红字波起手",
    Logger = Logger:New("核武红字波起手", 14),
}

-- 初始化原版核武开场操作。
-- 该函数在跳红字时被调用，计算的CD是超出预期生效时间的厘秒数。
function HalfDoomShroom:New(sched)
    local o = {
        sched = sched,
        co = {}
    }

    local gridCD, doomRow = DoomGridCD(6)
    o.doomRow = doomRow

    -- 确定倭瓜/地刺要放的列。
    if o.doomRow == 1 then
        o.edgeRow = 5
    else
        o.edgeRow = 0
    end

    local doomCD = math.max(0, GetCardColdDown(Plants.DoomShroom) - 1100)

    -- 选择边路植物。
    -- 地刺在红字后刷怪时总是可用的，因此我们不需要把边路植物的就绪时间作为CD计算的参数。
    -- 因为此时上一次使用地刺的时间最晚只会在1路冰车冰道即将到达7列时使用，足够时间恢复。
    if math.max(0, GetCardColdDown(Plants.Squash) - 1100) > 0 then
        o.edgePlant = Plants.SpikeWeed
    else
        o.edgePlant = Plants.Squash
    end

    o.cd = math.max(gridCD, doomCD)
    self.Logger:Info("就绪时间：红字波刷新后" .. o.cd .. "。")
    setmetatable(o, {__index = HalfDoomShroom})

    return o
end

function HalfDoomShroom:Run(wave)
    local spawnedAt = Context.gameTime
    Wait(150)
    GrowInstantPlant(self.edgePlant, self.edgeRow, 8)
    Wait(200)
    GrowInstantPlant(Plants.DoomShroom, self.doomRow, 6)
    self.Logger:Info("核武释放完毕。")

    -- 检查未受到核武攻击的边路是否存在冰车，有的话倭瓜或者地刺伺候。
    table.insert(self.co, ZomboniProtect(wave, 1600, self.edgeRow, 6))
    self.co[#self.co]()

    -- 在岸路抢一次弹坑。
    if wave == 10 then
        WaitBeforeSpawn(110, 11)
        -- 保证复制核武没有被冰车碾压的风险。
        table.insert(self.co, ZomboniProtect(11, 200, self.doomRow, 8))
        self.co[#self.co]()
    else
        Wait(1600)
    end

    WaitUntilCardAvailable(Plants.IceShroom)
    Wait(math.max(0, GetCardColdDown(Plants.Imitater) - 100))
    GrowPlant(Plants.IceShroom)
    GrowInstantPlant(Plants.Imitater, self.doomRow, 8)
end

local HalfImitaterDoomShroom = {
    Name = "复制核武红字波起手",
    Logger = Logger:New("复制核武红字波起手", 14)
}

function HalfImitaterDoomShroom:New(sched)
    local o = {
        sched = sched
    }

    local gridCD, doomRow = DoomGridCD(6)
    o.doomRow = doomRow
    if doomRow == 1 then
        o.edgeRow = 5
    else
        o.edgeRow = 0
    end

    o.cd = math.max(0, math.max(
        GetCardColdDown(Plants.IceShroom) - 1220,
        GetCardColdDown(Plants.Imitater) - 900
    ))

    setmetatable(o, {__index = HalfImitaterDoomShroom})
    o.Logger:Info("复制核武红字波起手剩余CD：" .. o.cd)
    return o
end

function HalfImitaterDoomShroom:Run()
    local spawnAfter = Context.gameTime

    Wait(150)
    GrowPlant(Plants.Imitater, self.doomRow, 6)

    if IsCardAvailable(Plants.Squash) then
        GrowInstantPlant(Plants.Squash, self.edgeRow, 8)
    else
        GrowInstantPlant(Plants.SpikeWeed, self.edgeRow, 8)
    end

    Wait(320)
    GrowInstantPlant(Plants.IceShroom)

    WaitUntilSpawn(Context.currentWave + 1, 0, 1130)
    if Context.currentWave == 10 then
        self.sched(Context.currentWave, 1600)
    else
        self.sched(Context.currentWave)
    end
end

local HalfCherryAndJalapeno = {
    Name = "樱桃辣椒红字波起手",
    Logger = Logger:New("樱桃辣椒红字波起手", 14)
}
function HalfCherryAndJalapeno:New(sched)
    local o = {
        sched = sched,
        cd = math.max(0, math.max(
            GetCardColdDown(Plants.Cherry),
            GetCardColdDown(Plants.Jalapeno)
        ) - 1100)
    }

    local g1, r1 = DoomGridCD(8)
    local g2, r2 = DoomGridCD(7)
    local doomRow, doomCol
    if g1 < g2 then
        o.doomRow = r1
        o.doomCol = 7
    else
        o.doomRow = r2
        o.doomCol = 8
    end

    setmetatable(o, {__index = HalfCherryAndJalapeno})
    o.Logger:Info("樱桃辣椒组合剩余CD：" .. o.cd)
    return o
end

function HalfCherryAndJalapeno:Run(wave)
    Wait(250)
    if IsCardAvailable(Plants.Squash) then
        GrowPlant(Plants.Squash, 0, 8)
    else
        GrowPlant(Plants.SpikeWeed, 0, 8)
    end

    Wait(100)
    -- TODO：小偷不会威胁水路曾哥以及猫的情况。
    GrowInstantPlant(Plants.Cherry, 1, 4)
    GrowInstantPlant(Plants.Jalapeno, 5, 5)

    WaitUntilSpawn(11, 0, 1250)
    -- 僵尸即将刷新，再等一会。
    if Context.spawnCountdown >= 200 then
        WaitUntilSpawn(11, 210)
    end

    -- 无论第11波僵尸刷新与否，我们都使用核武。
    GrowPlant(Plants.DoomShroom, self.doomRow, self.doomCol)

    -- 当第11波刷新时，如果1路有冰车，那么我们必然需要保护樱桃位。
    -- 因为第12波的灰烬操作必然晚于第11波的1路冰车冰道到达7列。
    if Context.currentWave == 11 and
       doomRow ~= 1 and
       Zombies.Find(function (z)
           return z.type == Zombies.Zomboni and
                  z.row == 0 and
                  z.spawnedAt == 11
       end)
    then
        Wait(1100)
        if IsCardAvailable(Plants.Squash) then
            GrowInstantPlant(Plants.Squash, 0, 6)
        else
            GrowInstantPlant(Plants.SpikeWeed, 0, 6)
        end
    end

    -- 如果还在第10波，那么就等待11波刷新。
    -- 然后将操作交给常规灰烬操作调度器。
    if Context.currentWave ~= 11 then
        WaitUntilSpawn()
        o.sched(Context.currentWave)
    end
end

local logger = Logger:New("起手方式选择", 17)
return {
    LevelStartup = {},

    HalfStartup =  {
        DoomShroom = HalfDoomShroom,
        ImitaterDoomShroom = HalfImitaterDoomShroom,
        CherryAndJalapeno = HalfCherryAndJalapeno
    },

    SelectHalfStartup = function (sched)
        local op = HalfDoomShroom:New(sched)
        if op.cd == 0 then
            return op
        end

        for _, o in pairs({
            HalfImitaterDoomShroom:New(sched),
            HalfCherryAndJalapeno:New(sched)
        }) do
            if o.cd == 0 then
                return o
            elseif o.cd < op.cd then
                op = o
            end
        end

        logger:Info("选择" .. op.Name .. "，红字波刷新之后剩余CD：" .. op.cd)
        return op
    end
}