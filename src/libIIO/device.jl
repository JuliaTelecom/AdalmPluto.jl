"""
    C_iio_device_attr_read(device, attr)

Read the content of the given device-specific attribute.

# Parameters
- `device::Ptr{iio_device}` : A pointer to an iio_device structure
- `attr::String`            : A NULL-terminated string corresponding to the name of the attribute. Passing an empty string reads all the attributes.

# Returns
- On success, the number of bytes written to the buffer and the attribute value as a `String`.
- On error, a negative errno code is returned along an empty `String`.
- If all the attributes are being read, an array of the values above is returned.
The string may be shorter than the number of bytes returned as the conversion trims excess null characters.

# NOTE
By passing NULL (replaced by an empty string in the Julia wrapper) as the "attr" argument to iio_device_attr_read, it is now possible to read all of the attributes of a device.

The buffer is filled with one block of data per attribute of the device, by the order they appear in the iio_device structure.

The first four bytes of one block correspond to a 32-bit signed value in network order.
If negative, it corresponds to the errno code that were returned when reading the attribute;
if positive, it corresponds to the length of the data read. In that case, the rest of the block contains the data.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#gaf0233eb0ef4a64ad70ebaef6328b0494)
"""
function C_iio_device_attr_read(device::Ptr{iio_device}, attr::String)
    if attr == ""; attr = C_NULL; end; # allows to read all the attributes
    buf = zeros(UInt8, BUF_SIZE);
    ret = ccall(
        (:iio_device_attr_read, libIIO),
        Cssize_t, (Ptr{iio_device}, Cstring, Cstring, Csize_t),
        device, attr, pointer(buf), BUF_SIZE
    );
    attr == C_NULL ? attrs = iio_decode_blocks(buf, ret) : attrs = toString(buf);
    return ret, attrs;
end

"""
    C_iio_device_attr_read_all()

THIS IS A PLACEHOLDER. THE DOCUMENTATION BELOW IS ONLY A COPY/PASTE OF THE C DOCUMENTATION.

Read the content of all device-specific attributes.

# Parameters
- dev : A pointer to an iio_device structure
- cb : A pointer to a callback function
- data : A pointer that will be passed to the callback function

# Returns
- On success, 0 is returned
- On error, a negative errno code is returned

# NOTE
This function is especially useful when used with the network backend, as all the device-specific attributes are read in one single command.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#ga5b1fef1333c4835942384b661f148b36)
"""
function C_iio_device_attr_read_all()
    return "PLACEHOLDER"
end

"""
    C_iio_device_attr_read_bool(device, attr)

Read the content of the given device-specific attribute.

# Parameters
- `device::Ptr{iio_device}` : A pointer to an iio_device structure
- `attr::String`            : A NULL-terminated string corresponding to the name of the attribute

# Returns
- On success, `(0, value::Bool)` is returned.
- On error, `(errno, value::Bool)` is returned, where errno is a negative error code. `value` should be discarded.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#ga96364b7c7097bb8e4656924ea896a502)
"""
function C_iio_device_attr_read_bool(device::Ptr{iio_device}, attr::String)
    value = Ref{UInt8}(0);
    ret = ccall(
        (:iio_device_attr_read_bool, libIIO),
        Cint, (Ptr{iio_device}, Cstring, Ptr{Cuchar}),
        device, attr, value
    );
    return ret, Base.convert(Bool, value[]);
end

"""
    C_iio_device_attr_read_double(device, attr)

Read the content of the given device-specific attribute.

# Parameters
- `device::Ptr{iio_device}` : A pointer to an iio_device structure
- `attr::String`            : A NULL-terminated string corresponding to the name of the attribute

# Returns
- On success, `(0, value::Float64)` is returned.
- On error, `(errno, value::Float64)` is returned, where errno is a negative error code. `value` should be discarded.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#gab1b150a5bfa7b1ab7fd76c538e15e4da)
"""
function C_iio_device_attr_read_double(device::Ptr{iio_device}, attr::String)
    value = Ref{Float64}(0);
    ret = ccall(
        (:iio_device_attr_read_double, libIIO),
        Cint, (Ptr{iio_device}, Cstring, Ptr{Cdouble}),
        device, attr, value
    );
    return ret, value[];
