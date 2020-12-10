"""
    C_iio_context_info_get_description(context)

Get a description of a discovered context.

# Parameters
- `context::Ptr{iio_context_info}`: A pointer to an iio_context_info structure.

# Returns
    A pointer to a static NULL-terminated string

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Scan.html#ga885558697d0e4dad11a4a5b6f5fbc4d6)
"""
function C_iio_context_info_get_description(context::Ptr{iio_context_info})
    return Base.unsafe_string(ccall(
        (:iio_context_info_get_description, libIIO),
        Cstring, (Ptr{iio_context_info},),
        context
    ));
end

"""
    C_iio_context_info_get_uri(context)

Get the URI of a discovered context.

# Parameters
- `context::Ptr{iio_context_info}`: A pointer to an iio_context_info structure.

# Returns
    A pointer to a static NULL-terminated string

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Scan.html#ga6a142a62112a0f84370d22facb2f2a37)
"""
function C_iio_context_info_get_uri(context::Ptr{iio_context_info})
    return Base.unsafe_string(ccall(
        (:iio_context_info_get_uri, libIIO),
        Cstring, (Ptr{iio_context_info},),
        context
    ));
end

"""
    C_iio_context_info_list_free(ptr_context)

Free a context info list.

# Parameters
- `ptr_context::Ptr{Ptr{iio_context_info}}` : A pointer to a 'const struct iio_context_info *' typed variable.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Scan.html#ga4e618c6efb5a62e04a664f53f1b80d99)
"""
function C_iio_context_info_list_free(ptr_context::Ptr{Ptr{iio_context_info}})
    ccall(
        (:iio_context_info_list_free, libIIO),
        Cvoid, (Ptr{Ptr{iio_context_info}},),
        ptr_context
    );
end

"""
    C_iio_create_scan_block(backend, flags)

Create a scan block.

# Parameters
- `backend::String`: A NULL-terminated string containing the backend to use for scanning. If NULL, all the available backends are used.
- `flags::UInt32` : Unused for now. Set to 0.

# Returns
    On success, a pointer to a iio_scan_block structure
    On failure, NULL is returned and errno is set appropriately

Introduced in version 0.20.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Scan.html#gad7fd2ea05bf5a8cebaff26b60edb8a13)
"""
function C_iio_create_scan_block(backend::String, flags::UInt32=UInt32(0))
    @assert_null_pointer scan_block = ccall(
        (:iio_create_scan_block, libIIO),
        Ptr{iio_scan_block}, (Cstring, Cuint),
        backend, flags
    );
    return scan_block;
end

"""
    C_iio_create_scan_context(backend, flags)

Create a scan context.

# Parameters
- `backend::String` : A NULL-terminated string containing the backend(s) to use for scanning (example: pre version 0.20 : "local", "ip", or "usb"; post version 0.20 can handle multiple, including "local:usb:", "ip:usb:", "local:usb:ip:"). If NULL, all the available backends are used.
- `flags::UInt32` : Unused for now. Set to 0.

# Returns
    On success, a pointer to a iio_scan_context structure
    On failure, NULL is returned and errno is set appropriately

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Scan.html#gaa333dd2e410a2769cf5685019185d99c)
"""
function C_iio_create_scan_context(backend::String, flags::UInt32=UInt32(0))
    @assert_null_pointer scan_context = ccall(
        (:iio_create_scan_context, libIIO),
        Ptr{iio_scan_context}, (Cstring, Cuint),
        backend, flags
    );
    return scan_context;
end

"""
    C_iio_scan_block_destroy(scan_block)

Destroy the given scan block.

# Parameters
- `block::Ptr{iio_scan_block}` : A pointer to an iio_scan_block structure

NOTE: After that function, the iio_scan_block pointer shall be invalid.

Introduced in version 0.20.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Scan.html#ga91f6902ca18c491f96627cadb88c5c0a)
"""
function C_iio_scan_block_destroy(scan_block::Ptr{iio_scan_block})
    ccall(
        (:iio_scan_block_destroy, libIIO),
        Cvoid, (Ptr{iio_scan_block},),
        scan_block
    );
end

"""
    C_iio_scan_block_get_info(scan_block, index)

Get the iio_context_info for a particular context.

# Parameters
- `scan_block::Ptr{iio_scan_block}` : A pointer to an iio_scan_block structure
- `index::UInt32` : The index corresponding to the context.

# Returns
    A pointer to the iio_context_info for the context
    On success, a pointer to the specified iio_context_info
    On failure, NULL is returned and errno is set appropriately

Introduced in version 0.20.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Scan.html#ga98c087491e97eb7e25999e3f29263e98)
"""
function C_iio_scan_block_get_info(scan_block::Ptr{iio_scan_block}, index::UInt32)
    @assert_null_pointer context_info = ccall(
        (:iio_scan_block_get_info, libIIO),
        Ptr{iio_context_info}, (Ptr{iio_scan_block}, Cuint),
        scan_block, index
    );
    return context_info;
end

"""
    C_iio_scan_block_scan(scan_block)

Enumerate available contexts via scan block.

# Parameters
- `scan_block::Ptr{iio_scan_block}` : A pointer to a iio_scan_block structure.

# Returns
    On success, the number of contexts found.
    On failure, a negative error number.

Introduced in version 0.20.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Scan.html#gaee7e04572c3b4d202cd0043bb8cee642)
"""
function C_iio_scan_block_scan(scan_block::Ptr{iio_scan_block})
    nb_contexts = ccall(
        (:iio_scan_block_scan, libIIO),
        Cssize_t, (Ptr{iio_scan_block},),
        scan_block
    );
    return Base.convert(Int, nb_contexts);
end

"""
    C_iio_scan_context_destroy(scan_context)

Destroy the given scan context.

# Parameters
- `scan_context::Ptr{iio_scan_context}` : A pointer to an iio_scan_context structure

NOTE: After that function, the iio_scan_context pointer shall be invalid.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Scan.html#ga649d7821636c744753067e8301a84e6d)
"""
function C_iio_scan_context_destroy(scan_context::Ptr{iio_scan_context})
    ccall(
        (:iio_scan_context_destroy, libIIO),
        Cvoid, (Ptr{iio_scan_context},),
        scan_context
    );
end

"""
    C_iio_scan_context_get_info_list(scan_context, context_info)

Enumerate available contexts.

# Parameters
- `scan_context::Ptr{iio_scan_context}` : A pointer to an iio_scan_context structure
- `context_info::Ref{Ptr{Ptr{iio_context_info}}}` : A pointer to a 'const struct iio_context_info **' typed variable. The pointed variable will be initialized on success.

# Returns
    On success, the number of contexts found.
    On failure, a negative error number.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Scan.html#ga5d364d8d008bdbfe5486e6329d06257f)
"""
function C_iio_scan_context_get_info_list(scan_context::Ptr{iio_scan_context}, context_info::Ref{Ptr{Ptr{iio_context_info}}})
    nb_contexts = ccall(
        (:iio_scan_context_get_info_list, libIIO),
        Cssize_t, (Ptr{iio_scan_context}, Ptr{Ptr{Ptr{iio_context_info}}}),
        scan_context, context_info
    );
    return Base.convert(Int, nb_contexts);
end
