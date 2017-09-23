-- ���㰶·7�еĺ������ʣ��CD�����������Լ�����CD��
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
        -- ������������²���ʬˢ��֮ǰ�ָ��ã���ô���ǲ��ý���CD���뵽�����С�
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
    Logger = Logger:New("������ֲ�����", 14),
}

-- ��ʼ��ԭ����俪��������
-- �ú�����������ʱ�����ã������CD�ǳ���Ԥ����Чʱ�����������
function HalfDoomshroom:New(sched)
    local o = {
        sched = sched
    }

    local gridCD, doomRow = DoomGridCD()
    o.doomRow = doomRow

    -- ȷ������/�ش�Ҫ�ŵ��С�
    if o.doomRow == 1 then
        o.edgeRow = 5
    else
        o.edgeRow = 0
    end

    local doomCD = math.max(0, GetCardColdDown(Plants.DoomShroom) - 1100)

    -- ѡ���·ֲ�
    -- �ش��ں��ֺ�ˢ��ʱ���ǿ��õģ�������ǲ���Ҫ�ѱ�·ֲ��ľ���ʱ����ΪCD����Ĳ�����
    -- ��Ϊ��ʱ��һ��ʹ�õش̵�ʱ������ֻ����1·����������������7��ʱʹ�ã��㹻ʱ��ָ���
    if math.max(0, GetCardColdDown(Plants.Squash) - 1100) > 0 then
        o.edgePlant = Plants.SpikeWeed
    else
        o.edgePlant = Plants.Squash
    end

    o.cd = math.max(gridCD, doomCD)
    self.Logger:Info("����ʱ�䣺���ֲ�ˢ�º�" .. cd .. "��")
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
    -- ��ʬ����ˢ�£����ǻ�û�е�����ʱ1.1�롣
    if Context.spawnCountdown >= 200 && Context.spawnCountdown < 110 then
        Wait(Context.spawnCountdown - 110)
    end

    -- �����ڰ�·��һ�ε��ӡ�
    if (Context.currentWave == 11 or Context.spawnCountdown <= 110) and
        IsCardAvailable(Plants.IceShroom) and
        GetCardColdDown(Plants.Imitater) <= 100 and
        Context.gridGrowable[self.doomRow][8]
    then
        GrowPlant(Plants.IceShroom)
        Delay(100)
        GrowPlant(Plants.Imitater, self.doomRow, 8, false, true)
        self.Logger:Info("�ɹ�����2·���ӡ�")
    else
        self.Logger:Info("��������·��2���ӡ�")
        self.sched(Context.currentWave, context.gameTime - spawnedAt)
    end
end

local HalfImitaterDoomShroom = {
    Logger = Logger:New("���ƺ�����ֲ�����", 14)
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
    o.Logger:Info("���ƺ�����ֲ�����ʣ��CD��" .. o.cd)
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
    -- ��ʬ����ˢ�£����ǻ�û�е�����ʱ1.1�룬�Ǿ��ٵ�һ�ᡣ
    if Context.spawnCountdown >= 200 && Context.spawnCountdown < 110 then
        Wait(Context.spawnCountdown - 110)
    end
end

local HalfCherryAndJalapeno = {
    Logger = Logger:New("ӣ���������ֲ�����", 14)
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
    o.Logger:Info("ӣ���������ʣ��CD��" .. cd)
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