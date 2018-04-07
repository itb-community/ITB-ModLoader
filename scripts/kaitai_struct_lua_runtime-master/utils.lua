--
-- Utility functions for KaitaiStruct
--

local utils = {}

local function array_compare(arr, fn)
    if #arr == 0 then
        return nil
    end

    local ret = arr[1]

    for i = 2, #arr do
        if fn(arr[i], ret) then
            ret = arr[i]
        end
    end

    return ret
end

function utils.array_min(arr)
    return array_compare(arr, function(x, y) return x < y end)
end

function utils.array_max(arr)
    return array_compare(arr, function(x, y) return x > y end)
end

return utils
