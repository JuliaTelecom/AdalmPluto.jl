using Test;

using AdalmPluto;

@testset "libIIO/scan.jl" begin
    # disable the assertions
    toggleNoAssertions(true);
    C_iio_has_backend("usb") || (@error "Library doesn't have the USB backend available. Skipping tests."; return;)

    @testset "Scan context" begin
        # C_iio_create_scan_context
        @test (global scan_context = C_iio_create_scan_context("usb")) != C_NULL;

        if scan_context == C_NULL
            @error "C_iio_create_scan_context failed, skipping the remaining tests";
            return;
        end

        info = Ref{Ptr{Ptr{iio_context_info}}}(0);

        # C_iio_scan_context_get_info_list
        @test (global nb_contexts = C_iio_scan_context_get_info_list(scan_context, info)) > 0;

        if nb_contexts < 0
            @error "C_iio_scan_context_get_info_list failed, skipping the remaining tests";
            C_iio_scan_context_destroy(scan_context);
            return;
        elseif nb_contexts == 0
            @warn "0 contexts found, skipping the remaining tests";
            C_iio_context_info_list_free(info[]);
            C_iio_scan_context_destroy(scan_context);
            return;
        end

        loaded_info = unsafe_load(info[], 1);

        # C_iio_context_info_get_description
        @test C_iio_context_info_get_description(loaded_info) != "";
        # C_iio_context_info_get_uri
        @test C_iio_context_info_get_uri(loaded_info) != "";

        # C_iio_context_info_list_free
        @test C_iio_context_info_list_free(info[]) === nothing;
        # C_iio_scan_context_destroy
        @test C_iio_scan_context_destroy(scan_context) === nothing;
    end

    @testset "Scan block" begin
        # C_iio_create_scan_block
        @test (global scan_block = C_iio_create_scan_block("usb")) != C_NULL;

        if scan_block == C_NULL
            @error "C_iio_create_scan_block failed, skipping the remaining tests.";
            return;
        end

        # C_iio_scan_block_scan
        @test (global nb_contexts = C_iio_scan_block_scan(scan_block)) > 0;

        if nb_contexts < 0
            @error "C_iio_scan_block_scan failed, skipping the remaining tests";
            C_iio_scan_block_destroy(scan_block);
            return;
        elseif nb_contexts == 0
            @warn "0 contexts found, skipping the remaining tests";
            C_iio_scan_block_destroy(scan_block);
            return;
        end
        # C_iio_scan_block_get_info
        @test C_iio_scan_block_get_info(scan_block, UInt32(0)) != C_NULL;

        # C_iio_scan_block_destroy
        @test C_iio_scan_block_destroy(scan_block) === nothing;
    end


end
