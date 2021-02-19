using Test;

using AdalmPluto;

@testset "libIIO/device.jl" begin
    toggleNoAssertions(true);

    try
        global uri = AdalmPluto.scan("usb", 1, false);
        global ctx = AdalmPluto.createContext(uri);
        global txd,rxd = AdalmPluto.findTRXDevices(ctx);
        global phy = C_iio_context_find_device(ctx, AdalmPluto.PHY_DEVICE_NAME);
    catch
        @error "Could not get a valid uri or context or devices, skipping the remaining tests"; return;
    end

    @testset "Device properties" begin
        #  C_iio_device_get_context (device::Ptr, …)
        @test C_iio_device_get_context(rxd) == ctx;

        saved_data_ptr = C_iio_device_get_data(rxd);
        test_data = Cuchar.(collect("Test data"));
        #  C_iio_device_set_data (device::Ptr, …)
        @test C_iio_device_set_data(rxd, Ptr{Cvoid}(pointer(test_data))) === nothing;
        #  C_iio_device_get_data (device::Ptr, …)
        @test C_iio_device_get_data(rxd) == Ptr{Cvoid}(pointer(test_data));
        C_iio_device_set_data(rxd, saved_data_ptr);

        # NOTE : I'm not actually sure if that ID is constant to the model or the radio or the session
        #  C_iio_device_get_id (device::Ptr, …)
        @test C_iio_device_get_id(rxd) == "iio:device4";

        #  C_iio_device_get_name (device::Ptr, …)
        @test C_iio_device_get_name(rxd) == AdalmPluto.RX_DEVICE_NAME;

        # TODO: Find what that function does, and implement its test
        #  C_iio_device_set_kernel_buffers_count (device::Ptr, …)
        @test_skip C_iio_device_set_kernel_buffers_count(device, UInt32(2));
    end

    #TODO: Are there triggers in the AdalmPluto ? Or are those functions meant for other radios ?
    # From libiio doc: Some devices, mostly low speed ADCs and DACs, require a trigger
    @testset "Triggers" begin
        #  C_iio_device_is_trigger (device::Ptr, …)
        @test C_iio_device_is_trigger(rxd) == false;

        for devIdx = 0:C_iio_context_get_devices_count(ctx)-1
            global device = C_iio_context_get_device(ctx, UInt32(devIdx));
            if C_iio_device_is_trigger(device); break; end;
        end

        if !C_iio_device_is_trigger(device)
            @warn "Could not find a trigger device, skipping trigger tests";
        else
            #  C_iio_device_get_trigger (device::Ptr, …)
            @test_skip C_iio_device_get_trigger(rxd) == (-2, Ptr{iio_device}(0));
            #  C_iio_device_set_trigger (device::Ptr, …)
            @test_skip C_iio_device_set_trigger(rxd, device) == 0;
        end

    end

    @testset "Device attributes" begin
        #  C_iio_device_get_attrs_count (device::Ptr, …)
        @test (global nb_attrs = C_iio_device_get_attrs_count(phy)) > 0;

        # uncomment to display all the available attributes
        #  for devIdx = 0:C_iio_context_get_devices_count(ctx)-1
            #  device = C_iio_context_get_device(ctx, UInt32(devIdx));
            #  nb_attrs = C_iio_device_get_attrs_count(device);
            #  for attrIdx = 0:nb_attrs-1
                #  @show attr = C_iio_device_get_attr(device, UInt32(attrIdx));
                #  @show C_iio_device_attr_read(device, attr);
                #  @show C_iio_device_attr_read_bool(device, attr);
                #  @show C_iio_device_attr_read_double(device, attr);
                #  @show C_iio_device_attr_read_longlong(device, attr);
            #  end
        #  end

        if nb_attrs < 1
            @warn "No device attributes, skipping the related tests";
        else
            #  C_iio_device_get_attr (device::Ptr, …)
            @test (global first_attr = C_iio_device_get_attr(phy, UInt32(0))) != "";
            #  C_iio_device_find_attr (device::Ptr, …)
            @test C_iio_device_find_attr(phy, first_attr) == first_attr;

            attr = "calib_mode";
            #  C_iio_device_attr_read (device::Ptr, …)
            @test C_iio_device_attr_read(phy, attr)[1] > 0;
            @test C_iio_device_attr_read(phy, "dummy")[1] < 0;
            saved_attr = C_iio_device_attr_read(phy, attr)[2];
            #  C_iio_device_attr_write (device::Ptr, …)
            @test C_iio_device_attr_write(phy, attr, "manual") > 0 && C_iio_device_attr_read(phy, attr)[2] == "manual";
            @test C_iio_device_attr_write(phy, attr, "auto") > 0 && C_iio_device_attr_read(phy, attr)[2] == "auto";
            #  C_iio_device_attr_write_raw (device::Ptr, …)
            new_calib_mode = b"manual\0";
            @test (C_iio_device_attr_write_raw(phy, attr, Ptr{Cvoid}(pointer(new_calib_mode)), UInt64(sizeof(new_calib_mode))) > 0
                && C_iio_device_attr_read(phy, attr)[2] == "manual");
            # put back the original value
            C_iio_device_attr_write(phy, attr, saved_attr);

            #  C_iio_device_attr_read_bool (device::Ptr, …)
            @test C_iio_device_attr_read_bool(phy, "xo_correction") == (0, true);           # no boolean attributes, so we read a number
            #  C_iio_device_attr_write_bool (device::Ptr, …)
            @test_skip C_iio_device_attr_write_bool(phy, nothing) == 0;               # there are no boolean attributes to write to

            #  C_iio_device_attr_read_double (device::Ptr, …)
            @test C_iio_device_attr_read_double(phy, "xo_correction")[2] > 0;               # same here, real value is an integer
            #  C_iio_device_attr_write_double (device::Ptr, …)
            @test_skip C_iio_device_attr_write_double(phy, nothing) == 0;             # there are no double attributes to write to

            #  C_iio_device_attr_read_longlong (device::Ptr, …)
            @test (global saved_longlong = C_iio_device_attr_read_longlong(phy, "xo_correction")[2]) > 0;
            #  C_iio_device_attr_write_longlong (device::Ptr, …)
            # Could be more robust as we suppose the current value was strictly inferior to the maximum available value
            @test (C_iio_device_attr_write_longlong(phy, "xo_correction", saved_longlong + 1) == 0
                && C_iio_device_attr_read_longlong(phy, "xo_correction") == (0, saved_longlong + 1));
            C_iio_device_attr_write_longlong(phy, "xo_correction", saved_longlong);
        end
    end

    @testset "Buffer attributes" begin
        #  C_iio_device_get_buffer_attrs_count (device::Ptr, …)
        @test (global nb_attrs = C_iio_device_get_buffer_attrs_count(rxd)) > 0;

        # uncomment to display all the available attributes
        #  for devIdx = 0:C_iio_context_get_devices_count(ctx)-1
            #  device = C_iio_context_get_device(ctx, UInt32(devIdx));
            #  nb_attrs = C_iio_device_get_buffer_attrs_count(device);
            #  for attrIdx = 0:nb_attrs-1
                #  @show attr = C_iio_device_get_buffer_attr(device, UInt32(attrIdx));
                #  @show C_iio_device_buffer_attr_read(device, attr);
                #  @show C_iio_device_buffer_attr_read_bool(device, attr);
                #  @show C_iio_device_buffer_attr_read_double(device, attr);
                #  @show C_iio_device_buffer_attr_read_longlong(device, attr);
            #  end
        #  end
        # uncomment to display all the available attributes of a specific device
        #  @show C_iio_device_buffer_attr_read(rxd, "");

        if nb_attrs < 1
            @warn "No device attributes, skipping the related tests";
        else
            #  C_iio_device_get_buffer_attr (device::Ptr, …)
            @test (global first_attr = C_iio_device_get_buffer_attr(rxd, UInt32(0))) != "";
            #  C_iio_device_find_buffer_attr (device::Ptr, …)
            @test C_iio_device_find_buffer_attr(rxd, first_attr) == first_attr;

            attr = "watermark";
            #  C_iio_device_buffer_attr_read (device::Ptr, …)
            @test C_iio_device_buffer_attr_read(rxd, attr)[1] > 0;
            @test C_iio_device_buffer_attr_read(rxd, "dummy")[1] < 0;
            #  saved_attr = C_iio_device_attr_read(rxd, attr)[2];
            #  C_iio_device_buffer_attr_write (device::Ptr, …)
            @test_skip C_iio_device_buffer_attr_write(rxd, attr, nothing);                  # there are no attributes available for user writing
            #  C_iio_device_buffer_attr_write_raw (device::Ptr, …)
            @test_skip C_iio_device_buffer_attr_write_raw(rxd, attr, nothing);              # there are no attributes available for user writing

            #  C_iio_device_buffer_attr_read_bool (device::Ptr, …)
            @test C_iio_device_buffer_attr_read_bool(rxd, attr)[1] == 0;
            #  C_iio_device_buffer_attr_write_bool (device::Ptr, …)
            @test_skip C_iio_device_buffer_attr_write_bool(rxd, attr, nothing);             # there are no boolean attributes to write to

            #  C_iio_device_buffer_attr_read_double (device::Ptr, …)
            @test C_iio_device_buffer_attr_read_double(rxd, attr)[2] > 0;
            #  C_iio_device_buffer_attr_write_double (device::Ptr, …)
            @test_skip C_iio_device_buffer_attr_write_double(rxd, attr, nothing);           # there are no double attributes to write to

            #  C_iio_device_buffer_attr_read_longlong (device::Ptr, …)
            @test C_iio_device_buffer_attr_read_longlong(rxd, attr)[2] > 0;
            #  C_iio_device_buffer_attr_write_longlong (device::Ptr, …)
            @test_skip C_iio_device_buffer_attr_write_longlong(rxd, attr, nothing);         # there are no double attributes available for user writing
        end
    end

    @testset "Channels" begin
        #  C_iio_device_get_channels_count (device::Ptr, …)
        @test (global nb_channels = C_iio_device_get_channels_count(rxd)) > 0;

        if nb_channels < 1
            @warn "No channels found for the tested device, skipping related tests"
        else
            #  C_iio_device_get_channel (device::Ptr, …)
            @test C_iio_device_get_channel(rxd, UInt32(0)) != Ptr{iio_channel}(0);

            #  C_iio_device_find_channel (device::Ptr, …)
            @test C_iio_device_find_channel(phy, "voltage0", false) != Ptr{iio_channel}(0); # RX channel
        end
    end


    # Those functions take a function pointer as an argument, hence their non-implementation
    @testset "Placeholders" begin
        # C_iio_device_attr_read_all
        @test_skip C_iio_device_attr_read_all() == Any;
        # C_iio_device_attr_write_all
        @test_skip C_iio_device_attr_write_all() == Any;
        # C_iio_device_buffer_attr_read_all
        @test_skip C_iio_device_buffer_attr_read_all() == Any;
        # C_iio_device_buffer_attr_write_all
        @test_skip C_iio_device_buffer_attr_write_all() == Any;
    end
end