end

"""
    C_iio_device_attr_read_longlong(device, attr)

Read the content of the given device-specific attribute.

# Parameters
- `device::Ptr{iio_device}` : A pointer to an iio_device structure
- `attr::String`            : A NULL-terminated string corresponding to the name of the attribute

# Returns
- On success, `(0, value::Int64)` is returned.
- On error, `(errno, value::Int64)` is returned, where errno is a negative error code. `value` should be discarded.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#ga0f7b5d21a4e40efac68e1ece44d7ba74)
"""
function C_iio_device_attr_read_longlong(device::Ptr{iio_device}, attr::String)
    value = Ref{Int64}(0);
    ret = ccall(
        (:iio_device_attr_read_longlong, libIIO),
        Cint, (Ptr{iio_device}, Cstring, Ptr{Clonglong}),
        device, attr, value
    );
    return ret, value[];
end

"""
    C_iio_device_attr_write(device, attr, value)

Set the value of the given device-specific attribute.

# Parameters
- `device::Ptr{iio_device}` : A pointer to an iio_device structure
- `attr::String`            : A NULL-terminated string corresponding to the name of the attribute
- `value::String`           : A NULL-terminated string to set the attribute to

# Returns
- On success, the number of bytes written
- On error, a negative errno code is returned

# NOTE
By passing NULL as the "attr" argument to `iio_device_attr_write`, it is now possible to write all of the attributes of a device.

The buffer must contain one block of data per attribute of the device, by the order they appear in the iio_device structure.

The first four bytes of one block correspond to a 32-bit signed value in network order.
If negative, the attribute is not written;
if positive, it corresponds to the length of the data to write. In that case, the rest of the block must contain the data.

# WARNING
If the value given is among the available values but not working on the radio,
this function returns the success value without actually writing the value.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#gaaa2d1867c15ef8f8424164d0ccea4dd8)
"""
function C_iio_device_attr_write(device::Ptr{iio_device}, attr::String, value::String)
    return ccall(
        (:iio_device_attr_write, libIIO),
        Cssize_t, (Ptr{iio_device}, Cstring, Cstring),
        device, attr, value
    );
end

"""
    C_iio_device_attr_write_all()

THIS IS A PLACEHOLDER. THE DOCUMENTATION BELOW IS ONLY A COPY/PASTE OF THE C DOCUMENTATION.

Set the values of all device-specific attributes.

# Parameters
- dev : A pointer to an iio_device structure
- cb : A pointer to a callback function
- data : A pointer that will be passed to the callback function

# Returns
- On success, 0 is returned
- On error, a negative errno code is returned

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#gadfbbfafabc32d6954d3f3dfcda957735)
"""
function C_iio_device_attr_write_all()
    return "PLACEHOLDER"
end

"""
    C_iio_device_attr_write_bool(device, attr, value)

Set the value of the given device-specific attribute.

# Parameters
- `device::Ptr{iio_device}` : A pointer to an iio_device structure
- `attr::String`            : A NULL-terminated string corresponding to the name of the attribute
- `value::Bool`             : A bool value to set the attribute to

# Returns
- On success, 0 is returned
- On error, a negative errno code is returned

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#ga9f53f9d1c3dc9f87191943fcbd1a7324)
"""
function C_iio_device_attr_write_bool(device::Ptr{iio_device}, attr::String, value::Bool)
    return ccall(
        (:iio_device_attr_write_bool, libIIO),
        Cint, (Ptr{iio_device}, Cstring, Cuchar),
        device, attr, value
    );
end

"""
    C_iio_device_attr_write_double(device, attr, value)

Set the value of the given device-specific attribute.

# Parameters
- `device::Ptr{iio_device}` : A pointer to an iio_device structure
- `attr::String`            : A NULL-terminated string corresponding to the name of the attribute
- `value::Float64`          : A double value to set the attribute to

# Returns
- On success, 0 is returned
- On error, a negative errno code is returned

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#gacdaf529f12b46ba2a5290bbc590c8b9e)
"""
function C_iio_device_attr_write_double(device::Ptr{iio_device}, attr::String, value::Float64)
    return ccall(
        (:iio_device_attr_write_double, libIIO),
        Cint, (Ptr{iio_device}, Cstring, Cdouble),
        device, attr, value
    );
