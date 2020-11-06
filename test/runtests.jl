using PlutoSDR;
using Test;
using Plots;
#  using GetSpectrum;

function test_once()
    txCfg = PlutoSDR.streamCfg("A", 4e6, 4e6, 105.5e6);
    rxCfg = PlutoSDR.streamCfg("A_BALANCED", 4e6, 4e6, 105.5e6);

    try
        pluto = PlutoSDR.openPluto(txCfg, rxCfg);
        sig, res = PlutoSDR.recv(pluto);
        PlutoSDR.closePluto(pluto);
    catch e
        rethrow(e)
        return 1;
    end

    return 0;
end

@testset "PlutoSDR.jl" begin
    # Write your tests here.
    @test test_once() == 0;
end
