function C_iio_device_attr_read(device::Ptr{iio_device}, attr::String)
    buf = zeros(UInt8, BUF_SIZE);
    ret = ccall(
        (:iio_device_attr_read, libIIO),
        Cssize_t, (Ptr{iio_device}, Cstring, Cstring, Csize_t),
        device, attr, Ref(buf), BUF_SIZE
    );
    return ret, String(Char.(buf[1:ret-1]));
end

function C_iio_device_attr_read_all()
    return "PLACEHOLDER"
end

function C_iio_device_attr_read_bool(device::Ptr{iio_device}, attr::String)
    value::UInt8 = 0;
    ret = ccall(
        (:iio_device_attr_read_bool, libIIO),
        Cint, (Ptr{iio_device}, Cstring, Ptr{Cuchar}),
        device, attr, Ref(value)
    );
    return ret, Base.convert(Bool, value);
end

function C_iio_device_attr_read_double(device::Ptr{iio_device}, attr::String)
    value::Float64 = 0;
    ret = ccall(
        (:iio_device_attr_read_double, libIIO),
        Cint, (Ptr{iio_device}, Cstring, Ptr{Cdouble}),
        device, attr, Ref(value)
    );
    return ret, value;
end

function C_iio_device_attr_read_longlong(device::Ptr{iio_device}, attr::String)
    value::Int64 = 0;
    ret = ccall(
        (:iio_device_attr_read_longlong, libIIO),
        Cint, (Ptr{iio_device}, Cstring, Ptr{Clonglong}),
        device, attr, Ref(value)
    );
    return ret, value;
end

function C_iio_device_attr_write(device::Ptr{iio_device}, attr::String, value::String)
    return ccall(
        (:iio_device_attr_write, libIIO),
        Cssize_t, (Ptr{iio_device}, Cstring, Cstring),
        device, attr, value
    );
end

function C_iio_device_attr_write_all()
    return "PLACEHOLDER"
end

function C_iio_device_attr_write_bool(device::Ptr{iio_device}, attr::String, value::Bool)
    return ccall(
        (:iio_device_attr_write_bool, libIIO),
        Cint, (Ptr{iio_device}, Cstring, Cuchar),
        device, attr, value
    );
end

function C_iio_device_attr_write_double(device::Ptr{iio_device}, attr::String, value::Float64)
    return ccall(
        (:iio_device_attr_write_double, libIIO),
        Cint, (Ptr{iio_device}, Cstring, Cdouble),
        device, attr, value
    );
end

function C_iio_device_attr_write_longlong(device::Ptr{iio_device}, attr::String, value::Int64)
    return ccall(
        (:iio_device_attr_write_longlong, libIIO),
        Cint, (Ptr{iio_device}, Cstring, Clonglong),
        device, attr, value
    );
end

# maybe janky casting to Ptr{Cvoid}
function C_iio_device_attr_write_raw(device::Ptr{iio_device}, attr::String, value)
    return ccall(
        (:iio_device_attr_write_raw, libIIO),
        Cssize_t, (Ptr{iio_device}, Cstring, Ptr{Cuchar}, Csize_t),
        device, attr, value, sizeof(value)
    );
end

function C_iio_device_buffer_attr_read(device::Ptr{iio_device}, attr::String)
    buf = zeros(UInt8, BUF_SIZE);
    ret = ccall(
        (:iio_device_buffer_attr_read, libIIO),
        Cssize_t, (Ptr{iio_device}, Cstring, Cstring, Csize_t),
        device, attr, Ref(buf), BUF_SIZE
    );
    return ret, String(Char.(buf[1:ret-1]));
end

function C_iio_device_buffer_attr_read_all()
    return "PLACEHOLDER"
end

function C_iio_device_buffer_attr_read_bool(device::Ptr{iio_device}, attr::String)
    value::UInt8 = 0;
    ret = ccall(
        (:iio_device_buffer_attr_read_bool, libIIO),
        Cint, (Ptr{iio_device}, Cstring, Ptr{Cuchar}),
        device, attr, Ref(value)
    );
    return ret, Base.convert(Bool, value);
end

function C_iio_device_buffer_attr_read_double(device::Ptr{iio_device}, attr::String)
    value::Float64 = 0;
    ret = ccall(
        (:iio_device_buffer_attr_read_double, libIIO),
        Cint, (Ptr{iio_device}, Cstring, Ptr{Cdouble}),
        device, attr, Ref(value)
    );
    return ret, value;
end

function C_iio_device_buffer_attr_read_longlong(device::Ptr{iio_device}, attr::String)
    value::Int64 = 0;
    ret = ccall(
        (:iio_device_buffer_attr_read_longlong, libIIO),
        Cint, (Ptr{iio_device}, Cstring, Ptr{Clonglong}),
        device, attr, Ref(value)
    );
    return ret, value;
end

function C_iio_device_buffer_attr_write(device::Ptr{iio_device}, attr::String, value::String)
    return ccall(
        (:iio_device_buffer_attr_write, libIIO),
        Cssize_t, (Ptr{iio_device}, Cstring, Cstring),
        device, attr, value
    );
end

function C_iio_device_buffer_attr_write_all()
    return "PLACEHOLDER"
end

function C_iio_device_buffer_attr_write_bool(device::Ptr{iio_device}, attr::String, value::Bool)
    return ccall(
        (:iio_device_buffer_attr_write_bool, libIIO),
        Cint, (Ptr{iio_device}, Cstring, Cuchar),
        device, attr, value
    );
end

function C_iio_device_buffer_attr_write_double(device::Ptr{iio_device}, attr::String, value::Float64)
    return ccall(
        (:iio_device_buffer_attr_write_double, libIIO),
        Cint, (Ptr{iio_device}, Cstring, Cdouble),
        device, attr, value
    );
