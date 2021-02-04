"""
    C_iio_channel_attr_get_filename(channel, attr)

Retrieve the filename of an attribute.

# Parameters
- `channel::Ptr{iio_channel}` : A pointer to an iio_channel structure
- `attr::String` : a NULL-terminated string corresponding to the name of the attribute

# Returns
- On success, a NULL-terminated string
- If the attribute name is unknown, NULL is returned. This may throw an error.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Channel.html#gab6462404bb6667e9e9241a18e09a1638)
"""
# TODO : does implicit ccall conversion to Cstring causes errors when NULL is returned?
function C_iio_channel_attr_get_filename(channel::Ptr{iio_channel}, attr::String)
    @assert_Cstring name = ccall(
        (:iio_channel_attr_get_filename, libIIO),
        Cstring, (Ptr{iio_channel}, Cstring),
        channel, attr
    );
    return name;
end

"""
    C_iio_channel_attr_read(channel, attr)

Read the content of the given channel-specific attribute.

# Parameters
- `channel::Ptr{iio_channel}` : A pointer to an iio_channel structure
- `attr::String` : a NULL-terminated string corresponding to the name of the attribute

# Returns
- On success, `(nbytes, value::String)` where nbytes is the length of the value string.
- On error, `(errno, "")` is returned, where errno is a negative error code.

# NOTE
By passing NULL as the "attr" argument to `iio_channel_attr_read`, it is now possible to read all of the attributes of a channel.

The buffer is filled with one block of data per attribute of the channel, by the order they appear in the iio_channel structure.

The first four bytes of one block correspond to a 32-bit signed value in network order.
If negative, it corresponds to the errno code that were returned when reading the attribute;
if positive, it corresponds to the length of the data read. In that case, the rest of the block contains the data.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Channel.html#ga2c2ca5696d1341067051eb390d5014ae)
"""
function C_iio_channel_attr_read(channel::Ptr{iio_channel}, attr::String)
    buf = zeros(UInt8, BUF_SIZE);
    ret = ccall(
        (:iio_channel_attr_read, libIIO),
        Cssize_t, (Ptr{iio_channel}, Cstring, Cstring, Csize_t),
        channel, attr, pointer(buf, 1), BUF_SIZE
    );
    return ret, String(Char.(buf[1:ret-1]));
end

"""
    C_iio_channel_attr_read_all()

THIS IS A PLACEHOLDER. THE DOCUMENTATION BELOW IS ONLY A COPY/PASTE OF THE C DOCUMENTATION.

Read the content of all channel-specific attributes.

# Parameters
- chn : A pointer to an iio_channel structure
- cb : A pointer to a callback function
- data : A pointer that will be passed to the callback function

# Returns
- On success, 0 is returned
- On error, a negative errno code is returned

# NOTE
This function is especially useful when used with the network backend, as all the channel-specific attributes are read in one single command.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Channel.html#gab9c28b0cd94c0607bcc7cac16219eb48)
"""
function C_iio_channel_attr_read_all()
    return "PLACEHOLDER"
end

"""
    C_iio_channel_attr_read_bool(channel, attr)

Read the content of the given channel-specific attribute.

# Parameters
- `channel::Ptr{iio_channel}` : A pointer to an iio_channel structure
- `attr::String` : a NULL-terminated string corresponding to the name of the attribute

# Returns
- On success, `(0, value::Bool)` is returned
- On error, `(errno, false)` is returned, where errno is a negative error code. The second value should be discarded.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Channel.html#ga319f39c313bbd4d331e23df51e4d3ce6)
"""
function C_iio_channel_attr_read_bool(channel::Ptr{iio_channel}, attr::String)
    value::UInt8 = 0;
    ret = ccall(
        (:iio_channel_attr_read_bool, libIIO),
        Cint, (Ptr{iio_channel}, Cstring, Ptr{Cuchar}),
        channel, attr, Ref(value)
    );
    return ret, Base.convert(Bool, value);
end

