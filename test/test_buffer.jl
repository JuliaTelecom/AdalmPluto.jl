using Test;

using AdalmPluto;

@testset "libIIO/buffer.jl" begin
    toggleNoAssertions(true);

    try
        global uri          = AdalmPluto.scan("usb", 1, false)[1];
        global ctx          = AdalmPluto.createContext(uri);
        global tx, rx       = AdalmPluto.findTRXDevices(ctx);
        global txc, rxc     = AdalmPluto.findTRXChannels(ctx);
        global txloc, rxloc = AdalmPluto.findLoChannels(ctx);
        global txi, txq     = AdalmPluto.findIQChannels(tx, "voltage0", "voltage1", true);
        global rxi, rxq     = AdalmPluto.findIQChannels(rx, "voltage0", "voltage1", false);

        C_iio_channel_enable(txi);
        C_iio_channel_enable(txq);
        C_iio_channel_enable(rxi);
        C_iio_channel_enable(rxq);
    catch
        @error "Could not get a valid uri or context or channels, skipping the remaining tests.";
        C_iio_context_destroy(ctx);
        return;
    end

    #  C_iio_device_create_buffer (device::Ptr, …)
    @test (global buf = C_iio_device_create_buffer(rx, UInt(1024), false)) != C_NULL;
    @testset "Buffer properties" begin
        #  C_iio_buffer_get_device (buffer::Ptr, …)
        @test C_iio_buffer_get_device(buf) == rx;
        #  C_iio_buffer_get_poll_fd (buffer::Ptr, …)
        @test_skip C_iio_buffer_get_poll_fd(buf) > 0;                   # The function returns -38: Function not implemented
        #  C_iio_buffer_set_blocking_mode (buffer::Ptr, …)
        @test_skip C_iio_buffer_set_blocking_mode(buf, false) == 0;     # The function returns -38: Function not implemented
        @test_skip C_iio_buffer_set_blocking_mode(buf, true) == 0;      # The function returns -38: Function not implemented
        # By default devices are blocking

        saved_data_ptr = C_iio_buffer_get_data(buf);
        test_data = b"Test data\0";
        #  C_iio_buffer_set_data (buffer::Ptr, …)
        @test C_iio_buffer_set_data(buf, Ptr{Cvoid}(pointer(test_data))) === nothing;
        #  C_iio_buffer_get_data (buffer::Ptr, …)
        @test C_iio_buffer_get_data(buf) == Ptr{Cvoid}(pointer(test_data));
        C_iio_buffer_set_data(buf, saved_data_ptr);

        #  C_iio_buffer_start (buffer::Ptr, …)
        @test C_iio_buffer_start(buf) != C_NULL;
        #  C_iio_buffer_first (buffer::Ptr, …)
        @test C_iio_buffer_first(buf, rxi) != C_NULL;
        #  C_iio_buffer_step (buffer::Ptr, …)
        @test C_iio_buffer_step(buf) > 0;
        #  C_iio_buffer_end (buffer::Ptr, …)
        @test C_iio_buffer_end(buf) != C_NULL;
    end

    @testset "Buffer read/write" begin
        #  C_iio_buffer_refill (buffer::Ptr, …)
        @test C_iio_buffer_refill(buf) > 0;

        #  C_iio_channel_read! (chn::Ptr, …)
        smp = zeros(UInt8, 512 * C_iio_device_get_sample_size(rx));
        @test C_iio_channel_read!(rxi, buf, smp) == 512 * C_iio_device_get_sample_size(rx);

        # Testing those implies you can listen to what the radio emits
        #  C_iio_buffer_push (buffer::Ptr, …)
        @test_skip C_iio_buffer_push(buf) > 0;
        #  C_iio_buffer_push_partial (buffer::Ptr, …)
        @test_skip C_iio_buffer_push_partial(buf, samples_count) > 0;

        #  C_iio_buffer_cancel (buffer::Ptr, …)
        @test_skip C_iio_buffer_cancel(buf) === nothing;
    end

    @testset "Placeholders" begin
        #  C_iio_buffer_foreach_sample
        @test_skip C_iio_buffer_foreach_sample() === nothing;
    end

    C_iio_channel_disable(txi);
    C_iio_channel_disable(txq);
    C_iio_channel_disable(rxi);
    C_iio_channel_disable(rxq);

    #  C_iio_buffer_destroy (buffer::Ptr, …)
    @test C_iio_buffer_destroy(buf) === nothing;

    C_iio_context_destroy(ctx);
end