end

"""
    C_iio_device_attr_write_longlong(device, attr, value)

Set the value of the given device-specific attribute.

# Parameters
- `device::Ptr{iio_device}` : A pointer to an iio_device structure
- `attr::String`            : A NULL-terminated string corresponding to the name of the attribute
- `value::Int64`            : A long long value to set the attribute to

# Returns
- On success, 0 is returned
- On error, a negative errno code is returned

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#ga3fcba684f6b07d3f6295759bb788c4d2)
"""
function C_iio_device_attr_write_longlong(device::Ptr{iio_device}, attr::String, value::Int64)
    return ccall(
        (:iio_device_attr_write_longlong, libIIO),
        Cint, (Ptr{iio_device}, Cstring, Clonglong),
        device, attr, value
    );
end

"""
    C_iio_device_attr_write_raw(device, attr, value)

Set the value of the given device-specific attribute.

# Parameters
- `device::Ptr{iio_device}` : A pointer to an iio_device structure
- `attr::String`            : A NULL-terminated string corresponding to the name of the attribute
- `value::Ptr{Cvoid}`       : A pointer to the data to be written
- `size::Csize_t`           : The number of bytes to be written

# Returns
- On success, the number of bytes written
- On error, a negative errno code is returned

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#ga30829a67dcdffc902c4ba6801233e79a)
"""
function C_iio_device_attr_write_raw(device::Ptr{iio_device}, attr::String, value::Ptr{Cvoid}, size::Csize_t)
    return ccall(
        (:iio_device_attr_write_raw, libIIO),
        Cssize_t, (Ptr{iio_device}, Cstring, Ptr{Cvoid}, Csize_t),
        device, attr, value, size
    );
end

"""
    C_iio_device_buffer_attr_read(device, attr)

Read the content of the given buffer-specific attribute.

# Parameters
- `device::Ptr{iio_device}` : A pointer to an iio_device structure
- `attr::String`            : A NULL-terminated string corresponding to the name of the attribute. Passing an empty string reads all the attributes.

# Returns
- On success, (number_of_bytes, value::String) is returned, where number of bytes should be the length of the string.
- On error, (errno, "") is returned, where errno is a negative error code.
- If all the attributes are being read, an array of the values above is returned.
The string may be shorter than the actual number of bytes returned as the conversion trims excess null characters.

# NOTE
By passing NULL (replaced by an empty string in the Julia wrapper) as the "attr" argument to `iio_device_buffer_attr_read`, it is now possible to read all of the attributes of a device.

The buffer is filled with one block of data per attribute of the buffer, by the order they appear in the iio_device structure.

The first four bytes of one block correspond to a 32-bit signed value in network order.
If negative, it corresponds to the errno code that were returned when reading the attribute;
if positive, it corresponds to the length of the data read. In that case, the rest of the block contains the data.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#gaa77d52bb9dea248cc3de682778a08a6f)
"""
function C_iio_device_buffer_attr_read(device::Ptr{iio_device}, attr::String)
    if attr == ""; attr = C_NULL; end; # allows to read all the attributes
    buf = zeros(UInt8, BUF_SIZE);
    ret = ccall(
        (:iio_device_buffer_attr_read, libIIO),
        Cssize_t, (Ptr{iio_device}, Cstring, Cstring, Csize_t),
        device, attr, pointer(buf), BUF_SIZE
    );
    attr == C_NULL ? attrs = iio_decode_blocks(buf, ret) : attrs = toString(buf);
    return ret, attrs;
end

"""
    C_iio_device_buffer_attr_read_all()

THIS IS A PLACEHOLDER. THE DOCUMENTATION BELOW IS ONLY A COPY/PASTE OF THE C DOCUMENTATION.

Read the content of all buffer-specific attributes.

# Parameters
- dev : A pointer to an iio_device structure
- cb : A pointer to a callback function
- data : A pointer that will be passed to the callback function

# Returns
- On success, 0 is returned
- On error, a negative errno code is returned

# NOTE
This function is especially useful when used with the network backend, as all the buffer-specific attributes are read in one single command.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#gaae5bf33ad1bd1b14155eab4a018c576c)
"""
function C_iio_device_buffer_attr_read_all()
    return "PLACEHOLDER"
