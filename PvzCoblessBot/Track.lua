local common = require('CommonStrategy')
local Scheduler = require('Scheduler')

local GrowJalapeno = common.GrowJalapeno
local IsFastZombieLineup = common.IsFastZombieLineup

local PoolDoomShroom = common.PoolDoomShroom
local PoolImitaterDoomShroom = common.PoolImitaterDoomShroom

local CherryAndJalapeno = common.CherryAndJalapeno
local CherryAndDelayedJalapeno = common.CherryAndDelayedJalapeno
local CherryAndJalapenoEnding = common.CherryAndJalapenoEnding

local SquashAndSpikeweed = coroutine.wrap((function ()
    local logger = Logger:New("���ϵش̹���", 26)
    return function ()
        while true do
            Wait(1200)
            if IsCardAvailable(Plants.Squash) then
                if Zombies.Find(function (z)
                    return (z.type == Zombies.Zomboni or
                           z.type == Zombies.GigaGargantuar or
                           z.type == Zombies.Gargantuar) and
                           z.row == 0
                end)
                then
                    logger:Info("ʹ�����ϱ���1·��")
                    GrowPlant(Plants.Squash, 0, 6)
                end
            elseif Zombies.Find(function (z)
                return z.type == Zombies.Zomboni and z.row == 0
            end)
            then
                logger:Info("������δ׼���ã�ʹ�õش������")
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
                logger:Info("6·�ش��Ѿ��ͷš�")
            end

            coroutine.yield()
        end
    end
end)());

local logger = Logger:New("���ٹز���")
local DoomShroomStartup = {
    [1] = function ()
        Wait(200)
        GrowInstantPlant(Plants.DoomShroom, 1, 8)
    end,

    [2] = function ()
        Wait(150)
        GrowInstantPlant(Plants.IceShroom)
        Wait(110)
        GrowInstantPlant(Plants.Squash, 0, 8)
        Wait(400)
        GrowInstantPlant(Plants.Imitater, 4, 6)
    end,

    [3] = function ()
        if ZombieLineup.GigaGargantuar and ZombieLineup.Gargantuar then
            CherryAndJalapeno:Run(900)
        else
            CherryAndDelayedJalapeno:Run(900)
        end
    end
}

local MidLevelStartup = function (sched)
return {
    [10] = function(wave)
        Wait(150)
        GrowJalapeno()
        if IsCardAvailable(Plants.Squash) then
            GrowInstantPlant(Plants.Squash, 0, 8)
            Wait(500)
        else
            Wait(150)
            GrowInstantPlant(Plants.SpikeWeed, 2, 8)
            Wait(350)
        end
        GrowInstantPlant(Plants.Cherry, 1, 4)

        Wait(650)
        if IsCardAvailable(Plants.Squash) then
            GrowInstantPlant(Plants.Squash, 5, 6)
        else
            GrowInstantPlant(Plants.SpikeWeed, 5, 6)
        end

        sched:Run(10, 1100)
    end,

    [11] = sched,
    [12] = sched
}

return {
    [10] = function(wave)
        Wait(150)
        if IsCardAvailable(Plants.Squash)
            GrowInstantPlant(Plants.Squash)
        end
    end
}
end

-- ��9��19�Լ�20����β�߼�
local ending = function(sched)
    return function(wave)
        if IsFastZombieLineup(wave) then
            logger:Info("��9��û�о��˽�ʬ�����������Ϻ͵ش�����ʱ�䡣")
            for _, op in pairs(sched.selected) do
                op.cancel = true
            end
            SquashAndSpikeweed()
        else
            sched(wave)
        end

        -- ѡ����õ���β������
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
        
        Wait(math.max(1600 - minOp.CastTime, cd))

        if not Zombies.Find(function (z)
            return z.row ~= 4 and (
                (z.type == Zombies.GigaGargantuar and z.hp > 2800) or
                (z.type == Zombies.Gargantuar and z.hp > 1200)
            )
        end)
        then
            logger:Info("������1Ѫ�����Ϻ��ۺ�����ֵ����1200�İ��ۣ���ȥ��β��")
            return
        end

        if InstanceOf(minOp, PoolImitaterDoomShroom) then
            minOp:Run(0, true)
        else
            minOp:Run()
        end
    end
end

local Track = {}
return {
    DoomShroomStartup = {
        Run = function ()
            local ops = {
                PoolDoomShroom,
                PoolImitaterDoomShroom
            }
            Track = {}

            if ZombieLineup.GigaGargantuar and ZombieLineup.Gargantuar then
                table.insert(ops, CherryAndJalapeno)
            else
                table.insert(ops, CherryAndDelayedJalapeno)
            end

            local sched = Scheduler:New(ops)

            for i = 1, 9 do
                local f

                if i >= 4 and i <= 8 then
                    f = sched
                elseif i == 9 then
                    f = ending(sched)
                else
                    f = DoomShroomStartup[i]
                end

                Track[i] = coroutine.wrap((function (wave)
                    return function ()
                        WaitUntilSpawn(wave)
                        f(wave)
                    end
                end)(i))
            end

            for _, f in pairs(Track) do
                f()
            end
        end
    }
}