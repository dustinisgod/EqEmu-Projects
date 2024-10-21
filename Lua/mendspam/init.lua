local mq = require('mq')

local mend = function ()
    if  mq.TLO.Me.Skill('Mend')() < mq.TLO.Me.SkillCap('Mend')() then
        mq.cmd('/doability "mend"')
        mq.delay('361s')
    end

    if  mq.TLO.Me.Skill('Mend')() == mq.TLO.Me.SkillCap('Mend')() then
    print('MAXED MEND')
    mq.cmd('/lua stop mend')
    end
end

while true do

    mend()
    mq.delay('1s')
end