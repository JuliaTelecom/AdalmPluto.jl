"""
    C_iio_buffer_cancel(buffer)

Cancel all buffer operations.

# Parameters
- `buffer::Ptr{iio_buffer}` :The buffer for which operations should be canceled

This function cancels all outstanding buffer operations previously scheduled.
This means any pending iio_buffer_push() or iio_buffer_refill() operation will abort and return immediately,
any further invocations of these functions on the same buffer will return immediately with an error.

Usually iio_buffer_push() and iio_buffer_refill() will block until either all data has been transferred or a timeout occurs.
This can depending on the configuration take a significant amount of time.
iio_buffer_cancel() is useful to bypass these conditions if the buffer operation is supposed to be stopped in response to an external event (e.g. user input).

To be able to capture additional data after calling this function the buffer should be destroyed and then re-created.

This function can be called multiple times for the same buffer, but all but the first invocation will be without additional effect.

This function is thread-safe, but not signal-safe, i.e. it must not be called from a signal handler.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Buffer.html#ga0e42431688750313cfa077ab4f6e0282)
"""
function C_iio_buffer_cancel(buffer::Ptr{iio_buffer})
    ccall(
        (:iio_buffer_cancel, libIIO),
        Cvoid, (Ptr{iio_buffer},),
        buffer
    );
end

"""
    C_iio_buffer_destroy(buffer)

Destroy the given buffer.

# Parameters
- `buffer::Ptr{iio_buffer}` : A pointer to an iio_buffer structure

NOTE: After that function, the iio_buffer pointer shall be invalid.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Buffer.html#gaba58dc2780be63fead6f09397ce90d10)
"""
function C_iio_buffer_destroy(buffer::Ptr{iio_buffer})
    ccall(
        (:iio_buffer_destroy, libIIO),
        Cvoid, (Ptr{iio_buffer},),
        buffer
    );
end

"""
    C_iio_buffer_end(buffer)

Get the address that follows the last sample in a buffer.

# Parameters
- `buffer::Ptr{iio_buffer}` : A pointer to an iio_buffer structure

# Returns
    A pointer corresponding to the address that follows the last sample present in the buffer

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Buffer.html#gab5300f917bbdfc5dafc093a60138f131)
"""
function C_iio_buffer_end(buffer::Ptr{iio_buffer})
    return ccall(
        (:iio_buffer_end, libIIO),
        Ptr{Cuchar}, (Ptr{iio_buffer},),
        buffer
    );
end

"""
    C_iio_buffer_first(buffer, channel)

    Find the first sample of a channel in a buffer.

# Parameters
- `buffer::Ptr{iio_buffer}` : A pointer to an iio_buffer structure
- `channel::Ptr{iio_channel}` : A pointer to an iio_channel structure

# Returns
    A pointer to the first sample found, or to the end of the buffer if no sample for the given channel is present in the buffer

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Buffer.html#ga000d2f4c8b72060db1c38ec905bf4156)
"""
function C_iio_buffer_first(buffer::Ptr{iio_buffer}, channel::Ptr{iio_channel})
    return ccall(
        (:iio_buffer_first, libIIO),
        Ptr{Cuchar}, (Ptr{iio_buffer}, Ptr{iio_channel}),
        buffer, channel
    );
end

"""
    C_iio_buffer_foreach_sample()

THIS IS A PLACEHOLDER. THE DOCUMENTATION BELOW IS ONLY A COPY/PASTE OF THE C DOCUMENTATION.

Call the supplied callback for each sample found in a buffer.

# Parameters
    buf	A pointer to an iio_buffer structure
    callback	A pointer to a function to call for each sample found
    data	A user-specified pointer that will be passed to the callback

# Returns
    number of bytes processed.

NOTE: The callback receives four arguments:

    A pointer to the iio_channel structure corresponding to the sample,
    A pointer to the sample itself,
    The length of the sample in bytes,
    The user-specified pointer passed to iio_buffer_foreach_sample.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Buffer.html#ga810ec50155e82331b18ec71d3c507104)
"""
function C_iio_buffer_foreach_sample()
    return "PLACEHOLDER"
