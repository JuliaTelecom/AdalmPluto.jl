using AdalmPluto;
using Test;

#  include("fm.jl");
#  inlucde("test_AdalmPluto.jl");
#  include("test_buffer.jl");
#  include("test_debug.jl");
#  include("test_structures.jl");
@testset "libIIO_jl" begin
    include("test_toplevel.jl");
    include("test_scan.jl");
    include("test_context.jl");
    include("test_device.jl");
    include("test_channel.jl");
end

function test_recvOnce()
    try
        radio = openPluto(Int64(105.5e6), Int64(4e6), 60);
        samples = recv(radio, 2*1024*1024 + 1);
        AdalmPluto.close(radio);
    catch e
        rethrow(e)
    end

    return 0;
end

#  @testset "AdalmPluto.jl" begin
    #  @test test_recvOnce() == 0;
    #  # TODO: test at least all the exported functions
#  end
#
#  @testset "Audio" begin
    #  @test_skip test_fmFromFile(joinpath(pwd(), "test", "samples", "raw_samples")) == 0;
    #  @test test_fmTenSeconds() == 0;
#  end
