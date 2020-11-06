function C_iio_channel_attr_get_filename(channel::Ptr{iio_channel}, attr::String)
    @assert_Cstring name = ccall(
        (:iio_channel_attr_get_filename, libIIO),
        Cstring, (Ptr{iio_channel}, Cstring),
        channel, attr
    );
    return name;
end

function C_iio_channel_attr_read(channel::Ptr{iio_channel}, attr::String)
    buf = zeros(UInt8, BUF_SIZE);
    ret = ccall(
        (:iio_channel_attr_read, libIIO),
        Cssize_t, (Ptr{iio_channel}, Cstring, Cstring, Csize_t),
        channel, attr, pointer(buf, 1), BUF_SIZE
    );
    return ret, String(Char.(buf[1:ret-1]));
end

function C_iio_channel_attr_read_all()
    return "PLACEHOLDER"
end

function C_iio_channel_attr_read_bool(channel::Ptr{iio_channel}, attr::String)
    value::UInt8 = 0;
    ret = ccall(
        (:iio_channel_attr_read_bool, libIIO),
        Cint, (Ptr{iio_channel}, Cstring, Ptr{Cuchar}),
        channel, attr, Ref(value)
    );
    return ret, Base.convert(Bool, value);
end

function C_iio_channel_attr_read_double(channel::Ptr{iio_channel}, attr::String)
    value::Float64 = 0;
    ret = ccall(
        (:iio_channel_attr_read_double, libIIO),
        Cint, (Ptr{iio_channel}, Cstring, Ptr{Cdouble}),
        channel, attr, Ref(value)
    );
    return ret, value;
end

function C_iio_channel_attr_read_longlong(channel::Ptr{iio_channel}, attr::String)
    value::Int64 = 0;
    ret = ccall(
        (:iio_channel_attr_read_longlong, libIIO),
        Cint, (Ptr{iio_channel}, Cstring, Ptr{Clonglong}),
        channel, attr, Ref(value)
    );
    return ret, value;
end

function C_iio_channel_attr_write(channel::Ptr{iio_channel}, attr::String, value::String)
    return ccall(
        (:iio_channel_attr_write, libIIO),
        Cssize_t, (Ptr{iio_channel}, Cstring, Cstring),
        channel, attr, value
    );
end

function C_iio_channel_attr_write_all()
    return "PLACEHOLDER"
end

function C_iio_channel_attr_write_bool(channel::Ptr{iio_channel}, attr::String, value::Bool)
    return ccall(
        (:iio_channel_attr_write_bool, libIIO),
        Cint, (Ptr{iio_channel}, Cstring, Cuchar),
        channel, attr, value
    );
end

function C_iio_channel_attr_write_double(channel::Ptr{iio_channel}, attr::String, value::Float64)
    return ccall(
        (:iio_channel_attr_write_double, libIIO),
        Cint, (Ptr{iio_channel}, Cstring, Cdouble),
        channel, attr, value
    );
end

function C_iio_channel_attr_write_longlong(channel::Ptr{iio_channel}, attr::String, value::Int64)
    return ccall(
        (:iio_channel_attr_write_longlong, libIIO),
        Cint, (Ptr{iio_channel}, Cstring, Clonglong),
        channel, attr, value
    );
end

# maybe janky casting to Ptr{Cvoid}
function C_iio_channel_attr_write_raw(channel::Ptr{iio_channel}, attr::String, value)
    return ccall(
        (:iio_channel_attr_write_raw, libIIO),
        Cssize_t, (Ptr{iio_channel}, Cstring, Ptr{Cuchar}, Csize_t),
        channel, attr, value, sizeof(value)
    );
end

function C_iio_channel_disable(channel::Ptr{iio_channel})
    ccall(
        (:iio_channel_disable, libIIO),
        Cvoid, (Ptr{iio_channel},),
        channel
    );
end

function C_iio_channel_enable(channel::Ptr{iio_channel})
    ccall(
        (:iio_channel_enable, libIIO),
        Cvoid, (Ptr{iio_channel},),
        channel
    );
end

