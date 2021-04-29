using Test;

using AdalmPluto;

@testset "libIIO/toplevel.jl" begin
    # disable the assertions
    toggleNoAssertions(true);

    # C_iio_library_get_version
     # @test C_iio_library_get_version() == (0, 21, "565bf68");

    # C_iio_get_backends_count
    @test C_iio_get_backends_count() > 0;

    # C_iio_has_backend
    @test C_iio_has_backend("usb") == true;
    @test C_iio_has_backend("dummy") == false;

    # C_iio_get_backend
    @test C_iio_get_backend(UInt32(0)) != "";
    @test C_iio_get_backend(UInt32(666)) == "";

    # C_iio_strerror
    @test C_iio_strerror(1) == "Operation not permitted";
end