end

"""
    C_iio_device_buffer_attr_read_bool(device, attr)

Read the content of the given buffer-specific attribute.

# Parameters
- `device::Ptr{iio_device}` : A pointer to an iio_device structure
- `attr::String`            : A NULL-terminated string corresponding to the name of the attribute

# Returns
- On success, (0, value::Bool) is returned.
- On error, (errno, value::Bool) is returned, where errno is a negative error code. `value` should be discarded.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#ga92ee863b94e6f841efec3919f57f5193)
"""
function C_iio_device_buffer_attr_read_bool(device::Ptr{iio_device}, attr::String)
    value = Ref{UInt8}(0);
    ret = ccall(
        (:iio_device_buffer_attr_read_bool, libIIO),
        Cint, (Ptr{iio_device}, Cstring, Ptr{Cuchar}),
        device, attr, value
    );
    return ret, Base.convert(Bool, value[]);
end

"""
    C_iio_device_buffer_attr_read_double(device, attr)

Read the content of the given buffer-specific attribute.

# Parameters
- `device::Ptr{iio_device}` : A pointer to an iio_device structure
- `attr::String`            : A NULL-terminated string corresponding to the name of the attribute

# Returns
- On success, (0, value::Float64) is returned.
- On error, (errno, value::Float64) is returned, where errno is a negative error code. `value` should be discarded.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#ga44952198b73ff6b0c0c0b53d3cd6d1bd)
"""
function C_iio_device_buffer_attr_read_double(device::Ptr{iio_device}, attr::String)
    value = Ref{Float64}(0);
    ret = ccall(
        (:iio_device_buffer_attr_read_double, libIIO),
        Cint, (Ptr{iio_device}, Cstring, Ptr{Cdouble}),
        device, attr, value
    );
    return ret, value[];
end

"""
    C_iio_device_buffer_attr_read_longlong(device, attr)

Read the content of the given buffer-specific attribute.

# Parameters
- `device::Ptr{iio_device}` : A pointer to an iio_device structure
- `attr::String`            : A NULL-terminated string corresponding to the name of the attribute

# Returns
- On success, (0, value::Int64) is returned.
- On error, (errno, value::Int64) is returned, where errno is a negative error code. `value` should be discarded.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#gae5b9be890edb372d3e30a14ce1c79874)
"""
function C_iio_device_buffer_attr_read_longlong(device::Ptr{iio_device}, attr::String)
    value = Ref{Int64}(0);
    ret = ccall(
        (:iio_device_buffer_attr_read_longlong, libIIO),
        Cint, (Ptr{iio_device}, Cstring, Ptr{Clonglong}),
        device, attr, value
    );
    return ret, value[];
end

"""
    C_iio_device_buffer_attr_write(device, attr, value)

Set the value of the given buffer-specific attribute.

# Parameters
- `device::Ptr{iio_device}` : A pointer to an iio_device structure
- `attr::String`            : A NULL-terminated string corresponding to the name of the attribute
- `value::String`           : A NULL-terminated string to set the attribute to

# Returns
- On success, the number of bytes written
- On error, a negative errno code is returned

# NOTE
By passing NULL as the "attr" argument to `iio_device_buffer_attr_write`, it is now possible to write all of the attributes of a device.

The buffer must contain one block of data per attribute of the buffer, by the order they appear in the iio_device structure.

The first four bytes of one block correspond to a 32-bit signed value in network order.
If negative, the attribute is not written;
if positive, it corresponds to the length of the data to write. In that case, the rest of the block must contain the data.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#ga8a12066003b7ef442e95bfbc22b4370b)
"""
function C_iio_device_buffer_attr_write(device::Ptr{iio_device}, attr::String, value::String)
    return ccall(
        (:iio_device_buffer_attr_write, libIIO),
        Cssize_t, (Ptr{iio_device}, Cstring, Cstring),
        device, attr, value
    );
end

