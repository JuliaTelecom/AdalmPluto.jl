"""
    C_iio_get_backend(index)

Retrieve the name of a given backend.

# Parameters
- `index::UInt32` : The index corresponding to the attribute

# Returns
- On success, a pointer to a static NULL-terminated string
- If the index is invalid, NULL is returned

Introduced in version 0.9.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__TopLevel.html#ga0b950d578c5e4e06232949159c491dab)
"""
function C_iio_get_backend(index::UInt32)
    @assert_Cstring backend = ccall(
        (:iio_get_backend, libIIO),
        Cstring, (Cuint,),
        index
    );
    return Base.unsafe_string(backend);
end

"""
    C_iio_get_backends_count()

Get the number of available backends.

# Returns
- The number of available backends

Introduced in version 0.9.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__TopLevel.html#gabe08d9f1e10801b0334575063a66a56c)
"""
function C_iio_get_backends_count()
    return Base.convert(UInt32, ccall(
        (:iio_get_backends_count, libIIO),
        Cuint, ()
    ));
end

"""
    C_iio_has_backend(backend)

Check if the specified backend is available.

# Parameters
- `backend::String` : The name of the backend to query

# Returns
- True if the backend is available, false otherwise

Introduced in version 0.9.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__TopLevel.html#ga8cf6a3818d471333f4115f3d0d8d95a2)
"""
function C_iio_has_backend(backend::String)
    return Base.convert(Bool, ccall(
        (:iio_has_backend, libIIO),
        Cuchar, (Cstring,),
        backend
    ));
end

"""
    C_iio_library_get_version()

Get the version of the libiio library.

# Returns
- `major::Int` : The major version
- `minor::Int` : The minor version
- `git_tag::String` : The git tag

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__TopLevel.html#gaaa29e5bac86d00a1cef6e2d00b0ea24c)
"""
function C_iio_library_get_version()
    major, minor, git_tag = 0, 0, zeros(UInt8, 8);
    ccall(
        (:iio_library_get_version, libIIO),
        Cvoid, (Ptr{Cuint}, Ptr{Cuint}, Ptr{Cchar}),
        Ref{UInt32}(major), Ref{UInt32}(minor), Ref(git_tag)
    );
    return major, minor, toString(git_tag);
end

"""
    C_iio_strerror(error)

Get a string description of an error code.

# Parameters
- `error::Int` : The error code

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__TopLevel.html#ga4a117b0ac02e97aeda92e33c063f7cf0)
"""
function C_iio_strerror(error::Int)
    buffer = zeros(UInt8, 256);
    ccall(
        (:iio_strerror, libIIO),
        Cvoid, (Cint, Ptr{Cuchar}, Csize_t),
        error, pointer(buffer), length(buffer)
    );
    return toString(buffer);
end
