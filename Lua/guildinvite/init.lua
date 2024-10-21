local mq = require('mq')

function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

if mq.TLO.Plugin("mq2dannet").IsLoaded() == true then
    local arg1 = mq.TLO.DanNet.Peers() 
    local frontDelim = mq.TLO.DanNet.FrontDelim()
    local count = 0 
    if string.find(arg1, "|") then
        for i in arg1:gmatch("|") do
            count = count + 1
          end
        cResult = split(arg1,'|')
    end
    if frontDelim ~= true then
        for i=1, count do
            mq.cmdf("/guildinvite %s", cResult[tonumber(i)])
        end
    else
        for i=2, count+1 do
            mq.cmdf("/guildinvite %s", cResult[tonumber(i)])
        end
    end

else
    print("ERROR: This is to be used with MQ2Dannet and you don't have it loaded.")
end 