end

function C_iio_device_buffer_attr_write_longlong(device::Ptr{iio_device}, attr::String, value::Int64)
    return ccall(
        (:iio_device_buffer_attr_write_longlong, libIIO),
        Cint, (Ptr{iio_device}, Cstring, Clonglong),
        device, attr, value
    );
end

# maybe janky casting to Ptr{Cvoid}
function C_iio_device_buffer_attr_write_raw(device::Ptr{iio_device}, attr::String, value)
    return ccall(
        (:iio_device_buffer_attr_write_raw, libIIO),
        Cssize_t, (Ptr{iio_device}, Cstring, Ptr{Cuchar}, Csize_t),
        device, attr, value, sizeof(value)
    );
end

function C_iio_device_find_attr(device::Ptr{iio_device}, name::String)
    @assert_Cstring attr = ccall(
        (:iio_device_find_attr, libIIO),
        Cstring, (Ptr{iio_device}, Cstring),
        device, name
    );
    return Base.unsafe_string(attr);
end

function C_iio_device_find_buffer_attr(device::Ptr{iio_device}, name::String)
    @assert_Cstring attr = ccall(
        (:iio_device_find_buffer_attr, libIIO),
        Cstring, (Ptr{iio_device}, Cstring),
        device, name
    );
    return Base.unsafe_string(attr);
end

function C_iio_device_find_channel(device::Ptr{iio_device}, name::String, isOutput::Bool)
    @assert_channel channel = ccall(
        (:iio_device_find_channel, libIIO),
        Ptr{iio_channel}, (Ptr{iio_device}, Cstring, Cuchar),
        device, name, isOutput
    );
    return channel;
end

function C_iio_device_get_attr(device::Ptr{iio_device}, index::UInt32)
    @assert_Cstring attr = ccall(
        (:iio_device_get_attr, libIIO),
        Cstring, (Ptr{iio_device}, Cuint),
        device, index
    );
    return Base.unsafe_string(attr);
end

function C_iio_device_get_attrs_count(device::Ptr{iio_device})
    return ccall(
        (:iio_device_get_attrs_count, libIIO),
        Cuint, (Ptr{iio_device},),
        device
    );
end

function C_iio_device_get_buffer_attr(device::Ptr{iio_device}, index::UInt32)
    @assert_Cstring attr = ccall(
        (:iio_device_get_buffer_attr, libIIO),
        Cstring, (Ptr{iio_device}, Cuint),
        device, index
    );
    return Base.unsafe_string(attr);
end

function C_iio_device_get_buffer_attrs_count(device::Ptr{iio_device})
    return ccall(
        (:iio_device_get_buffer_attrs_count, libIIO),
        Cuint, (Ptr{iio_device},),
        device
    );
end

function C_iio_device_get_channel(device::Ptr{iio_device}, index::UInt32)
    @assert_channel channel = ccall(
        (:iio_device_get_channel, libIIO),
        Ptr{iio_channel}, (Ptr{iio_device}, Cuint),
        device, index
    );
    return channel;
end

function C_iio_device_get_channels_count(device::Ptr{iio_device})
    return ccall(
        (:iio_device_get_channels_count, libIIO),
        Cuint, (Ptr{iio_device},),
        device
    );
end

function C_iio_device_get_context(device::Ptr{iio_device})
    return ccall(
        (:iio_device_get_context, libIIO),
        Ptr{iio_context}, (Ptr{iio_device},),
        device
    );
end

# can return NULL
function C_iio_device_get_data(device::Ptr{iio_device})
    return ccall(
        (:iio_device_get_context, libIIO),
        Ptr{Cuchar}, (Ptr{iio_device},),
        device
    );
end

function C_iio_device_get_id(device::Ptr{iio_device})
    return Base.unsafe_string(ccall(
        (:iio_device_get_id, libIIO),
        Cstring, (Ptr{iio_device},),
        device
    ));
end

# can return NULL
function C_iio_device_get_name(device::Ptr{iio_device})
    return Base.unsafe_string(ccall(
        (:iio_device_get_name, libIIO),
        Cstring, (Ptr{iio_device},),
        device
    ));
end

function C_iio_device_get_trigger(device::Ptr{iio_device})
    trigger = Ptr{iio_device}();
    ret = ccall(
        (:iio_device_get_trigger, libIIO),
        Cint, (Ptr{iio_device}, Ptr{Ptr{iio_device}}),
        device, Ref(trigger)
    );
    return ret, trigger
end

function C_iio_device_is_trigger(device::Ptr{iio_device})
    return Base.convert(Bool, ccall(
        (:iio_device_is_trigger, libIIO),
        Cuchar, (Ptr{iio_device},),
        device
    ));
end

# maybe janky casting to Ptr{Cvoid}
# you probably also need to make sure data lives longer than device
# TODO: check if julia args are refs or copies ?
function C_iio_device_set_data(device::Ptr{iio_device}, data)
    ccall(
        (:iio_device_set_data, libIIO),
        Cvoid, (Ptr{iio_device}, Ptr{Cuchar}),
        device, Ref(data)
    );
end

function C_iio_device_set_kernel_buffers_count(device::Ptr{iio_device}, nb_buffers::UInt32)
    return ccall(
        (:iio_device_set_kernel_buffers_count, libIIO),
        Cint, (Ptr{iio_device}, Cuint),
        device, nb_buffers
    );
end

function C_iio_device_set_trigger(device::Ptr{iio_device}, trigger::Ptr{iio_device})
    return ccall(
        (:iio_device_set_trigger, libIIO),
        Cint, (Ptr{iio_device}, Ptr{iio_device}),
        device, trigger
    );
end