"""
    C_iio_device_buffer_attr_write_all()

THIS IS A PLACEHOLDER. THE DOCUMENTATION BELOW IS ONLY A COPY/PASTE OF THE C DOCUMENTATION.

Set the values of all buffer-specific attributes.

# Parameters
- dev : A pointer to an iio_device structure
- cb : A pointer to a callback function
- data : A pointer that will be passed to the callback function

# Returns
- On success, 0 is returned
- On error, a negative errno code is returned

# NOTE
This function is especially useful when used with the network backend, as all the buffer-specific attributes are written in one single command.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#ga3d77bb90c22eb1d0a13805bf69def068)
"""
function C_iio_device_buffer_attr_write_all()
    return "PLACEHOLDER"
end

"""
    C_iio_device_buffer_attr_write_bool(device, attr, value)

Set the value of the given buffer-specific attribute.

# Parameters
- `device::Ptr{iio_device}` : A pointer to an iio_device structure
- `attr::String`            : A NULL-terminated string corresponding to the name of the attribute
- `value::Bool`             : A bool value to set the attribute to

# Returns
- On success, 0 is returned
- On error, a negative errno code is returned

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#ga3fad39798014287c24c36bac4a67648e)
"""
function C_iio_device_buffer_attr_write_bool(device::Ptr{iio_device}, attr::String, value::Bool)
    return ccall(
        (:iio_device_buffer_attr_write_bool, libIIO),
        Cint, (Ptr{iio_device}, Cstring, Cuchar),
        device, attr, value
    );
end

"""
    C_iio_device_buffer_attr_write_double(device, attr, value)

Set the value of the given buffer-specific attribute.

# Parameters
- `device::Ptr{iio_device}` : A pointer to an iio_device structure
- `attr::String`            : A NULL-terminated string corresponding to the name of the attribute
- `value::Float64`          : A double value to set the attribute to

# Returns
- On success, 0 is returned
- On error, a negative errno code is returned

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#ga10d47af8de4ad1f9dc4b63ce0aa0ff7d)
"""
function C_iio_device_buffer_attr_write_double(device::Ptr{iio_device}, attr::String, value::Float64)
    return ccall(
        (:iio_device_buffer_attr_write_double, libIIO),
        Cint, (Ptr{iio_device}, Cstring, Cdouble),
        device, attr, value
    );
end

"""
    C_iio_device_buffer_attr_write_longlong(device, attr, value)

Set the value of the given buffer-specific attribute.

# Parameters
- `device::Ptr{iio_device}` : A pointer to an iio_device structure
- `attr::String`            : A NULL-terminated string corresponding to the name of the attribute
- `value::Int64`            : A long long value to set the attribute to

# Returns
- On success, 0 is returned
- On error, a negative errno code is returned

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#gac05869aa707121328dd72cdad10cedf2)
"""
function C_iio_device_buffer_attr_write_longlong(device::Ptr{iio_device}, attr::String, value::Int64)
    return ccall(
        (:iio_device_buffer_attr_write_longlong, libIIO),
        Cint, (Ptr{iio_device}, Cstring, Clonglong),
        device, attr, value
    );
end

"""
    C_iio_device_buffer_attr_write_raw(device, attr, value)

Set the value of the given buffer-specific attribute.

# Parameters
- `device::Ptr{iio_device}` : A pointer to an iio_device structure
- `attr::String`            : A NULL-terminated string corresponding to the name of the attribute
- `value::Ptr{Cvoid}`       : A pointer to the data to be written
- `size::Csize_t`           : The number of bytes to be written

# Returns
- On success, the number of bytes written
- On error, a negative errno code is returned

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#ga982e2bcb890aab88eabf833a00ba841a)
"""
function C_iio_device_buffer_attr_write_raw(device::Ptr{iio_device}, attr::String, value::Ptr{Cvoid}, size::Csize_t)
    return ccall(
        (:iio_device_buffer_attr_write_raw, libIIO),
        Cssize_t, (Ptr{iio_device}, Cstring, Ptr{Cvoid}, Csize_t),
        device, attr, value, size
    );
end

