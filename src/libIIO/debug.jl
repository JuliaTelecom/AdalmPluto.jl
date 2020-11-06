function C_iio_device_get_sample_size(device::Ptr{iio_device})
    return ccall(
        (:iio_device_get_sample_size, libIIO),
        Cssize_t, (Ptr{iio_device},),
        device
    );
end