"""
    C_iio_channel_attr_read_double(channel, attr)

Read the content of the given channel-specific attribute.

# Parameters
- `channel::Ptr{iio_channel}` : A pointer to an iio_channel structure
- `attr::String` : a NULL-terminated string corresponding to the name of the attribute

# Returns
- On success, `(0, value::Float64)` is returned
- On error, `(errno, 0)` is returned, where errno is a negative error code. The second value should be discarded.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Channel.html#ga75ac9b81eb7e7e8a961afb67748e4102)
"""
function C_iio_channel_attr_read_double(channel::Ptr{iio_channel}, attr::String)
    value::Float64 = 0;
    ret = ccall(
        (:iio_channel_attr_read_double, libIIO),
        Cint, (Ptr{iio_channel}, Cstring, Ptr{Cdouble}),
        channel, attr, Ref(value)
    );
    return ret, value;
end

"""
    C_iio_channel_attr_read_longlong(channel, attr)

Read the content of the given channel-specific attribute.

# Parameters
- `channel::Ptr{iio_channel}` : A pointer to an iio_channel structure
- `attr::String` : a NULL-terminated string corresponding to the name of the attribute

# Returns
- On success, `(0, value::Int64)` is returned
- On error, `(errno, 0)` is returned, where errno is a negative error code. The second value should be discarded.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Channel.html#ga116c61892bf3d20ff07efd642c5dfbe1)
"""
function C_iio_channel_attr_read_longlong(channel::Ptr{iio_channel}, attr::String)
    value::Int64 = 0;
    ret = ccall(
        (:iio_channel_attr_read_longlong, libIIO),
        Cint, (Ptr{iio_channel}, Cstring, Ptr{Clonglong}),
        channel, attr, Ref(value)
    );
    return ret, value;
end

"""
    C_iio_channel_attr_write(channel, attr, value)

Set the value of the given channel-specific attribute.

# Parameters
- `channel::Ptr{iio_channel}` : A pointer to an iio_channel structure
- `attr::String` : a NULL-terminated string corresponding to the name of the attribute
- `value::String` : A NULL-terminated string to set the attribute to

# Returns
- On success, the number of bytes written
- On error, a negative errno code is returned

# NOTE
By passing NULL as the "attr" argument to `iio_channel_attr_write`, it is now possible to write all of the attributes of a channel.

The buffer must contain one block of data per attribute of the channel, by the order they appear in the iio_channel structure.

The first four bytes of one block correspond to a 32-bit signed value in network order.
If negative, the attribute is not written;
if positive, it corresponds to the length of the data to write.
In that case, the rest of the block must contain the data.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Channel.html#ga35c76ce5fcae4c551b7c78d648665a41)
"""
function C_iio_channel_attr_write(channel::Ptr{iio_channel}, attr::String, value::String)
    return ccall(
        (:iio_channel_attr_write, libIIO),
        Cssize_t, (Ptr{iio_channel}, Cstring, Cstring),
        channel, attr, value
    );
end

"""
    C_iio_channel_attr_write_all()

THIS IS A PLACEHOLDER. THE DOCUMENTATION BELOW IS ONLY A COPY/PASTE OF THE C DOCUMENTATION.

Set the values of all channel-specific attributes.

# Parameters
- chn : A pointer to an iio_channel structure
- cb : A pointer to a callback function
- data : A pointer that will be passed to the callback function

# Returns
- On success, 0 is returned
- On error, a negative errno code is returned

# NOTE
This function is especially useful when used with the network backend, as all the channel-specific attributes are written in one single command.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Channel.html#ga6df693ee4f0c329d957f7c7ca3588f3f)
"""
function C_iio_channel_attr_write_all()
    return "PLACEHOLDER"
end

"""
    C_iio_channel_attr_write_bool(channel, attr, value)

Set the value of the given channel-specific attribute.

# Parameters
- `channel::Ptr{iio_channel}` : A pointer to an iio_channel structure
- `attr::String` : a NULL-terminated string corresponding to the name of the attribute
- `value::Bool` : A bool value to set the attribute to

# Returns
- On success, the number of bytes written
- On error, a negative errno code is returned

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Channel.html#ga9a385b9b05d20f33f8e587feb2ebe81a)
"""
function C_iio_channel_attr_write_bool(channel::Ptr{iio_channel}, attr::String, value::Bool)
    return ccall(
        (:iio_channel_attr_write_bool, libIIO),
        Cint, (Ptr{iio_channel}, Cstring, Cuchar),
        channel, attr, value
    );
