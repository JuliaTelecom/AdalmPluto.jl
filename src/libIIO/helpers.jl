# convert null terminated C string to julia string
function toString(array::Array{UInt8,1})
    chars = Char.(array);
    stop = findfirst(isequal('\0'), chars);
    return isnothing(stop) ? String(chars) : String(chars[1:stop-1]);
end
