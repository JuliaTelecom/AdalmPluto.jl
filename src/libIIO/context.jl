function C_iio_context_clone(context::Ptr{iio_context})
    @assert_context clone = ccall(
        (:iio_context_clone, libIIO),
        Ptr{iio_context}, (Ptr{iio_context},),
        context
    );
    return clone;
end

function C_iio_context_destroy(context::Ptr{iio_context})
    ccall(
        (:iio_context_destroy, libIIO),
        Cvoid, (Ptr{iio_context},),
        context
    );
end

function C_iio_context_find_device(context::Ptr{iio_context}, name::String)
    @assert_device device = ccall(
        (:iio_context_find_device, libIIO),
        Ptr{iio_device}, (Ptr{iio_context}, Cstring),
        context, name
    );
    return device;
end

# TODO: TEST
function C_iio_context_get_attr(context::Ptr{iio_context}, index::UInt32)
    name, value = Ref{Cstring}(), Ref{Cstring}();
    ret = ccall(
        (:iio_context_get_attr, libIIO),
        Cint, (Ptr{iio_context}, Cuint, Ptr{Cstring}, Ptr{Cstring}),
        context, index, name, value
    );
    return (ret == 0) ? (ret, Base.unsafe_string(name[]), Base.unsafe_string(value[])) : (ret, "", "");
end

function C_iio_context_get_attr_value(context::Ptr{iio_context}, name::String)
    @assert_Cstring value = ccall(
        (:iio_context_get_attr_value, libIIO),
        Cstring, (Ptr{iio_context}, Cstring),
        context, name
    );
    return Base.unsafe_string(value);
end

function C_iio_context_get_attrs_count(context::Ptr{iio_context})
    return ccall(
        (:iio_context_get_attrs_count, libIIO),
        Cuint, (Ptr{iio_context},),
        context
    );
end

function C_iio_context_get_description(context::Ptr{iio_context})
    return Base.unsafe_string(ccall(
        (:iio_context_get_description, libIIO),
        Cstring, (Ptr{iio_context},),
        context
    ));
end

function C_iio_context_get_device(context::Ptr{iio_context}, index::UInt32)
    @assert_device device = ccall(
        (:iio_context_get_device, libIIO),
        Ptr{iio_device}, (Ptr{iio_context}, Cuint),
        context, index
    );
    return device;
end

function C_iio_context_get_devices_count(context::Ptr{iio_context})
    return ccall(
        (:iio_context_get_devices_count, libIIO),
        Cuint, (Ptr{iio_context},),
        context
    );
end

function C_iio_context_get_name(context::Ptr{iio_context})
    return Base.unsafe_string(ccall(
        (:iio_context_get_name, libIIO),
        Cstring, (Ptr{iio_context},),
        context
    ));
end

# TODO: TEST
function C_iio_context_get_version(context::Ptr{iio_context})
    major, minor, git_tag = 0, 0, zeros(UInt8, 8);
    ret = ccall(
        (:iio_context_get_version, libIIO),
        Cint, (Ptr{iio_context}, Ptr{Cuint}, Ptr{Cuint}, Ptr{Cchar}),
        context, Ref{UInt32}(major), Ref{UInt32}(minor), Ref(git_tag)
    );
    return ret, major, minor, String(Char.(git_tag));
end

function C_iio_context_get_xml(context::Ptr{iio_context})
    return Base.unsafe_string(ccall(
        (:iio_context_get_xml, libIIO),
        Cstring, (Ptr{iio_context},),
        context
    ));
end

function C_iio_context_set_timeout(context::Ptr{iio_context}, timeout_ms::UInt32)
    return ccall(
        (:iio_context_set_timeout, libIIO),
        Cint, (Ptr{iio_context}, Cuint),
        context, timeout_ms
    );
end

function C_iio_create_context_from_uri(uri::String)
    @assert_context context = ccall(
        (:iio_create_context_from_uri, libIIO),
        Ptr{iio_context}, (Cstring,),
        uri
    );
    return context;
end

function C_iio_create_default_context()
    @assert_context context = ccall(
        (:iio_create_default_context, libIIO),
        Ptr{iio_context}, ()
    );
    return context;
end

function C_iio_create_local_context()
    @assert_context context = ccall(
        (:iio_create_local_context, libIIO),
        Ptr{iio_context}, ()
    );
    return context;
end

function C_iio_create_network_context(host::String)
    @assert_context context = ccall(
        (:iio_create_network_context, libIIO),
        Ptr{iio_context}, (Cstring,),
        host
    );
    return context;
end

function C_iio_create_xml_context(xml_file::String)
    @assert_context context = ccall(
        (:iio_create_xml_context, libIIO),
        Ptr{iio_context}, (Cstring,),
        xml_file
    );
    return context;
end

function C_iio_create_xml_context_mem(xml::String, length::UInt)
    @assert_context context = ccall(
        (:iio_create_xml_context_mem, libIIO),
        Ptr{iio_context}, (Cstring, Csize_t),
        xml, length
    );
end
