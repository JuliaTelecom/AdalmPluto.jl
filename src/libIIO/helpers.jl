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

"""
    iio_decode_blocks(buf, size)

Decodes an array of blocks containing attributes values.
Those come from `iio_[target]_attr_read` functions when C_NULL ("" for the julia wrapper) is passed as the attribute to read.

# Arguments
- `buf::Array{UInt8}` : an array containing the blocks returned by an IIO function.
- `size::Cssize_t`    : the total size of the blocks in the array

# Returns
An array containing :
- `(errno::Int, "")` for attributes that cannot be read as a string, where errno is a negative error number.
- `(size::Int, value::String)` for attributes that can be read. Size is the size of the block and not the actual size of the value.
"""
function iio_decode_blocks(buf::Array{UInt8}, size::Cssize_t)
    bytes_read = 0;
    attrs = Tuple{Int, String}[];
    while bytes_read < size
        block_size = reinterpret(Int32, reverse(buf[(1:4) .+ bytes_read]))[];
        if block_size % 4 != 0
            block_size += 4 - (block_size % 4); # You need to round to the next multiple of 4. Source : read byte per byte the array.
        end
        if block_size < 0
            push!(attrs, (block_size, ""));
            bytes_read += 4;
        else
            push!(attrs, (block_size, toString(buf[(1:block_size-1) .+ (4 + bytes_read)])));
            bytes_read += 4 + block_size;
        end
    end
    return attrs;
end