end

"""
    C_iio_buffer_get_data(buffer)

Retrieve a previously associated pointer of an iio_buffer structure.

# Parameters
- `buffer::Ptr{iio_buffer}` : A pointer to an iio_buffer structure

# Returns
    The pointer previously associated if present, or NULL


[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Buffer.html#gac110da795a50dc45fe998cace656329b)
"""
# can return null
function C_iio_buffer_get_data(buffer::Ptr{iio_buffer})
    return ccall(
        (:iio_buffer_get_data, libIIO),
        Ptr{Cuchar}, (Ptr{iio_buffer},),
        buffer
    );
end

"""
    C_iio_buffer_get_device(buffer)

Retrieve a pointer to the iio_device structure.

# Parameters
- `buffer::Ptr{iio_buffer}` : A pointer to an iio_buffer structure

# Returns
    A pointer to an iio_device structure


[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Buffer.html#ga42367567d47f501d1922d1b331cf64fb)
"""
function C_iio_buffer_get_device(buffer::Ptr{iio_buffer})
    return ccall(
        (:iio_buffer_get_device, libIIO),
        Ptr{iio_device}, (Ptr{iio_buffer},),
        buffer
    );
end

"""
    C_iio_buffer_get_poll_fd(buffer)

Get a pollable file descriptor.

Can be used to know when iio_buffer_refill() or iio_buffer_push() can be called

# Parameters
- `buffer::Ptr{iio_buffer}` : A pointer to an iio_buffer structure

# Returns
    On success, valid file descriptor
    On error, a negative errno code is returned

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Buffer.html#ga2ae96ee9f0748e55dfad996d6e9883f2)
"""
function C_iio_buffer_get_poll_fd(buffer::Ptr{iio_buffer})
    return ccall(
        (:iio_buffer_get_poll_fd, libIIO),
        Cint, (Ptr{iio_buffer},),
        buffer
    );
end

"""
    C_iio_buffer_push(buffer)

Send the samples to the hardware.

# Parameters
- `buffer::Ptr{iio_buffer}` : A pointer to an iio_buffer structure

# Returns
    On success, the number of bytes written is returned
    On error, a negative errno code is returned

NOTE: Only valid for output buffers

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Buffer.html#gae7033c625d128667a56cf482aa3149bd)
"""
function C_iio_buffer_push(buffer::Ptr{iio_buffer})
    return ccall(
        (:iio_buffer_push, libIIO),
        Cssize_t, (Ptr{iio_buffer},),
        buffer
    );
end

"""
    C_iio_buffer_push_partial(buffer, sample_count)

Send a given number of samples to the hardware.

# Parameters
- `buffer::Ptr{iio_buffer}` : A pointer to an iio_buffer structure
- `samples_count::UInt` : The number of samples to submit

# Returns
    On success, the number of bytes written is returned
    On error, a negative errno code is returned

NOTE: Only valid for output buffers

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Buffer.html#ga367b7368532aebb35a0d56bccc550570)
"""
function C_iio_buffer_push_partial(buffer::Ptr{iio_buffer}, sample_count::UInt)
    return ccall(
        (:iio_buffer_push_partial, libIIO),
        Cssize_t, (Ptr{iio_buffer}, Csize_t),
        buffer, sample_count
    );
end

"""
    C_iio_buffer_refill(buffer)

Fetch more samples from the hardware.

# Parameters
- `buffer::Ptr{iio_buffer}` : A pointer to an iio_buffer structure

# Returns
    On success, the number of bytes read is returned
    On error, a negative errno code is returned

NOTE: Only valid for input buffers

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Buffer.html#gac999e5244b5a2cbbca5ecaef8303a4ff)
"""
function C_iio_buffer_refill(buffer::Ptr{iio_buffer})
    return ccall(
        (:iio_buffer_refill, libIIO),
        Cssize_t, (Ptr{iio_buffer},),
        buffer
    );
