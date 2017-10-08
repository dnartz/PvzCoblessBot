local common = require('CommonStrategy')
local Track = require('Track')

SelectCard(
    Plants.DoomShroom,
    ImitatePlantType(Plants.DoomShroom),
    Plants.LilyPad,
    Plants.IceShroom,
    Plants.Cherry,
    Plants.Jalapeno,
    Plants.Squash,
    Plants.Pumpkin,
    Plants.FumeShroom,
    Plants.SpikeWeed
)

OnTick(common.FumeFixer)
-- OnTick(common.BalloonTrack)

pumpkinFixList = {}
for row = 0, 5 do
    if row == 2 or row == 3 then
        for col = 4, 5 do
            table.insert(pumpkinFixList, {row, col})
        end
    else
        table.insert(pumpkinFixList, {row, 0})
    end
end
local pf = common.PumpkinFixer:New(pumpkinFixList)
pf:Run()

Track:Run()