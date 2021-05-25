using Test;

using AdalmPluto;

@testset "libIIO/channel.jl" begin
    toggleNoAssertions(true);

    try
        global uri          = AdalmPluto.scan("usb", 1, false);
        global ctx          = AdalmPluto.createContext(uri);
        global tx, rx       = AdalmPluto.findTRXDevices(ctx);
        global txc, rxc     = AdalmPluto.findTRXChannels(ctx);
        global txloc, rxloc = AdalmPluto.findLoChannels(ctx);
        global txi, txq     = AdalmPluto.findIQChannels(tx, "voltage0", "voltage1", true);
        global rxi, rxq     = AdalmPluto.findIQChannels(rx, "voltage0", "voltage1", false);
        global channels     = [rxc, rxloc, rxi, rxq, txc, txloc, txi, txq];
    catch
        @error "Could not get a valid uri or context or channels, skipping the remaining tests.";
        C_iio_context_destroy(ctx);
        return;
    end

    # uncomment the following section to show all the available attributes and properties
    #  for channel in channels
        #  @show channel;
        #  nb_attrs = C_iio_channel_get_attrs_count(channel);
        #  for idx = 0:nb_attrs-1
            #  @show attr = C_iio_channel_get_attr(channel, UInt32(idx));
            #  @show C_iio_channel_attr_read(channel, attr);
            #  @show C_iio_channel_attr_read_bool(channel, attr);
            #  @show C_iio_channel_attr_read_double(channel, attr);
            #  @show C_iio_channel_attr_read_longlong(channel, attr);
            #  @show C_iio_channel_attr_get_filename(channel, attr);
            #  @show C_iio_channel_get_device(channel);
            #  @show C_iio_channel_get_id(channel);
            #  @show C_iio_channel_get_type(channel);
            #  @show C_iio_channel_get_name(channel);
            #  @show C_iio_channel_get_modifier(channel);
            #  @show C_iio_channel_is_enabled(channel);
            #  @show C_iio_channel_is_output(channel);
            #  @show C_iio_channel_is_scan_element(channel);
        #  end
    #  end

    @testset "Channel properties" begin
        #  C_iio_channel_get_device (channel::Ptr, …)
        @test C_iio_channel_get_device(rxc) != C_NULL;
        #  C_iio_channel_get_id (channel::Ptr, …)
        @test C_iio_channel_get_id(rxc) == "voltage0";
        #  C_iio_channel_get_modifier (channel::Ptr, …)
        @test C_iio_channel_get_modifier(rxc) == AdalmPluto.libIIO_jl.IIO_NO_MOD;
        #  C_iio_channel_get_name (channel::Ptr, …)
        @test C_iio_channel_get_name(rxloc) == "RX_LO";
        #  C_iio_channel_get_type (channel::Ptr, …)
        @test C_iio_channel_get_type(rxc) == AdalmPluto.libIIO_jl.IIO_VOLTAGE;
        #  C_iio_channel_is_output (channel::Ptr, …)
        @test C_iio_channel_is_output(rxc) == false;
        @test C_iio_channel_is_output(txc) == true;
        #  C_iio_channel_is_scan_element (channel::Ptr, …)
        @test C_iio_channel_is_scan_element(rxc) == false;
        @test C_iio_channel_is_scan_element(rxi) == true;

        #  C_iio_channel_disable (channel::Ptr, …)
        #  C_iio_channel_enable (channel::Ptr, …)
        #  C_iio_channel_is_enabled (channel::Ptr, …)
        enabled = C_iio_channel_is_enabled(rxi);
        if enabled
            @test C_iio_channel_disable(rxi) === nothing;
            @test C_iio_channel_is_enabled(rxi) == false;
            @test C_iio_channel_enable(rxi) === nothing;
            @test C_iio_channel_is_enabled(rxi) == true;
        else
            @test C_iio_channel_enable(rxi) === nothing;
            @test C_iio_channel_is_enabled(rxi) == true;
            @test C_iio_channel_disable(rxi) === nothing;
            @test C_iio_channel_is_enabled(rxi) == false;
        end

        saved_data_ptr = C_iio_channel_get_data(rxc);
        test_data = b"Test data\0";
        #  C_iio_channel_set_data (channel::Ptr, …)
        @test C_iio_channel_set_data(rxc, Ptr{Cvoid}(pointer(test_data))) === nothing;
        #  C_iio_channel_get_data (channel::Ptr, …)
        @test C_iio_channel_get_data(rxc) == Ptr{Cvoid}(pointer(test_data));
        C_iio_channel_set_data(rxc, saved_data_ptr);
    end

    @testset "Channel attributes" begin
        #  C_iio_channel_get_attrs_count (channel::Ptr, …)
        @test (global nb_attrs = C_iio_channel_get_attrs_count(rxc)) > 0;

        if nb_attrs < 1
            @warn "No channel attributes, skipping the related tests";
        else
            #  C_iio_channel_get_attr (channel::Ptr, …)
            @test (global first_attr = C_iio_channel_get_attr(rxc, UInt32(0))) != "";
            #  C_iio_channel_find_attr (channel::Ptr, …)
            @test C_iio_channel_find_attr(rxc, first_attr) == first_attr;
            #  C_iio_channel_attr_get_filename (channel::Ptr, …)
            @test C_iio_channel_attr_get_filename(rxc, "hardwaregain") == "in_voltage0_hardwaregain";

            attr = "gain_control_mode";
            #  C_iio_channel_attr_read (channel::Ptr, …)
            @test C_iio_channel_attr_read(rxc, attr)[1] > 0;
            @test C_iio_channel_attr_read(rxc, "dummy")[1] < 0;
            saved_value = C_iio_channel_attr_read(rxc, attr)[2];
            #  C_iio_channel_attr_write (channel::Ptr, …)
            @test C_iio_channel_attr_write(rxc, attr, "manual") > 0 && C_iio_channel_attr_read(rxc, attr)[2] == "manual";
            @test C_iio_channel_attr_write(rxc, attr, "slow_attack") > 0 && C_iio_channel_attr_read(rxc, attr)[2] == "slow_attack";
            new_gainmode = b"manual\0";
            #  C_iio_channel_attr_write_raw (channel::Ptr, …)
            @test (C_iio_channel_attr_write_raw(rxc, attr, Ptr{Cvoid}(pointer(new_gainmode)), UInt64(sizeof(new_gainmode))) > 0
                && C_iio_channel_attr_read(rxc, attr)[2] == "manual");
            # put back the original value
            C_iio_channel_attr_write(rxc, attr, saved_value);

            #  C_iio_channel_attr_read_bool (channel::Ptr, …)
            @test C_iio_channel_attr_read_bool(rxc, "filter_fir_en")[1] == 0;
            ## Doesn't work, don't know why
            #  saved_fir_en = C_iio_channel_attr_read_bool(rxc, "filter_fir_en")[2];
            #  @test (C_iio_channel_attr_write_bool(rxc, "filter_fir_en", !saved_fir_en) == 0
            #      && C_iio_channel_attr_read_bool(rxc, "filter_fir_en")[2] == !saved_fir_en);
            ##
            #  C_iio_channel_attr_write_bool (channel::Ptr, …)
            phy = C_iio_context_find_device(ctx, AdalmPluto.PHY_DEVICE_NAME);
            r, c, a = C_iio_device_identify_filename(phy, "in_out_voltage_filter_fir_en");
            saved_value = C_iio_channel_attr_read_bool(c, a)[2];
            @test_skip (C_iio_channel_attr_write_bool(c, a, !saved_value) == 0
                   & C_iio_channel_attr_read_bool(c, a)[2] == !saved_value);
            # put back the original value
            C_iio_channel_attr_write_bool(c, a, saved_value);

            #  C_iio_channel_attr_read_double (channel::Ptr, …)
            @test C_iio_channel_attr_read_double(txc, "hardwaregain")[1] == 0;
            saved_value = C_iio_channel_attr_read_double(txc, "hardwaregain")[2];
            #  C_iio_channel_attr_write_double (channel::Ptr, …)
            # assuming saved_gain > minimum available gain
            @test (C_iio_channel_attr_write_double(txc, "hardwaregain", saved_value - 0.25) == 0
                && C_iio_channel_attr_read_double(txc, "hardwaregain")[2] == saved_value - 0.25);
            # put back the original value
            C_iio_channel_attr_write_double(txc, "hardwaregain", saved_value);

            #  C_iio_channel_attr_read_longlong (channel::Ptr, …)
            @test C_iio_channel_attr_read_longlong(rxc, "rf_bandwidth")[1] == 0;
            saved_value = C_iio_channel_attr_read_longlong(rxc, "rf_bandwidth")[2];
            #  C_iio_channel_attr_write_longlong (channel::Ptr, …)
            @test (C_iio_channel_attr_write_longlong(rxc, "rf_bandwidth", 200000)[1] == 0
                && C_iio_channel_attr_read_longlong(rxc, "rf_bandwidth")[2] == 200000);
            sleep(1)
            @test (C_iio_channel_attr_write_longlong(rxc, "rf_bandwidth", 4000000)[1] == 0)

           # @show C_iio_channel_attr_write_longlong(rxc, "rf_bandwidth", 4000000)
           @show (C_iio_channel_attr_read_longlong(rxc, "rf_bandwidth") );
            # put back the original value
            C_iio_channel_attr_write_longlong(rxc, "rf_bandwidth", saved_value);
        end
    end


    # Those functions are not yet implemented as they need either data using the correct format or a function pointer.
    # C_iio_channel_read_raw, C_iio_channel_write, and C_iio_channel_write_raw also need a buffer initialized.
    @testset "Placeholders" begin
        #  C_iio_channel_attr_read_all
        @test_skip C_iio_channel_attr_read_all() === nothing;
        #  C_iio_channel_attr_write_all
        @test_skip C_iio_channel_attr_write_all() === nothing;
        #  C_iio_channel_read_raw
        @test_skip C_iio_channel_read_raw() === nothing;
        #  C_iio_channel_write
        @test_skip C_iio_channel_write() === nothing;
        #  C_iio_channel_write_raw
        @test_skip C_iio_channel_write_raw() === nothing;
    end

    #  C_iio_channel_read! (chn::Ptr, …)
    # This function is not tested here as a working buffer is needed

    C_iio_context_destroy(ctx);
end
