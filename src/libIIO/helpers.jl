"""
    toString(array)

Returns a `String` from a `Array{UInt8, 1}`. Stops at the first `\0` found if the byte string is null-terminated.
"""
function toString(array::Array{UInt8,1})
    chars = Char.(array);
    stop = findfirst(isequal('\0'), chars);
    return isnothing(stop) ? String(chars) : String(chars[1:stop-1]);
end