"""
    C_iio_device_find_attr(device, name)

Try to find a device-specific attribute by its name.

# Parameters
- `device::Ptr{iio_device}` : A pointer to an iio_device structure
- `name::String`            : A NULL-terminated string corresponding to the name of the attribute

# Returns
- On success, a NULL-terminated string.
- On failure, if the assertions are enabled, throws an error.
- On failure, if the assertions are disabled, returns an empty string.

# NOTE
This function is useful to detect the presence of an attribute.
It can also be used to retrieve the name of an attribute as a pointer to a static string from a dynamically allocated string.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#gafcbece1ac6260b06bcdf02d9eb55e5fd)
"""
function C_iio_device_find_attr(device::Ptr{iio_device}, name::String)
    @assert_Cstring attr = ccall(
        (:iio_device_find_attr, libIIO),
        Cstring, (Ptr{iio_device}, Cstring),
        device, name
    );
    return attr == C_NULL ? "" : Base.unsafe_string(attr);
end

"""
    C_iio_device_find_buffer_attr(device, name)

Try to find a buffer-specific attribute by its name.

# Parameters
- `device::Ptr{iio_device}` : A pointer to an iio_device structure
- `name::String`            : A NULL-terminated string corresponding to the name of the attribute

# Returns
- On success, a NULL-terminated string.
- On failure, if the assertions are enabled, throws an error.
- On failure, if the assertions are disabled, returns an empty string.

# NOTE
This function is useful to detect the presence of an attribute.
It can also be used to retrieve the name of an attribute as a pointer to a static string from a dynamically allocated string.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#ga58baa15da06b2d497fb0334f35264240)
"""
function C_iio_device_find_buffer_attr(device::Ptr{iio_device}, name::String)
    @assert_Cstring attr = ccall(
        (:iio_device_find_buffer_attr, libIIO),
        Cstring, (Ptr{iio_device}, Cstring),
        device, name
    );
    return attr == C_NULL ? "" : Base.unsafe_string(attr);
end

"""
    C_iio_device_find_channel(device, name, isOutput)

Try to find a channel structure by its name of ID.

# Parameters
- `device::Ptr{iio_device}` : A pointer to an iio_device structure
- `name::String`            : A NULL-terminated string corresponding to the name or the ID of the channel to search for
- `isOutput::Bool`          : True if the searched channel is output, False otherwise

# Returns
- On success, a pointer to an iio_channel structure
- On failure, if the assertions are enabled, throws an error.
- On failure, if the assertions are disabled, returns NULL.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#gaffc6086189ba801ab5e95341d68f882b)
"""
function C_iio_device_find_channel(device::Ptr{iio_device}, name::String, isOutput::Bool)
    @assert_null_pointer channel = ccall(
        (:iio_device_find_channel, libIIO),
        Ptr{iio_channel}, (Ptr{iio_device}, Cstring, Cuchar),
        device, name, isOutput
    );
    return channel;
end

"""
    C_iio_device_get_attr(device, index)

Get the device-specific attribute present at the given index.

# Parameters
- `device::Ptr{iio_device}` : A pointer to an iio_device structure
- `index::UInt32`           : The index corresponding to the attribute

# Returns
- On success, a NULL-terminated string.
- On failure, if the assertions are enabled, throws an error.
- On failure, if the assertions are disabled, returns an empty string.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#ga70b03d4cb3cc3c4fb1b6451764c8ccec)
"""
function C_iio_device_get_attr(device::Ptr{iio_device}, index::UInt32)
    @assert_Cstring attr = ccall(
        (:iio_device_get_attr, libIIO),
        Cstring, (Ptr{iio_device}, Cuint),
        device, index
    );
    return attr == C_NULL ? "" : Base.unsafe_string(attr);
end

"""
    C_iio_device_get_attrs_count(device)

Enumerate the device-specific attributes of the given device.

# Parameters
- `device::Ptr{iio_device}` : A pointer to an iio_device structure

# Returns
- The number of device-specific attributes found

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#ga36c2d0f703a803f44a578bc83fdab6a0)
"""
function C_iio_device_get_attrs_count(device::Ptr{iio_device})
    return ccall(
        (:iio_device_get_attrs_count, libIIO),
        Cuint, (Ptr{iio_device},),
        device
    );
end

