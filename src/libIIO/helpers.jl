"""
    toString(array)

Returns a `String` from a `Array{UInt8, 1}`. Stops at the first `\0` found if the byte string is null-terminated.
"""
function toString(array::Array{UInt8,1})
    chars = Char.(array);
    stop = findfirst(isequal('\0'), chars);
    return isnothing(stop) ? String(chars) : String(chars[1:stop-1]);
end

"""
    toggleNoAssertions([value])

Toggles the assertions in the libIIO_jl module.

# Arguments
- `value::Bool` : an optional value to set the `NO_ASSERT` toggle to.

# Returns
- `NO_ASSERT::Bool` : the actual value of the `NO_ASSERT` toggle.
"""
function toggleNoAssertions(value = nothing)
    if typeof(value) <: Bool
        global NO_ASSERT = value;
    else
        global NO_ASSERT = !NO_ASSERT;
    end
end