function C_iio_channel_find_attr(channel::Ptr{iio_channel}, name::String)
    @assert_Cstring attr = ccall(
        (:iio_channel_find_attr, libIIO),
        Cstring, (Ptr{iio_channel}, Cstring),
        channel, name
    );
    return Base.unsafe_string(attr);
end

function C_iio_channel_get_attr(channel::Ptr{iio_channel}, index::UInt32)
    @assert_Cstring attr = ccall(
        (:iio_channel_get_attr, libIIO),
        Cstring, (Ptr{iio_channel}, Cuint),
        channel, index
    );
    return Base.unsafe_string(attr);
end

function C_iio_channel_get_attrs_count(channel::Ptr{iio_channel})
    return ccall(
        (:iio_channel_get_attrs_count, libIIO),
        Cuint, (Ptr{iio_channel},),
        channel
    );
end

# can return null
function C_iio_channel_get_data(channel::Ptr{iio_channel})
    return ccall(
        (:iio_channel_get_data, libIIO),
        Ptr{Cuchar}, (Ptr{iio_channel},),
        channel
    );
end

function C_iio_channel_get_device(channel::Ptr{iio_channel})
    return ccall(
        (:iio_channel_get_device, libIIO),
        Ptr{iio_device}, (Ptr{iio_channel},),
        channel
    );
end

function C_iio_channel_get_id(channel::Ptr{iio_channel})
    return Base.unsafe_string(ccall(
        (:iio_channel_get_id, libIIO),
        Cstring, (Ptr{iio_channel},),
        channel
    ));
end

# TODO: check return value
function C_iio_channel_get_modifier(channel::Ptr{iio_channel})
    return ccall(
        (:iio_channel_get_modifier, libIIO),
        iio_modifier, (Ptr{iio_channel},),
        channel
    );
end

function C_iio_channel_get_name(channel::Ptr{iio_channel})
    @assert_Cstring name = ccall(
        (:iio_channel_get_name, libIIO),
        Cstring, (Ptr{iio_channel},),
        channel
    );
    return Base.unsafe_string(name);
end

# TODO: check return value
function C_iio_channel_get_type(channel::Ptr{iio_channel})
    return ccall(
        (:iio_channel_get_type, libIIO),
        iio_chan_type, (Ptr{iio_channel},),
        channel
    );
end

function C_iio_channel_is_enabled(channel::Ptr{iio_channel})
    return Base.convert(Bool, ccall(
        (:iio_channel_is_enabled, libIIO),
        Cuchar, (Ptr{iio_channel},),
        channel
    ));
end

function C_iio_channel_is_output(channel::Ptr{iio_channel})
    return Base.convert(Bool, ccall(
        (:iio_channel_is_output, libIIO),
        Cuchar, (Ptr{iio_channel},),
        channel
    ));
end

function C_iio_channel_is_scan_element(channel::Ptr{iio_channel})
    return Base.convert(Bool, ccall(
        (:iio_channel_is_scan_element, libIIO),
        Cuchar, (Ptr{iio_channel},),
        channel
    ));
end

# TODO: find out how the data format works (iio_channel_get_data_format)
# le:s12/16>>4
# means little endian signed, 12bits of data, 16bits sample, shifted to be LSB aligned
function C_iio_channel_read(chn::Ptr{iio_channel}, buf::Ptr{iio_buffer})
    dst = zeros(UInt8, BUF_SIZE);
    nbytes = ccall(
        (:iio_channel_read, libIIO),
        Csize_t, (Ptr{iio_channel}, Ptr{iio_buffer}, Ptr{Cuchar}, Csize_t),
        chn, buf, pointer(dst), BUF_SIZE
    );
    return nbytes, dst;
end

# TODO
function C_iio_channel_read_raw()
    return "PLACEHOLDER"
end

# Ptr{Cvoid} again
# also probably need to make sure data lifetime > channel lifetime
function C_iio_channel_set_data(channel::Ptr{iio_channel}, data)
    ccall(
        (:iio_channel_set_data, libIIO),
        Cvoid, (Ptr{iio_channel}, Ptr{Cuchar}),
        channel, data
    );
end

function C_iio_channel_write()
    return "PLACEHOLDER"
end

function C_iio_channel_write_raw()
    return "PLACEHOLDER"
end
