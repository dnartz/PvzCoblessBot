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

-- ���㰶·7�еĺ������ʣ��CD�����������Լ�����CD��
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

local HalfDoomShroom = {
    Name = "������ֲ�����",
    Logger = Logger:New("������ֲ�����", 14),
}

-- ��ʼ��ԭ����俪��������
-- �ú�����������ʱ�����ã������CD�ǳ���Ԥ����Чʱ�����������
function HalfDoomShroom:New(sched)
    local o = {
        sched = sched,
        co = {}
    }

    local gridCD, doomRow = DoomGridCD(6)
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
    self.Logger:Info("����ʱ�䣺���ֲ�ˢ�º�" .. o.cd .. "��")
    setmetatable(o, {__index = HalfDoomShroom})

    return o
end

function HalfDoomShroom:Run(wave)
    local spawnedAt = Context.gameTime
    Wait(150)
    GrowInstantPlant(self.edgePlant, self.edgeRow, 8)
    Wait(200)
    GrowInstantPlant(Plants.DoomShroom, self.doomRow, 6)
    self.Logger:Info("�����ͷ���ϡ�")

    -- ���δ�ܵ����乥���ı�·�Ƿ���ڱ������еĻ����ϻ��ߵش��ź�
    table.insert(self.co, ZomboniProtect(wave, 1600, self.edgeRow, 6))
    self.co[#self.co]()

    -- �ڰ�·��һ�ε��ӡ�
    if wave == 10 then
        WaitBeforeSpawn(110, 11)
        -- ��֤���ƺ���û�б�������ѹ�ķ��ա�
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
    Name = "���ƺ�����ֲ�����",
    Logger = Logger:New("���ƺ�����ֲ�����", 14)
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
    o.Logger:Info("���ƺ�����ֲ�����ʣ��CD��" .. o.cd)
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
    Name = "ӣ���������ֲ�����",
    Logger = Logger:New("ӣ���������ֲ�����", 14)
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
    o.Logger:Info("ӣ���������ʣ��CD��" .. o.cd)
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
    -- TODO��С͵������вˮ·�����Լ�è�������
    GrowInstantPlant(Plants.Cherry, 1, 4)
    GrowInstantPlant(Plants.Jalapeno, 5, 5)

    WaitUntilSpawn(11, 0, 1250)
    -- ��ʬ����ˢ�£��ٵ�һ�ᡣ
    if Context.spawnCountdown >= 200 then
        WaitUntilSpawn(11, 210)
    end

    -- ���۵�11����ʬˢ��������Ƕ�ʹ�ú��䡣
    GrowPlant(Plants.DoomShroom, self.doomRow, self.doomCol)

    -- ����11��ˢ��ʱ�����1·�б�������ô���Ǳ�Ȼ��Ҫ����ӣ��λ��
    -- ��Ϊ��12���Ļҽ�������Ȼ���ڵ�11����1·������������7�С�
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

    -- ������ڵ�10������ô�͵ȴ�11��ˢ�¡�
    -- Ȼ�󽫲�����������ҽ�������������
    if Context.currentWave ~= 11 then
        WaitUntilSpawn()
        o.sched(Context.currentWave)
    end
end

local logger = Logger:New("���ַ�ʽѡ��", 17)
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

        logger:Info("ѡ��" .. op.Name .. "�����ֲ�ˢ��֮��ʣ��CD��" .. op.cd)
        return op
    end
}