-- ����ҽ�����������
local Scheduler = {}
local logger = Logger:New("�ҽ���������", 24)

function Scheduler:New(available)
    local s = {
        -- Ŀǰ�ɹ�ѡ��Ļҽ�����
        available = available,

        -- ֮ǰ�Ѿ�ѡ��Ļҽ�����
        selected = {},

        -- �ȴ��̶߳��У��������available����Ϊ�յ�������͹���Э�̡�
        -- һ�㵽��������Ѿ�Ъ���ˣ������ǿ�����һ�Եȵ��лҽ��������ô��е������ָ���
        awaitCoroutines = {},

        -- �ҽ��ͷ�Ԥ��ʱ��������ڸ�ӣ�Ҹ񱣻��߼��ж��Ƿ���Ҫ������
        expectations = {}
    }

    setmetatable(s, {
        __index = Scheduler,
        __call = function(t, wave, afterSpawn)
            t:Run(wave, afterSpawn)
        end
    })

    return s
end

-- ����һ��ʣ����ȴʱ����̵Ļҽ�������
function Scheduler:Select()
    local j = 1
    local op = self.available[1]
    local cd = op:ColdDown()

    for i = 2, #self.available do
        local tOp = self.available[i]
        local tCd = tOp:ColdDown()

        if tCd < cd then
            cd = tCd
            op = tOp
            j = i
        end
    end

    return cd, op
end

-- ѡ��һ��δ����������ռ�ã���ʣ����ȴ��̵Ļҽ�������
function Scheduler:Acquire()
    -- ���ȫ���ҽ�������ռ�ã��ǻ���Ъ���ˡ�
    -- �����ǻ����Գ��Թ����̣߳��ȴ���Release���ѡ�
    if #self.available == 0 then
        table.insert(self.awaitCoroutines, coroutine.running())
        coroutine.yield()
    end

    local cd, op = self:Select()

    table.remove(self.available, j)
    return cd, op
end

-- ��ʹ����Ļҽ������Ż�Available���飬����й���Ĳ��δ����̣߳���ô�������ǡ�
function Scheduler:Release(op)
    table.insert(self.available, op)

    if #self.awaitCoroutines > 0 then
        local head = table.remove(self.awaitCoroutines, 1)
        coroutine.resume(head)
    end
end

-- �ж��Ƿ�ֱ����ʱ���cs֮ǰ����û�лҽ�ֲ�ﱣ��1·������
function Scheduler:HasNoProtectionBefore(cs)
    local len = #self.expectations
    while len > 0 and self.expectations[1] < Context.gameTime do
        table.remove(self.expectations, 1)
    end

    for _, t in pairs(self.expectations) do
        if t <= cs then
            return false
        end
    end

    return true
end

-- ӣ��λ�����߼������Ԥ�����лҽ��ᱬը���Ǿ�����������
local gLogger = Logger:New("ӣ��λ����", 2)
function Scheduler:GridProtect(wave)
    if Plants.Find(function (p)
        return p.type == Plants.Cherry
    end)
    then
        gLogger:Info("ӣ���Ѿ����ͷţ����豣����")
        return
    end

    if not Zombies.Find(function (z)
        return z.type == Zombies.Zomboni and
               z.spawnedAt == wave and
               z.row == 0
    end)
    then
        gLogger:Info("1·û�е�" .. wave .. "���ı�����7�б���ȡ����")
        return
    else
        gLogger:Info("1·�е�" .. wave .. "���ı�����")
    end

    if self:HasNoProtectionBefore(Context.gameTime + 500) then
        if IsCardAvailable(Plants.Squash) then
            GrowInstantPlant(Plants.Squash, 0, 6)
        else
            GrowInstantPlant(Plants.SpikeWeed, 0, 6)
        end
    else
        gLogger:Info("�Ѿ��лҽ�����1·��7�б���ȡ����")
    end
end

-- ִ��һ�λҽ�������ÿ����ʼʱ��Ϊһ������Э�̱����á�
-- �����ûҽ���ˢ�º�1600ʱ��ը������������ͷŻҽ���
function Scheduler:Run(wave, afterSpawn)
    if type(afterSpawn) == 'nil' then
        afterSpawn = 0
    end

    local cd, op = self:Acquire()
    local opImp = op:New()
    table.insert(self.selected, opImp)

    local effectiveAt = math.max(1600 - afterSpawn, cd + op.CastTime)
    local log = "ѡ��Ļҽ�������" ..  op.Name ..
                "����Чʱ�䣺ˢ�º�" ..  effectiveAt

    if effectiveAt + afterSpawn > 1600 then
        log = log .. "����Ҫ���ϱ���1·��"
    end
    logger:Info(log)

    -- ��ҽ���ЧԤ��ʱ������������һ��ֵ��
    table.insert(self.expectations, Context.gameTime + effectiveAt)

    -- �����Чʱ�䳬��ˢ�º�16�룬��1·7�п��ܻᱻ�����������ǡ�
    -- ��ᵼ��7���޷�����ӣ�ң�������Ҫ��������������7�е�ӣ��λ��
    Wait(1100 - afterSpawn)
    if effectiveAt + afterSpawn > 1600 then
        self:GridProtect(wave)
    end

    Wait(effectiveAt - 1100 - afterSpawn - op.CastTime)

    -- ������ͷŵ�9���Ļҽ�ʱ��֮ǰ���εĻҽ���û��ʼ�ͷţ��Ǿ�ȡ�����ǵ��ͷš�
    -- ��Ϊ�����Ϊ�����߼��ṩ����Ĳ���ѡ�񣬲���Ҳ���ᵼ��ӣ�Ҹ񱻱�����ռ��
    if wave == 9 then
        for _, o in pairs(self.selected) do
            if o ~= opImp then
                o.cancel = true
            end
        end
    end

    opImp:Run()
    self:Release(op)
end

return Scheduler