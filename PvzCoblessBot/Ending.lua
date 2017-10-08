local common = require('CommonStrategy')
local Startup = require('Startup')

local IsFastZombieLineup = common.IsFastZombieLineup
local PoolDoomShroom = common.PoolDoomShroom
local PoolImitaterDoomShroom = common.PoolImitaterDoomShroom
local CherryAndJalapenoEnding = common.CherryAndJalapenoEnding

local Ending = {}

local logger = Logger:New("倭瓜地刺过渡", 26)
local SquashAndSpikeweedThread = coroutine.wrap(function ()
    ::again::

    Wait(1200)
    if IsCardAvailable(Plants.Squash) then
        if Zombies.Find(function (z)
            return (z.type == Zombies.Zomboni or
                   z.type == Zombies.GigaGargantuar or
                   z.type == Zombies.Gargantuar) and
                   z.row == 0
        end)
        then
            logger:Info("使用倭瓜保护1路。")
            GrowPlant(Plants.Squash, 0, 6)
        end
    elseif Zombies.Find(function (z)
        return z.type == Zombies.Zomboni and z.row == 0
    end)
    then
        logger:Info("倭瓜尚未准备好，使用地刺替代。")
        GrowPlant(Plants.SpikeWeed, 0, 6)
    end

    WaitUntilCardAvailable(Plants.SpikeWeed)
    if Zombies.Find(function (z)
        return z.type == Zombies.Zomboni and z.row == 5
    end)
    then
        if Context.gridGrowable[5][6] then
            GrowPlant(Plants.SpikeWeed, 5, 6)
        elseif Context.gridGrowable[5][5] then
            Wait(300)
            GrowPlant(Plants.SpikeWeed, 5, 5)
        else
            Wait(600)
            GrowPlant({
                plant = Plants.SpikeWeed,
                row = 5,
                col = 4,
                remove = true
            })
        end
        logger:Info("6路地刺已经释放。")
    end

    coroutine.yield()
    goto again
end);

-- 收尾线程，红字有可能在16秒内出现。
-- 因此我们在另外一个线程中等待下一次收尾使用。
local EndingThread = coroutine.wrap(function(logger)
    -- 选择可用的收尾操作。
    local minOp = CherryAndJalapenoEnding
    local cd = CherryAndJalapenoEnding:ColdDown()

    for _, op in pairs({
        PoolDoomShroom:New(),
        PoolImitaterDoomShroom:New()
     }) do
        local tCd = op:ColdDown()
        if tCd < cd then
            cd = tCd
            minOp = op
        end
    end
    logger:Info("选择的收尾操作：" .. minOp.Name)
    
    Wait(math.max(1600 - minOp.CastTime, cd))

    if not Zombies.Find(function (z)
        return z.row ~= 4 and
        (z.spawnedAt <= 9) and
        ((z.type == Zombies.GigaGargantuar and z.hp > 2800) or
         (z.type == Zombies.Gargantuar and z.hp > 1200) or
         (z.row == 0 and
             (z.type == Zombies.Gargantuar or
              z.type == Zombies.GigaGargantuar) and
          z.hp > 600))
    end)
    then
        logger:Info("不存在1血及以上红眼和生命值大于1200的白眼，免去收尾。")
        return
    end

    -- 收尾之前，我们先计算另外两种中场起手的最短时间。
    -- 判断如果此次收尾操作触发红字之后，是否会导致后续起手的植物未准备好。
    local startup = {}
    if minOp.Name ~= PoolDoomShroom.Name then
        table.insert(startup, Startup.HalfStartup.DoomShroom:New().cd)
    end

    if minOp.Name ~= PoolImitaterDoomShroom.Name then
        table.insert(startup, Startup.HalfStartup.ImitaterDoomShroom:New().cd)
    end

    if minOp ~= CherryAndJalapenoEnding then
        table.insert(startup, CherryAndJalapenoEnding:ColdDown())
    end

    -- 使用了当前收尾方案的植物之后，还有两种中场起手方式可选。
    assert(#startup == 2)
    local cd = math.max(0, math.min(startup[1], startup[2]) - 200)
    if cd >= 200 then
        logger:Info("等待" .. cd .. "后执行收尾，才能衔接中场起手。")
        Wait(cd)
    end

    -- 如果已经出现红字，那么终止释放。
    if Context.spawnCountdown <= 200 or Context.alertCountdown > 0 then
        logger:Info("红字已经出现，放弃收尾。")
        return
    end

    if minOp.Name == PoolImitaterDoomShroom.Name then
        minOp:Run(0, true)
    else
        minOp:Run()
    end
end)

function Ending:New(sched, track)
    local o = {
        sched = sched,
        track = track,
        Logger = Logger:New("中场过渡策略", 15)
    }

    setmetatable(o, {
        __index = Ending,
        __call = function(t, wave)
            o:Run(wave)
        end
    })
    return o
end

function Ending:Run(wave)
    if IsFastZombieLineup(wave) then
        self.Logger:Info("第" .. wave .."波没有巨人僵尸，将采用倭瓜和地刺拖延时间。")
        -- 取消调度器里的全部灰烬操作，防止炸光全部快速僵尸。
        self.sched:Cancel(wave)
        SquashAndSpikeweedThread()
    else
        self.sched(wave)
        EndingThread(self.Logger)
    end

    WaitRedAlert()
    local op = Startup.SelectHalfStartup(self.sched)
    self.track[wave + 1] = coroutine.wrap(function(w)
        WaitUntilSpawn(w)
        op:Run(w)
    end)
    self.track[wave + 1](wave + 1)
end

return Ending