end

"""
    C_iio_channel_attr_write_double(channel, attr, value)

Set the value of the given channel-specific attribute.

# Parameters
- `channel::Ptr{iio_channel}` : A pointer to an iio_channel structure
- `attr::String` : a NULL-terminated string corresponding to the name of the attribute
- `value::Float64` : A double value to set the attribute to

# Returns
- On success, the number of bytes written
- On error, a negative errno code is returned

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Channel.html#gad9d6ec4a02948c6416cc99254bdbfa50)
"""
function C_iio_channel_attr_write_double(channel::Ptr{iio_channel}, attr::String, value::Float64)
    return ccall(
        (:iio_channel_attr_write_double, libIIO),
        Cint, (Ptr{iio_channel}, Cstring, Cdouble),
        channel, attr, value
    );
end

"""
    C_iio_channel_attr_write_longlong(channel, attr, value)

Set the value of the given channel-specific attribute.

# Parameters
- `channel::Ptr{iio_channel}` : A pointer to an iio_channel structure
- `attr::String` : a NULL-terminated string corresponding to the name of the attribute
- `value::Int64` : A long long value to set the attribute to

# Returns
- On success, the number of bytes written
- On error, a negative errno code is returned

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Channel.html#gac55cb77a1baf797e54a8a4e31b2f4680)
"""
function C_iio_channel_attr_write_longlong(channel::Ptr{iio_channel}, attr::String, value::Int64)
    return ccall(
        (:iio_channel_attr_write_longlong, libIIO),
        Cint, (Ptr{iio_channel}, Cstring, Clonglong),
        channel, attr, value
    );
end

"""
    C_iio_channel_attr_write_raw(channel, attr, value)

Set the value of the given channel-specific attribute.

# Parameters
- `channel::Ptr{iio_channel}` : A pointer to an iio_channel structure
- `attr::String` : a NULL-terminated string corresponding to the name of the attribute
- `value` : A pointer to the data to be written. Must be castable to Ptr{Cuchar}.

# Returns
- On success, the number of bytes written
- On error, a negative errno code is returned

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Channel.html#gacd0d3dd36bdc64a9f967e21a891230eb)
"""
# maybe janky casting to Ptr{Cvoid}
function C_iio_channel_attr_write_raw(channel::Ptr{iio_channel}, attr::String, value)
    return ccall(
        (:iio_channel_attr_write_raw, libIIO),
        Cssize_t, (Ptr{iio_channel}, Cstring, Ptr{Cuchar}, Csize_t),
        channel, attr, value, sizeof(value)
    );
end

"""
    C_iio_channel_disable(channel)

Disable the given channel.

# Parameters
- `channel::Ptr{iio_channel}` : A pointer to an iio_channel structure

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Channel.html#gad7c7c91c61b8a97187dc73cbcdb60c06)
"""
function C_iio_channel_disable(channel::Ptr{iio_channel})
    ccall(
        (:iio_channel_disable, libIIO),
        Cvoid, (Ptr{iio_channel},),
        channel
    );
end

"""
    C_iio_channel_enable(channel)

Enable the given channel.

# Parameters
- `channel::Ptr{iio_channel}` : A pointer to an iio_channel structure

# NOTE
Before creating an iio_buffer structure with `iio_device_create_buffer`, it is required to enable at least one channel of the device to read from.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Channel.html#ga2b787983683d37966b5e1e5c6c121d6a)
"""
function C_iio_channel_enable(channel::Ptr{iio_channel})
    ccall(
        (:iio_channel_enable, libIIO),
        Cvoid, (Ptr{iio_channel},),
        channel
    );
end

