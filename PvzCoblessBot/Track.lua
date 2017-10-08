local common = require('CommonStrategy')
local Scheduler = require('Scheduler')
local Ending = require('Ending')

local PoolDoomShroom = common.PoolDoomShroom
local PoolImitaterDoomShroom = common.PoolImitaterDoomShroom

local CherryAndJalapeno = common.CherryAndJalapeno
local CherryAndDelayedJalapeno = common.CherryAndDelayedJalapeno

local logger = Logger:New("变速关策略")
local DoomShroomStartup = {
    [1] = function ()
        Wait(300)
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

local Track = {}

return {
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

        for i = 1, 20 do
            local f

            if i >= 4 and i <= 8 or i >= 12 and i <= 18 then
                f = sched
            elseif i == 9 or i == 19 then
                f = Ending:New(sched, Track)
            elseif i <= 3 then
                f = DoomShroomStartup[i]
            end

            if type(f) ~= 'nil' then
                Track[i] = coroutine.wrap((function (wave)
                    return function ()
                        WaitUntilSpawn(wave)
                        f(wave)
                    end
                end)(i))

                Track[i]()
            end
        end
    end
}