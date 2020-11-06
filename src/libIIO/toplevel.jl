function C_iio_get_backend(index::UInt32)
    @assert_Cstring backend = ccall(
        (:iio_get_backend, libIIO),
        Cstring, (Cuint,),
        index
    );
    return Base.unsafe_string(backend);
end

function C_iio_get_backends_count()
    return Base.convert(UInt32, ccall(
        (:iio_get_backends_count, libIIO),
        Cuint, ()
    ));
end

function C_iio_has_backend(backend::String)
    return Base.convert(Bool, ccall(
        (:iio_has_backend, libIIO),
        Cuchar, (Cstring,),
        backend
    ));
end

# TODO: cleaner string conversion ? String(Char.) returns a string with \0 included
function C_iio_library_get_version()
    major, minor, git_tag = 0, 0, zeros(UInt8, 8);
    ccall(
        (:iio_library_get_version, libIIO),
        Cvoid, (Ptr{Cuint}, Ptr{Cuint}, Ptr{Cchar}),
        Ref{UInt32}(major), Ref{UInt32}(minor), Ref(git_tag)
    );
    return major, minor, String(Char.(git_tag));
end

function C_iio_strerror(error::Int)
    buffer = zeros(UInt8, 256);
    ccall(
        (:iio_strerror, libIIO),
        Cvoid, (Cint, Ptr{Cuchar}, Csize_t),
        error, Ref(buffer), length(buffer)
    );
    return toString(buffer);
end
