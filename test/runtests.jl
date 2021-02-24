using Test;

using AdalmPluto;

@testset "libIIO_jl" begin
    include("test_toplevel.jl");
    include("test_scan.jl");
    include("test_context.jl");
    include("test_device.jl");
    include("test_channel.jl");
    include("test_buffer.jl");
    #  include("test_debug.jl");
end

@testset "AdalmPluto" begin
    #  openPluto
    #  openPluto (txCfg::ChannelCfg, …)
    global pluto = openPluto(Int64(96e6), Int64(2.8e6), 64; bufferSize=UInt64(1024), bandwidth=Int(25e6));
    # Functions called by openPluto :
    #   - updateGain! (pluto::PlutoSDR, …)
    #   - updateGainMode! (pluto::PlutoSDR, …)
    #   - updateEffectiveCfg! (trx::Union, …)

    # Verification of the correct initalization of the fields
    ## PlutoSDR.PlutoTx.txWrapper
    @test pluto.tx.iio.tx     != C_NULL;
    @test pluto.tx.iio.tx0_i  != C_NULL;
    @test pluto.tx.iio.tx0_q  != C_NULL;
    @test pluto.tx.iio.chn    != C_NULL;
    @test pluto.tx.iio.chn_lo != C_NULL;
    ## PlutoSDR.PlutoRx.rxWrapper
    @test pluto.rx.iio.rx     != C_NULL;
    @test pluto.rx.iio.rx0_i  != C_NULL;
    @test pluto.rx.iio.rx0_q  != C_NULL;
    @test pluto.rx.iio.chn    != C_NULL;
    @test pluto.rx.iio.chn_lo != C_NULL;

    ## PlutoSDR.PlutoTx.ChannelCfg
    @test pluto.tx.cfg.rfport       == "A";
    @test pluto.tx.cfg.bandwidth    == 25000000;
    @test pluto.tx.cfg.samplingRate == Int64(2.8e6);
    @test pluto.tx.cfg.carrierFreq  == Int64(96e6);
    ## PlutoSDR.PlutoRx.ChannelCfg
    @test pluto.rx.cfg.rfport       == "A_BALANCED";
    @test pluto.rx.cfg.bandwidth    == 25000000;
    @test pluto.rx.cfg.samplingRate == Int64(2.8e6);
    @test pluto.rx.cfg.carrierFreq  == Int64(96e6);

    ## PlutoSDR.PlutoTx.IIO_Buffer
    @test pluto.tx.buf.C_ptr         != C_NULL;
    @test pluto.tx.buf.C_size        == 1024;
    @test pluto.tx.buf.C_sample_size > 0;
    @test pluto.tx.buf.C_first       != C_NULL;
    @test pluto.tx.buf.C_last        != C_NULL;
    @test pluto.tx.buf.C_step        > 0;
    ## PlutoSDR.PlutoTx.IIO_Buffer
    @test pluto.rx.buf.C_ptr         != C_NULL;
    @test pluto.rx.buf.C_size        == 1024;
    @test pluto.rx.buf.C_sample_size > 0;
    @test pluto.rx.buf.C_first       != C_NULL;
    @test pluto.rx.buf.C_last        != C_NULL;
    @test pluto.rx.buf.C_step        > 0;

    ## PlutoSDR.PlutoTx
    @test isapprox(pluto.tx.effectiveSamplingRate, pluto.tx.cfg.samplingRate; atol=5);
    @test isapprox(pluto.tx.effectiveCarrierFreq, pluto.tx.cfg.carrierFreq; atol=5);
    ## PlutoSDR.PlutoRx
    @test isapprox(pluto.rx.effectiveSamplingRate, pluto.rx.cfg.samplingRate; atol=5);
    @test isapprox(pluto.rx.effectiveCarrierFreq, pluto.rx.cfg.carrierFreq; atol=5);

    #  updateBandwidth! (pluto, …)
    @test updateBandwidth!(pluto, Int64(20e6); doLog=false) == 0;
    @test pluto.tx.cfg.bandwidth == Int64(20e6);
    @test C_iio_channel_attr_read_longlong(pluto.tx.iio.chn, "rf_bandwidth") == (0, Int64(20e6));
    @test pluto.rx.cfg.bandwidth == Int64(20e6);
    @test C_iio_channel_attr_read_longlong(pluto.rx.iio.chn, "rf_bandwidth") == (0, Int64(20e6));

    #  updateSamplingRate! (pluto::PlutoSDR, …)
    @test updateSamplingRate!(pluto, Int64(5e6); doLog=false) == 0;
    # Tx
    @test pluto.tx.cfg.samplingRate == Int64(5e6);
    @test isapprox(pluto.tx.effectiveSamplingRate, pluto.tx.cfg.samplingRate; atol=5);
    # Tx
    @test pluto.rx.cfg.samplingRate == Int64(5e6);
    @test isapprox(pluto.rx.effectiveSamplingRate, pluto.rx.cfg.samplingRate; atol=5);

    #  updateCarrierFreq! (pluto::PlutoSDR, …)
    @test updateCarrierFreq!(pluto, Int64(105.5e6); doLog=false) == 0;
    # Tx
    @test pluto.tx.cfg.carrierFreq == Int64(105.5e6);
    @test isapprox(pluto.tx.effectiveCarrierFreq, pluto.tx.cfg.carrierFreq; atol=5);
    # Rx
    @test pluto.rx.cfg.carrierFreq == Int64(105.5e6);
    @test isapprox(pluto.rx.effectiveCarrierFreq, pluto.rx.cfg.carrierFreq; atol=5);

    sig = zeros(ComplexF32, 3000);
    #  recv (pluto::PlutoSDR, …)
    #  recv! (sig::Array, …)
    @test recv!(sig, pluto) == length(sig);
    @test sig[1] != 0 && sig[end] != 0; # very unlikely to have those equal 0
    @test pluto.rx.buf.nb_samples == 3072 - length(sig);

    #  Base.close (pluto::PlutoSDR, …)
    close(pluto);
    @test pluto.released = true;
    @test pluto.tx.released = true;
    @test pluto.rx.released = true;
end