"""
    C_iio_channel_find_attr(channel, name)

Try to find a channel-specific attribute by its name.

# Parameters
- `channel::Ptr{iio_channel}` : A pointer to an iio_channel structure
- `name::String` : A NULL-terminated string corresponding to the name of the attribute

# Returns
- On success, a NULL-terminated string.
- On failure, if the assertions are enabled, throws an error.
- On failure, if the assertions are disabled, also throws an error :D

# NOTE
This function is useful to detect the presence of an attribute. It can also be used to retrieve the name of an attribute as a pointer to a static string from a dynamically allocated string.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Channel.html#ga13b2db3252a2380a2b0b1bb15b8034a4)
"""
# TODO: fix unsafe_string
function C_iio_channel_find_attr(channel::Ptr{iio_channel}, name::String)
    @assert_Cstring attr = ccall(
        (:iio_channel_find_attr, libIIO),
        Cstring, (Ptr{iio_channel}, Cstring),
        channel, name
    );
    return Base.unsafe_string(attr);
end

"""
    C_iio_channel_get_attr(channel, index)

Get the channel-specific attribute present at the given index.

# Parameters
- `channel::Ptr{iio_channel}` : A pointer to an iio_channel structure
- `index::UInt32` : The index corresponding to the attribute

# Returns
- On success, a NULL-terminated string.
- On failure, if the assertions are enabled, throws an error.
- On failure, if the assertions are disabled, also throws an error :D

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Channel.html#gafc3c52f360424c097a24d1925923d772)
"""
function C_iio_channel_get_attr(channel::Ptr{iio_channel}, index::UInt32)
    @assert_Cstring attr = ccall(
        (:iio_channel_get_attr, libIIO),
        Cstring, (Ptr{iio_channel}, Cuint),
        channel, index
    );
    return Base.unsafe_string(attr);
end

"""
    C_iio_channel_get_attrs_count(channel)

Enumerate the channel-specific attributes of the given channel.

# Parameters
- `channel::Ptr{iio_channel}` : A pointer to an iio_channel structure

# Returns
- The number of channel-specific attributes found

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Channel.html#ga14869c3fda8b04f413a02f15dfa6ef7c)
"""
function C_iio_channel_get_attrs_count(channel::Ptr{iio_channel})
    return ccall(
        (:iio_channel_get_attrs_count, libIIO),
        Cuint, (Ptr{iio_channel},),
        channel
    );
end

"""
    C_iio_channel_get_data(channel)

Retrieve a previously associated pointer of an iio_channel structure.

# Parameters
- `channel::Ptr{iio_channel}` : A pointer to an iio_channel structure

# Returns
- The pointer previously associated if present, or NULL

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Channel.html#gacbce92eaefb8d61c1e4f0dc042b211e6)
"""
# can return null
function C_iio_channel_get_data(channel::Ptr{iio_channel})
    return ccall(
        (:iio_channel_get_data, libIIO),
        Ptr{Cuchar}, (Ptr{iio_channel},),
        channel
    );
end

"""
    C_iio_channel_get_device(channel)

Retrieve a pointer to the iio_device structure.

# Parameters
- `channel::Ptr{iio_channel}` : A pointer to an iio_channel structure

# Returns
- A pointer to an iio_device structure

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Channel.html#gaf2800d7a6953c5dd3271df390c062439)
"""
function C_iio_channel_get_device(channel::Ptr{iio_channel})
    return ccall(
        (:iio_channel_get_device, libIIO),
        Ptr{iio_device}, (Ptr{iio_channel},),
        channel
    );
end

"""
    C_iio_channel_get_id(channel)

Retrieve the channel ID (e.g. voltage0)

# Parameters
- `channel::Ptr{iio_channel}` : A pointer to an iio_channel structure

# Returns
- A NULL-terminated string

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Channel.html#gafda1782de4655905ad08a40492f3dc64)
"""
function C_iio_channel_get_id(channel::Ptr{iio_channel})
    return Base.unsafe_string(ccall(
        (:iio_channel_get_id, libIIO),
        Cstring, (Ptr{iio_channel},),
        channel
    ));
