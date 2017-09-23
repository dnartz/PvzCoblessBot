-- 计算岸路7列的核武格子剩余CD（包括冰道以及弹坑CD）
local DoomGridCD = function()
    local timeout = {
        [1] = 0,
        [4] = 0
    }
    local gridCD, row
    Craters.ForEach(function (c)
        if c.col == 6 and (c.row == 1 or c.row == 4) then
            timeout[c.row] = c.timeout
        end
    end)

    for i = 1, 4, 3 do
        if Context.icePath[x] < 588 then
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

local HalfDoomshroom = {
    Logger = Logger:New("核武红字波起手", 14),
}

-- 初始化原版核武开场操作。
-- 该函数在跳红字时被调用，计算的CD是超出预期生效时间的厘秒数。
function HalfDoomshroom:New(sched)
    local o = {
        sched = sched
    }

    local gridCD, doomRow = DoomGridCD()
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
    self.Logger:Info("就绪时间：红字波刷新后" .. cd .. "。")
    setmetatable(o, {__index = HalfDoomShroom})

    return o
end

function HalfDoomShroom:Run(wave)
    local spawnedAt = conetxt.gameTime
    Wait(150)
    GrowInstantPlant(self.edgePlant, self.edgeRow, 8)
    wait(200)
    GrowInstantPlant(Plants.DoomShroom, self.doomRow, 6)

    WaitBeforeSpawn(110, 11, 1450)
    -- 僵尸即将刷新，但是还没有到倒计时1.1秒。
    if Context.spawnCountdown >= 200 && Context.spawnCountdown < 110 then
        Wait(Context.spawnCountdown - 110)
    end

    -- 尝试在岸路抢一次弹坑。
    if (Context.currentWave == 11 or Context.spawnCountdown <= 110) and
        IsCardAvailable(Plants.IceShroom) and
        GetCardColdDown(Plants.Imitater) <= 100 and
        Context.gridGrowable[self.doomRow][8]
    then
        GrowPlant(Plants.IceShroom)
        Delay(100)
        GrowPlant(Plants.Imitater, self.doomRow, 8, false, true)
        self.Logger:Info("成功抢到2路弹坑。")
    else
        self.Logger:Info("放弃抢岸路第2弹坑。")
        self.sched(Context.currentWave, context.gameTime - spawnedAt)
    end
end

local HalfImitaterDoomShroom = {
    Logger = Logger:New("复制核武红字波起手", 14)
}

function HalfImitaterDoomShroom:New(sched)
    local o = {
        sched = sched
    }

    local gridCD, doomRow = DoomGridCd()
    o.doomRow = doomRow
    if doomRow == 1 then
        o.edgeRow = 5
    else
        o.edgeRow = 0
    end

    o.cd = math.max(o, math.max(
        GetCardColdDown(Plants.IceShroom),
        GetCardColdDown(Plants.Imitater)
    ) - 1100)

    setmetatable(o, {__index = HalfImitaterDoomShroom})
    o.Logger:Info("复制核武红字波起手剩余CD：" .. o.cd)
    return o
end

function HalfImitaterDoomShroom:Run()
    Delay(150)
    GrowPlant(Plants.Imitater, self.doomRow, 6)

    if IsCardAvailable(Plants.Squash) then
        GrowPlant(Plants.Squash, self.edgeRow, 8)
    else
        GrowPlant(Plants.SpikeWeed, self.edgeRow, 8)
    end

    Delay(320)
    GrowInstantPlant(Plants.IceShroom)

    WaitBeforeSpawn(110, 11, 1450)
    -- 僵尸即将刷新，但是还没有到倒计时1.1秒，那就再等一会。
    if Context.spawnCountdown >= 200 && Context.spawnCountdown < 110 then
        Wait(Context.spawnCountdown - 110)
    end
end

local HalfCherryAndJalapeno = {
    Logger = Logger:New("樱桃辣椒红字波起手", 14)
}
function HalfCherryAndJalapeno:New(sched)
    local o = {
        sched = sched
        cd = math.min(0, math.max(
            GetCardColdDown(Plants.Cherry),
            GetCardColdDown(Plants.Jalapeno)
        ) - 1100)
    }

    setmetatable(o, {__index = HalfCherryAndJalapeno})
    o.Logger:Info("樱桃辣椒组合剩余CD：" .. cd)
    return o
end

function HalfCherryAndJalapeno:Run(wave)
    Delay(150)
    if IsCardAvailable(Plants.Squash) then
        GrowPlant(Plants.Squash, 0, 8)
    else
        GrowPlant(Plants.SpikeWeed, 0, 8)
    end

    Delay(200)
    GrowInstantPlant(Plants.Cherry, 1, 3)
    GrowInstantPlant(Plants.Jalapeno, 5, 4)
    self.sched(wave, 350)
end

return {
    LevelBegin = {},
    HalfStartup = {
        DoomShroom = HalfDoomShroom,
        ImitaterDoomShroom = HalfImitaterDoomShroom,
        CherryAndJalapeno = HalfCherryAndJalapeno
    }
}