"""
    C_iio_device_get_buffer_attr(device, index)

Get the buffer-specific attribute present at the given index.

# Parameters
- `device::Ptr{iio_device}` : A pointer to an iio_device structure
- `index::UInt32`           : The index corresponding to the attribute

# Returns
- On success, a NULL-terminated string.
- On failure, if the assertions are enabled, throws an error.
- On failure, if the assertions are disabled, returns an empty string.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#ga7225b9df06559012d549d627fb451c2a)
"""
function C_iio_device_get_buffer_attr(device::Ptr{iio_device}, index::UInt32)
    @assert_Cstring attr = ccall(
        (:iio_device_get_buffer_attr, libIIO),
        Cstring, (Ptr{iio_device}, Cuint),
        device, index
    );
    return attr == C_NULL ? "" : Base.unsafe_string(attr);
end

"""
    C_iio_device_get_buffer_attrs_count(device)

Enumerate the buffer-specific attributes of the given device.

# Parameters
- `device::Ptr{iio_device}` : A pointer to an iio_device structure

# Returns
- The number of buffer-specific attributes found

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#ga6d4bd3c4f9791c706d9baa4454e0f1d3)
"""
function C_iio_device_get_buffer_attrs_count(device::Ptr{iio_device})
    return ccall(
        (:iio_device_get_buffer_attrs_count, libIIO),
        Cuint, (Ptr{iio_device},),
        device
    );
end

"""
    C_iio_device_get_channel(device, index)

Get the channel present at the given index.

# Parameters
- `device::Ptr{iio_device}` : A pointer to an iio_device structure
- `index::UInt32`           : The index corresponding to the channel

# Returns
- On success, a pointer to an iio_channel structure
- On failure, if the assertions are enabled, throws an error.
- On failure, if the assertions are disabled, returns NULL.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#ga67289d735b7d8e1ed12ae0ea642bd1ac)
"""
function C_iio_device_get_channel(device::Ptr{iio_device}, index::UInt32)
    @assert_null_pointer channel = ccall(
        (:iio_device_get_channel, libIIO),
        Ptr{iio_channel}, (Ptr{iio_device}, Cuint),
        device, index
    );
    return channel;
end

"""
    C_iio_device_get_channels_count(device)

Retrieve a pointer to the iio_context structure.

# Parameters
- `device::Ptr{iio_device}` : A pointer to an iio_device structure

# Returns
- A pointer to an iio_context structure

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#gae10ff440f64dac52b4229eb3f2ebea76)
"""
function C_iio_device_get_channels_count(device::Ptr{iio_device})
    return ccall(
        (:iio_device_get_channels_count, libIIO),
        Cuint, (Ptr{iio_device},),
        device
    );
end

"""
    C_iio_device_get_context(device)

Retrieve a pointer to the iio_context structure.

# Parameters
- `device::Ptr{iio_device}` : A pointer to an iio_device structure

# Returns
- A pointer to an iio_context structure

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#gacc7d7b43ca5a1e228ef4c3a4952195fd)
"""
function C_iio_device_get_context(device::Ptr{iio_device})
    return ccall(
        (:iio_device_get_context, libIIO),
        Ptr{iio_context}, (Ptr{iio_device},),
        device
    );
end

"""
    C_iio_device_get_data(device)

Retrieve a previously associated pointer of an iio_device structure.

# Parameters
- `device::Ptr{iio_device}` : A pointer to an iio_device structure

# Returns
- The pointer previously associated if present, or NULL

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#ga87cff8d90e1a68e73410e4a527cc5334)
"""
function C_iio_device_get_data(device::Ptr{iio_device})
    return ccall(
        (:iio_device_get_data, libIIO),
        Ptr{Cvoid}, (Ptr{iio_device},),
        device
    );
end

"""
    C_iio_device_get_id(device)

Retrieve the device ID (e.g. iio:device0)

# Parameters
- `device::Ptr{iio_device}` : A pointer to an iio_device structure

# Returns
- A NULL-terminated string

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#ga9e6610c3dd7cc45bebcc7ed7a1b064c6)
"""
function C_iio_device_get_id(device::Ptr{iio_device})
    return Base.unsafe_string(ccall(
        (:iio_device_get_id, libIIO),
        Cstring, (Ptr{iio_device},),
        device
    ));
end