end

"""
    C_iio_channel_get_modifier(channel)

Get the modifier type of the given channel.

# Parameters
- `channel::Ptr{iio_channel}` : A pointer to an iio_channel structure

# Returns
- The modifier type of the channel

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Channel.html#ga4c3179cee86d8992ee6c6bdbcaa44156)
"""
# TODO: check return value
function C_iio_channel_get_modifier(channel::Ptr{iio_channel})
    return ccall(
        (:iio_channel_get_modifier, libIIO),
        iio_modifier, (Ptr{iio_channel},),
        channel
    );
end

"""
    C_iio_channel_get_name(channel)

Retrieve the channel name (e.g. vccint)

# Parameters
- `channel::Ptr{iio_channel}` : A pointer to an iio_channel structure

# Returns
- A NULL-terminated string

# NOTE
If the channel has no name, NULL is returned. (Throws an error atm)

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Channel.html#ga37346a6f3fcfb1eb40572aec6c3b39ac)
"""
function C_iio_channel_get_name(channel::Ptr{iio_channel})
    @assert_Cstring name = ccall(
        (:iio_channel_get_name, libIIO),
        Cstring, (Ptr{iio_channel},),
        channel
    );
    return Base.unsafe_string(name);
end

"""
    C_iio_channel_get_type(channel)

Get the type of the given channel.

# Parameters
- `channel::Ptr{iio_channel}` : A pointer to an iio_channel structure

# Returns
- The type of the channel

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Channel.html#ga281660051fb40b5b4055227466a3be36)
"""
# TODO: check return value
function C_iio_channel_get_type(channel::Ptr{iio_channel})
    return ccall(
        (:iio_channel_get_type, libIIO),
        iio_chan_type, (Ptr{iio_channel},),
        channel
    );
end

"""
    C_iio_channel_is_enabled(channel)

# Parameters
- `channel::Ptr{iio_channel}` : A pointer to an iio_channel structure

# Returns
- True if the channel is enabled, False otherwise

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Channel.html#gaf10427dc35adaa0991cd34a9dd45a82f)
"""
function C_iio_channel_is_enabled(channel::Ptr{iio_channel})
    return Base.convert(Bool, ccall(
        (:iio_channel_is_enabled, libIIO),
        Cuchar, (Ptr{iio_channel},),
        channel
    ));
end

"""
    C_iio_channel_is_output(channel)

Return True if the given channel is an output channel.

# Parameters
- `channel::Ptr{iio_channel}` : A pointer to an iio_channel structure

# Returns
- True if the channel is an output channel, False otherwise

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Channel.html#ga3c24e9c93e2217c9506073d04b878461)
"""
function C_iio_channel_is_output(channel::Ptr{iio_channel})
    return Base.convert(Bool, ccall(
        (:iio_channel_is_output, libIIO),
        Cuchar, (Ptr{iio_channel},),
        channel
    ));
end

"""
    C_iio_channel_is_scan_element(channel)

Return True if the given channel is a scan element.

# Parameters
- `channel::Ptr{iio_channel}` : A pointer to an iio_channel structure

# Returns
- True if the channel is a scan element, False otherwise

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Channel.html#ga07892a3c0c31e7a3eecf76ec72a8669d)
"""
function C_iio_channel_is_scan_element(channel::Ptr{iio_channel})
    return Base.convert(Bool, ccall(
        (:iio_channel_is_scan_element, libIIO),
        Cuchar, (Ptr{iio_channel},),
        channel
    ));
end

"""
    C_iio_channel_read(chn, buf)

Demultiplex and convert the samples of a given channel.

# Parameters
- `chn::Ptr{iio_channel}` : A pointer to an iio_channel structure
- `buf::Ptr{iio_buffer}` : A pointer to an iio_buffer structure

# Returns
- `(nbytes, dst::Array{UInt8})` where nbytes is the number of bytes written to dst.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Channel.html#ga5c01edc37b0b57aef503abd5989a6a30)
"""
# TODO: fix buffer size (or remove the function altogether as it make more sense to preallocate the buffer)
# le:s12/16>>4
# means little endian signed, 12bits of data, 16bits sample, shifted to be LSB aligned
function C_iio_channel_read(chn::Ptr{iio_channel}, buf::Ptr{iio_buffer})
    dst = zeros(UInt8, BUF_SIZE);
    nbytes = C_iio_channel_read!(chn, buf, dst);
    return nbytes, dst;
