function C_iio_buffer_cancel(buffer::Ptr{iio_buffer})
    ccall(
        (:iio_buffer_cancel, libIIO),
        Cvoid, (Ptr{iio_buffer},),
        buffer
    );
end

function C_iio_buffer_destroy(buffer::Ptr{iio_buffer})
    ccall(
        (:iio_buffer_destroy, libIIO),
        Cvoid, (Ptr{iio_buffer},),
        buffer
    );
end

function C_iio_buffer_end(buffer::Ptr{iio_buffer})
    return ccall(
        (:iio_buffer_end, libIIO),
        Ptr{Cuchar}, (Ptr{iio_buffer},),
        buffer
    );
end

function C_iio_buffer_first(buffer::Ptr{iio_buffer}, channel::Ptr{iio_channel})
    return ccall(
        (:iio_buffer_first, libIIO),
        Ptr{Cuchar}, (Ptr{iio_buffer}, Ptr{iio_channel}),
        buffer, channel
    );
end

function C_iio_buffer_foreach_sample()
    return "PLACEHOLDER"
end

# can return null
function C_iio_buffer_get_data(buffer::Ptr{iio_buffer})
    return ccall(
        (:iio_buffer_get_data, libIIO),
        Ptr{Cuchar}, (Ptr{iio_buffer},),
        buffer
    );
end

function C_iio_buffer_get_device(buffer::Ptr{iio_buffer})
    return ccall(
        (:iio_buffer_get_device, libIIO),
        Ptr{iio_device}, (Ptr{iio_buffer},),
        buffer
    );
end

function C_iio_buffer_get_poll_fd(buffer::Ptr{iio_buffer})
    return ccall(
        (:iio_buffer_get_poll_fd, libIIO),
        Cint, (Ptr{iio_buffer},),
        buffer
    );
end

function C_iio_buffer_push(buffer::Ptr{iio_buffer})
    return ccall(
        (:iio_buffer_push, libIIO),
        Cssize_t, (Ptr{iio_buffer},),
        buffer
    );
end

function C_iio_buffer_push_partial(buffer::Ptr{iio_buffer}, sample_count::UInt)
    return ccall(
        (:iio_buffer_push_partial, libIIO),
        Cssize_t, (Ptr{iio_buffer}, Csize_t),
        buffer, sample_count
    );
end

function C_iio_buffer_refill(buffer::Ptr{iio_buffer})
    return ccall(
        (:iio_buffer_refill, libIIO),
        Cssize_t, (Ptr{iio_buffer},),
        buffer
    );
end

function C_iio_buffer_set_blocking_mode(buffer::Ptr{iio_buffer}, blocking::Bool)
    return ccall(
        (:iio_buffer_set_blocking_mode, libIIO),
        Cint, (Ptr{iio_buffer}, Cuchar),
        buffer, blocking
    );
end

# Ptr{Cvoid} again
# also probably need to make sure data lifetime > buffer lifetime
function C_iio_buffer_set_data(buffer::Ptr{iio_buffer}, data)
    return ccall(
        (:iio_buffer_set_data, libIIO),
        Cvoid, (Ptr{iio_buffer}, Ptr{Cuchar}),
        buffer, data
    );
end

function C_iio_buffer_start(buffer::Ptr{iio_buffer})
    return ccall(
        (:iio_buffer_start, libIIO),
        Ptr{Cuchar}, (Ptr{iio_buffer},),
        buffer
    );
end

function C_iio_buffer_step(buffer::Ptr{iio_buffer})
    return ccall(
        (:iio_buffer_step, libIIO),
        Cssize_t, (Ptr{iio_buffer},),
        buffer
    );
end

function C_iio_device_create_buffer(device::Ptr{iio_device}, samples_count::UInt, cyclic::Bool)
    @assert_buffer buffer = ccall(
        (:iio_device_create_buffer, libIIO),
        Ptr{iio_buffer}, (Ptr{iio_device}, Csize_t, Cuchar),
        device, samples_count, cyclic
    );
    return buffer;
end
