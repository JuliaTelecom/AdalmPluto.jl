using Test;

using AdalmPluto;

@testset "libIIO/context.jl" begin
    # disable errors on null pointers
    toggleNoAssertions(true);

    # Need iiod running for those
    # C_iio_create_default_context
    @test_skip C_iio_create_default_context() != C_NULL;
    # C_iio_create_local_context
    @test_skip C_iio_create_local_context() != C_NULL;
    # C_iio_create_network_context
    @test_skip C_iio_create_network_context("127.0.0.1") != C_NULL;

    try
        global uri = AdalmPluto.scan("usb", 1, false)[1];
    catch
        println(exception)
        @error "Could not get a valid uri, skipping the remaining tests"; return;
    end

    # C_iio_create_context_from_uri
    @test (global context = C_iio_create_context_from_uri(uri)) != C_NULL;

    if context == C_NULL
        @error "Could not create a context, skipping the remaining tests"; return;
    end

    @testset "Context description" begin
        # C_iio_context_get_name
        @test C_iio_context_get_name(context) != "";
        # C_iio_context_get_description
        @test C_iio_context_get_description(context) != "";
        # C_iio_context_get_version
        ctx =  C_iio_context_get_version(context) 
        @test ctx[3] > 17 
        # @test (C_iio_context_get_version(context) == (0, 0, 17, "v0.17  ") ||    C_iio_context_get_version(context) == (0, 0, 18, "v0.18  ")); 
    end


    @testset "Context devices" begin
        # C_iio_context_get_devices_count
        @test (global nb_devices = C_iio_context_get_devices_count(context)) > 0;

        if nb_devices < 1
            @warn "Could not find devices in the context, skipping related tests";
        else
            # C_iio_context_find_device
            @test C_iio_context_find_device(context, "dummy") == C_NULL;
            @test C_iio_context_find_device(context, "cf-ad9361-lpc") != C_NULL;

            # C_iio_context_get_device
            @test C_iio_context_get_device(context, UInt32(666)) == C_NULL;
            @test C_iio_context_get_device(context, UInt32(0)) != C_NULL;
        end

    end

    @testset "Context attrs" begin
        # C_iio_context_get_attrs_count
        @test (global nb_attrs = C_iio_context_get_attrs_count(context)) > 0

        if nb_attrs < 1
            @warn "Could not find context specific attributes, skipping related tests";
        else
            # NOTE : Specific the radio used for the test, this test failing can be normal.
            # C_iio_context_get_attr
            flag1 = C_iio_context_get_attr(context, UInt32(0)) ==  (0, "hw_model", "Analog Devices PlutoSDR Rev.B (Z7010-AD9364)") 
            flag2 = C_iio_context_get_attr(context, UInt32(0)) ==  (0, "hw_model", "Analog Devices PlutoSDR Rev.B (Z7010-AD9363A)") 
            @test flag1 || flag2
            # C_iio_context_get_attr_value

            flag1 =  C_iio_context_get_attr_value(context, "hw_model") ==   (0, "hw_model", "Analog Devices PlutoSDR Rev.B (Z7010-AD9364)") 
            flag3 =  C_iio_context_get_attr_value(context, "hw_model") ==   ("Analog Devices PlutoSDR Rev.B (Z7010-AD9364)") 
            @test flag1 || flag2 || flag3
        end

    end


    # C_iio_context_set_timeout
    @test C_iio_context_set_timeout(context, UInt32(0)) == 0;

    @testset "Context xml & clone" begin
        # C_iio_context_get_xml
        @test (global xml = C_iio_context_get_xml(context)) != "";
        # C_iio_context_destroy
        @test C_iio_context_destroy(context) === nothing;
        # C_iio_create_xml_context
        # C_iio_create_xml_context_mem
        @test (global context = C_iio_create_xml_context_mem(xml, UInt64(length(xml)))) != C_NULL;
        # C_iio_context_clone
        @test (global clone = C_iio_context_clone(context)) != C_NULL;
        C_iio_context_destroy(clone);
    end

    C_iio_context_destroy(context);
end
