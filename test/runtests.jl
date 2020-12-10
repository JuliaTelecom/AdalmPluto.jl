using PlutoSDR;
using Test;
using Plots;

include("fm.jl");

function test_recvOnce()
    txCfg = PlutoSDR.ChannelCfg("A", 4e6, 4e6, 105.5e6);
    rxCfg = PlutoSDR.ChannelCfg("A_BALANCED", 4e6, 4e6, 105.5e6);

    try
        pluto = PlutoSDR.open(txCfg, rxCfg);
        nbytes, complex_samples, raw_i, raw_q = PlutoSDR.recv(pluto);
        PlutoSDR.close(pluto);
    catch e
        #  rethrow(e)
        return 1;
    end

    return 0;
end

@testset "PlutoSDR.jl" begin
    @test test_recvOnce() == 0;
    # TODO: test at least all the exported functions
end

@testset "Audio" begin
    @test_skip test_fmFromFile(joinpath(pwd(), "test", "samples", "raw_samples")) == 0;
    @test test_fmTenSeconds() == 0;
end