"""
    C_iio_device_get_name(device)

Retrieve the device name (e.g. xadc)

# Parameters
- `device::Ptr{iio_device}` : A pointer to an iio_device structure

# Returns
- A NULL-terminated string

# NOTE
If the device has no name and the assertions are enabled, throws an error.
If the device has no name and the assertions are enabled, returns an emtpy string.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#ga711666b3b3b6314fbe7e592b4632ab85)
"""
function C_iio_device_get_name(device::Ptr{iio_device})
    @assert_Cstring name = ccall(
        (:iio_device_get_name, libIIO),
        Cstring, (Ptr{iio_device},),
        device
    );
    return name == C_NULL ? "" : Base.unsafe_string(name);
end

"""
    C_iio_device_get_trigger(device)

Retrieve the trigger of a given device.

# Parameters
- `device::Ptr{iio_device}` : A pointer to an iio_device structure

# Returns
- On success, `(0, trigger::Ptr{iio_device})` is returned.
- On error, `(errno, NULL)` is returned, where errno is a negative error code.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#gae3ce1d7385ca02a9f6c36768fa41c610)
"""
function C_iio_device_get_trigger(device::Ptr{iio_device})
    trigger = Ptr{iio_device}();
    ret = ccall(
        (:iio_device_get_trigger, libIIO),
        Cint, (Ptr{iio_device}, Ref{Ptr{iio_device}}),
        device, Ref(trigger)
    );
    return ret, trigger
end

"""
    C_iio_device_is_trigger(device)

Return True if the given device is a trigger.

# Parameters
- `device::Ptr{iio_device}` : A pointer to an iio_device structure

# Returns
- True if the device is a trigger, False otherwise

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#ga7e3e5dee1ac8c082de038829c88edda8)
"""
function C_iio_device_is_trigger(device::Ptr{iio_device})
    return Base.convert(Bool, ccall(
        (:iio_device_is_trigger, libIIO),
        Cuchar, (Ptr{iio_device},),
        device
    ));
end

"""
    C_iio_device_set_data(device, data)

Associate a pointer to an iio_device structure. If the pointer is a Julia pointer, you need to protect the data from the GC.

See the [Julia Documentation](https://docs.julialang.org/en/v1/manual/calling-c-and-fortran-code/#Garbage-Collection-Safety) and [`GC.@preserve`](https://docs.julialang.org/en/v1/base/base/#Base.GC.@preserve).

# Parameters
- `device::Ptr{iio_device}` : A pointer to an iio_device structure
- `data::Ptr{Cvoid}`        : A pointer to the data to be associated.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#gab566248f50503d8975cf258a1f218275)
"""
function C_iio_device_set_data(device::Ptr{iio_device}, data::Ptr{Cvoid})
    ccall(
        (:iio_device_set_data, libIIO),
        Cvoid, (Ptr{iio_device}, Ptr{Cvoid}),
        device, data
    );
end

"""
    C_iio_device_set_kernel_buffers_count(device, nb_buffers)

Configure the number of kernel buffers for a device.

This function allows to change the number of buffers on kernel side.

# Parameters
- `device::Ptr{iio_device}` : A pointer to an iio_device structure
- `nb_buffers::UInt32`      : The number of buffers

# Returns
- On success, 0 is returned
- On error, a negative errno code is returned

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#ga8ad2357c4caf7afc778060a08e6e2209)
"""
function C_iio_device_set_kernel_buffers_count(device::Ptr{iio_device}, nb_buffers::UInt32)
    return ccall(
        (:iio_device_set_kernel_buffers_count, libIIO),
        Cint, (Ptr{iio_device}, Cuint),
        device, nb_buffers
    );
end

"""
    C_iio_device_set_trigger(device, trigger)

Associate a trigger to a given device.

# Parameters
- `device::Ptr{iio_device}`  : A pointer to an iio_device structure
- `trigger::Ptr{iio_device}` : a pointer to the iio_device structure corresponding to the trigger that should be associated.

# Returns
- On success, 0 is returned
- On error, a negative errno code is returned

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Device.html#ga3b8d1e621357f0755925d98555f53d9a)
"""
function C_iio_device_set_trigger(device::Ptr{iio_device}, trigger::Ptr{iio_device})
    return ccall(
        (:iio_device_set_trigger, libIIO),
        Cint, (Ptr{iio_device}, Ptr{iio_device}),
        device, trigger
    );
end
