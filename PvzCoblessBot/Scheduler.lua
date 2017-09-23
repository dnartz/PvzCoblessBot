-- 常规灰烬操作调度器
local Scheduler = {}
local logger = Logger:New("灰烬操作调度", 24)

function Scheduler:New(available)
    local s = {
        -- 目前可供选择的灰烬操作
        available = available,

        -- 之前已经选择的灰烬操作
        selected = {},

        -- 等待线程队列，如果发生available数组为空的情况，就挂起协程。
        -- 一般到这种情况已经歇逼了，但我们可以试一试等到有灰烬操作可用从中弹出并恢复。
        awaitCoroutines = {},

        -- 灰烬释放预期时间戳，用于给樱桃格保护逻辑判断是否需要保护。
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

-- 返回一个剩余冷却时间最短的灰烬操作。
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

-- 选择一个未被其他波次占用，且剩余冷却最短的灰烬操作。
function Scheduler:Acquire()
    -- 如果全部灰烬操作被占用，那基本歇逼了。
    -- 但我们还可以尝试挂起线程，等待被Release唤醒。
    if #self.available == 0 then
        table.insert(self.awaitCoroutines, coroutine.running())
        coroutine.yield()
    end

    local cd, op = self:Select()

    table.remove(self.available, j)
    return cd, op
end

-- 将使用完的灰烬操作放回Available数组，如果有挂起的波次处理线程，那么唤醒它们。
function Scheduler:Release(op)
    table.insert(self.available, op)

    if #self.awaitCoroutines > 0 then
        local head = table.remove(self.awaitCoroutines, 1)
        coroutine.resume(head)
    end
end

-- 判断是否直到在时间戳cs之前，都没有灰烬植物保护1路冰车。
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

-- 樱桃位保护逻辑，如果预期内有灰烬会爆炸，那就跳过保护。
local gLogger = Logger:New("樱桃位保护", 2)
function Scheduler:GridProtect(wave)
    if Plants.Find(function (p)
        return p.type == Plants.Cherry
    end)
    then
        gLogger:Info("樱桃已经被释放，无需保护。")
        return
    end

    if not Zombies.Find(function (z)
        return z.type == Zombies.Zomboni and
               z.spawnedAt == wave and
               z.row == 0
    end)
    then
        gLogger:Info("1路没有第" .. wave .. "波的冰车，7列保护取消。")
        return
    else
        gLogger:Info("1路有第" .. wave .. "波的冰车。")
    end

    if self:HasNoProtectionBefore(Context.gameTime + 500) then
        if IsCardAvailable(Plants.Squash) then
            GrowInstantPlant(Plants.Squash, 0, 6)
        else
            GrowInstantPlant(Plants.SpikeWeed, 0, 6)
        end
    else
        gLogger:Info("已经有灰烬保护1路，7列保护取消。")
    end
end

-- 执行一次灰烬操作，每波开始时作为一个独立协程被调用。
-- 优先让灰烬在刷新后1600时爆炸，否则尽量早地释放灰烬。
function Scheduler:Run(wave, afterSpawn)
    if type(afterSpawn) == 'nil' then
        afterSpawn = 0
    end

    local cd, op = self:Acquire()
    local opImp = op:New()
    table.insert(self.selected, opImp)

    local effectiveAt = math.max(1600 - afterSpawn, cd + op.CastTime)
    local log = "选择的灰烬操作：" ..  op.Name ..
                "，生效时间：刷新后" ..  effectiveAt

    if effectiveAt + afterSpawn > 1600 then
        log = log .. "，需要倭瓜保护1路。"
    end
    logger:Info(log)

    -- 向灰烬生效预期时间数组中增加一个值。
    table.insert(self.expectations, Context.gameTime + effectiveAt)

    -- 如果生效时间超过刷新后16秒，则1路7列可能会被冰车冰道覆盖。
    -- 这会导致7列无法放置樱桃，我们需要放置倭瓜来保护7列的樱桃位。
    Wait(1100 - afterSpawn)
    if effectiveAt + afterSpawn > 1600 then
        self:GridProtect(wave)
    end

    Wait(effectiveAt - 1100 - afterSpawn - op.CastTime)

    -- 如果在释放第9波的灰烬时，之前波次的灰烬还没开始释放，那就取消它们的释放。
    -- 因为这可以为拖延逻辑提供更多的操作选择，并且也不会导致樱桃格被冰道侵占。
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