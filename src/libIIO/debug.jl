"""
    C_iio_device_get_sample_size(device)

Get the current sample size.

# Parameters
- `device::Ptr{iio_device}` : A pointer to an iio_device structure

# Returns
- On success, the sample size in bytes
- On error, a negative errno code is returned

# NOTE
The sample size is not constant and will change when channels get enabled or disabled.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Debug.html#ga52b3e955c10d6f962b2c2e749c7c02fb)
"""
function C_iio_device_get_sample_size(device::Ptr{iio_device})
    return ccall(
        (:iio_device_get_sample_size, libIIO),
        Cssize_t, (Ptr{iio_device},),
        device
    );
end

"""
    C_iio_device_identify_filename(device, filename)

Identify the channel or debug attribute corresponding to a filename.

# Parameters
- `device::Ptr{iio_device}` : A pointer to an iio_device structure
- `filename::String` : A NULL-terminated string corresponding to the filename

# Returns
- On success, `(0, channel::Ptr{iio_channel}, attribute::String)` is returned.
- On error, `(errno, NULL, "")` is returned, where errno is a negative error code.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Debug.html#ga87ef46fa578c7be7b3e2a6f9f16fdf7e)
"""
function C_iio_device_identify_filename(device::Ptr{iio_device}, filename::String)
    channel = Ref{Ptr{iio_channel}}();
    attribute = Ref{Ptr{Cuchar}}();
    ret = ccall(
        (:iio_device_identify_filename, libIIO),
        Cint, (Ptr{iio_device}, Cstring, Ptr{Ptr{iio_channel}}, Ptr{Ptr{Cuchar}}),
        device, filename, channel, attribute
    );
    return attribute[] == C_NULL ? (ret, channel[], "") : (ret, channel[], Base.unsafe_string(attribute[]));
end