end

"""
    C_iio_channel_read!(chn, buf, dst)

Demultiplex and convert the samples of a given channel.

# Parameters
- `chn::Ptr{iio_channel}` : A pointer to an iio_channel structure
- `buf::Ptr{iio_buffer}` : A pointer to an iio_buffer structure
- `dst::Array{UInt8}` : An array where the converted data will be stored

# Returns
- The size of the converted data written is dst, in bytes

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Channel.html#ga5c01edc37b0b57aef503abd5989a6a30)
"""
function C_iio_channel_read!(chn::Ptr{iio_channel}, buf::Ptr{iio_buffer}, dst::Array{UInt8})
    nbytes = ccall(
        (:iio_channel_read, libIIO),
        Csize_t, (Ptr{iio_channel}, Ptr{iio_buffer}, Ptr{Cuchar}, Csize_t),
        chn, buf, pointer(dst), length(dst)
    );
    return nbytes;
end

"""
    C_iio_channel_read_raw()

THIS IS A PLACEHOLDER. THE DOCUMENTATION BELOW IS ONLY A COPY/PASTE OF THE C DOCUMENTATION.

Demultiplex the samples of a given channel.

# Parameters
- chn : A pointer to an iio_channel structure
- buffer : A pointer to an iio_buffer structure
- dst : A pointer to the memory area where the demultiplexed data will be stored
- len : The available length of the memory area, in bytes

# Returns
- The size of the demultiplexed data, in bytes

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Channel.html#gacd227a6861960ea2fb49d957f62887dd)
"""
# TODO
function C_iio_channel_read_raw()
    return "PLACEHOLDER"
end

"""
    C_iio_channel_set_data(channel, data)

Associate a pointer to an iio_channel structure.

# Parameters
- `channel::Ptr{iio_channel}` : A pointer to an iio_channel structure
- `data` : The pointer to be associated. Must be castabel to `Ptr{Cuchar}`.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Channel.html#ga5150c9b73386d899460ebafbe614f338)
"""
# Ptr{Cvoid} again
# also probably need to make sure data lifetime > channel lifetime
function C_iio_channel_set_data(channel::Ptr{iio_channel}, data)
    ccall(
        (:iio_channel_set_data, libIIO),
        Cvoid, (Ptr{iio_channel}, Ptr{Cuchar}),
        channel, data
    );
end

"""
    C_iio_channel_write()

THIS IS A PLACEHOLDER. THE DOCUMENTATION BELOW IS ONLY A COPY/PASTE OF THE C DOCUMENTATION.

Convert and multiplex the samples of a given channel.

# Parameters
- chn : A pointer to an iio_channel structure
- buffer : A pointer to an iio_buffer structure
- src : A pointer to the memory area where the sequential data will be read from
- len : The length of the memory area, in bytes

# Returns
- The number of bytes actually converted and multiplexed

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Channel.html#ga52c5a5cc138969b32f78db9669a4ffd2)
"""
function C_iio_channel_write()
    return "PLACEHOLDER"
end

"""
    C_iio_channel_write_raw()

THIS IS A PLACEHOLDER. THE DOCUMENTATION BELOW IS ONLY A COPY/PASTE OF THE C DOCUMENTATION.

Multiplex the samples of a given channel.

# Parameters
- chn : A pointer to an iio_channel structure
- buffer : A pointer to an iio_buffer structure
- src : A pointer to the memory area where the sequential data will be read from
- len : The length of the memory area, in bytes

# Returns
- The number of bytes actually multiplexed

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Channel.html#ga350e81855764c159c6aefa12fb78e1c2)
"""
function C_iio_channel_write_raw()
    return "PLACEHOLDER"
end
