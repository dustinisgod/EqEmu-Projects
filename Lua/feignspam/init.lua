--feign.lua scribbled by Cannonballdex
local mq = require('mq')

local feign = function ()
    if  mq.TLO.Me.Skill('Feign Death')() < mq.TLO.Me.SkillCap('Feign Death')() then
        mq.cmd('/doability "feign death"')
        mq.delay('1s')
    end
    if mq.TLO.Me.Ability('Feign Death')() then
        mq.cmd.stand()
    end
    if  mq.TLO.Me.Skill('Feign Death')() == mq.TLO.Me.SkillCap('Feign Death')() then
    print('MAXED FEIGN DEATH')
    mq.cmd('/lua stop feign')
    end
end

while true do

    feign()
    mq.delay('1s')
end