end

"""
    C_iio_buffer_set_blocking_mode(buffer, blocking)

Make iio_buffer_refill() and iio_buffer_push() blocking or not.

After this function has been called with blocking == false, iio_buffer_refill() and iio_buffer_push() will return -EAGAIN if no data is ready.
A device is blocking by default.

# Parameters
- `buffer::Ptr{iio_buffer}` : A pointer to an iio_buffer structure
- `blocking::Bool` : true if the buffer API should be blocking, else false

# Returns
    On success, 0
    On error, a negative errno code is returned

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Buffer.html#gadf834d825ece149886283bcb8c2a5466)
"""
function C_iio_buffer_set_blocking_mode(buffer::Ptr{iio_buffer}, blocking::Bool)
    return ccall(
        (:iio_buffer_set_blocking_mode, libIIO),
        Cint, (Ptr{iio_buffer}, Cuchar),
        buffer, blocking
    );
end

"""
    C_iio_buffer_set_data(buffer, data)

Associate a pointer to an iio_buffer structure.

# Parameters
- `buffer::Ptr{iio_buffer}` : A pointer to an iio_buffer structure
- `data` : A pointer to the data to be associated. Must be castable to Ptr{Cuchar}.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Buffer.html#ga07f485e4e2de57c8c1cd0141611187dc)
"""
# Ptr{Cvoid} again
# also probably need to make sure data lifetime > buffer lifetime
function C_iio_buffer_set_data(buffer::Ptr{iio_buffer}, data)
    return ccall(
        (:iio_buffer_set_data, libIIO),
        Cvoid, (Ptr{iio_buffer}, Ptr{Cuchar}),
        buffer, data
    );
end

"""
    C_iio_buffer_start(buffer)

Get the start address of the buffer.

# Parameters
- `buffer::Ptr{iio_buffer}` : A pointer to an iio_buffer structure

# Returns
    A pointer corresponding to the start address of the buffer


[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Buffer.html#ga7fdacbfda79aa5120f34ea73ae2ea5ab)
"""
function C_iio_buffer_start(buffer::Ptr{iio_buffer})
    return ccall(
        (:iio_buffer_start, libIIO),
        Ptr{Cuchar}, (Ptr{iio_buffer},),
        buffer
    );
end

"""
    C_iio_buffer_step(buffer)

Get the step size between two samples of one channel.

# Parameters
- `buffer::Ptr{iio_buffer}` : A pointer to an iio_buffer structure

# Returns
    the difference between the addresses of two consecutive samples of one same channel

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Buffer.html#ga5532665a8776cec1c209d6cf8d0bb409)
"""
function C_iio_buffer_step(buffer::Ptr{iio_buffer})
    return ccall(
        (:iio_buffer_step, libIIO),
        Cssize_t, (Ptr{iio_buffer},),
        buffer
    );
end

"""
    C_iio_device_create_buffer(device, samples_count, cyclic)

Create an input or output buffer associated to the given device.

# Parameters
- `device::Ptr{iio_device}`: A pointer to an iio_device structure
- `samples_count::UInt` : The number of samples that the buffer should contain
- `cyclic::Bool` : If True, enable cyclic mode

# Returns
    On success, a pointer to an iio_buffer structure
    On error, if the assertions are enabled, throws an error.
    On error, if the assertions are disabled, returns NULL.

NOTE: Channels that have to be written to / read from must be enabled before creating the buffer.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Buffer.html#gaea8067aca27b93a1260a0c563607a501)
"""
function C_iio_device_create_buffer(device::Ptr{iio_device}, samples_count::UInt, cyclic::Bool)
    @assert_null_pointer buffer = ccall(
        (:iio_device_create_buffer, libIIO),
        Ptr{iio_buffer}, (Ptr{iio_device}, Csize_t, Cuchar),
        device, samples_count, cyclic
    );
    return buffer;
end
