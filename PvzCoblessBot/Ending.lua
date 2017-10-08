local common = require('CommonStrategy')
local Startup = require('Startup')

local IsFastZombieLineup = common.IsFastZombieLineup
local PoolDoomShroom = common.PoolDoomShroom
local PoolImitaterDoomShroom = common.PoolImitaterDoomShroom
local CherryAndJalapenoEnding = common.CherryAndJalapenoEnding

local Ending = {}

local logger = Logger:New("���ϵش̹���", 26)
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
    goto again
end);

-- ��β�̣߳������п�����16���ڳ��֡�
-- �������������һ���߳��еȴ���һ����βʹ�á�
local EndingThread = coroutine.wrap(function(logger)
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
    logger:Info("ѡ�����β������" .. minOp.Name)
    
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
        logger:Info("������1Ѫ�����Ϻ��ۺ�����ֵ����1200�İ��ۣ���ȥ��β��")
        return
    end

    -- ��β֮ǰ�������ȼ������������г����ֵ����ʱ�䡣
    -- �ж�����˴���β������������֮���Ƿ�ᵼ�º������ֵ�ֲ��δ׼���á�
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

    -- ʹ���˵�ǰ��β������ֲ��֮�󣬻��������г����ַ�ʽ��ѡ��
    assert(#startup == 2)
    local cd = math.max(0, math.min(startup[1], startup[2]) - 200)
    if cd >= 200 then
        logger:Info("�ȴ�" .. cd .. "��ִ����β�������ν��г����֡�")
        Wait(cd)
    end

    -- ����Ѿ����ֺ��֣���ô��ֹ�ͷš�
    if Context.spawnCountdown <= 200 or Context.alertCountdown > 0 then
        logger:Info("�����Ѿ����֣�������β��")
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
        Logger = Logger:New("�г����ɲ���", 15)
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
        self.Logger:Info("��" .. wave .."��û�о��˽�ʬ�����������Ϻ͵ش�����ʱ�䡣")
        -- ȡ�����������ȫ���ҽ���������ֹը��ȫ�����ٽ�ʬ��
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