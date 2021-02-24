using ProgressMeter;
using UnicodePlots;

using AdalmPluto;

function bench_refill(radio::PlutoSDR, rate::Int)
    updateSamplingRate!(radio, rate; doLog=false);

    to_refill = 2 * rate;
    refilled = 0;
    start = time();
    while refilled < to_refill
        C_iio_buffer_refill(radio.rx.buf.C_ptr);
        refilled += radio.rx.buf.C_size;
    end
    stop = time();

    refill_rate = to_refill / (stop - start);

    return refill_rate;
end

function bench_refill_read(radio::PlutoSDR, rate::Int)
    updateSamplingRate!(radio, rate; doLog=false);

    to_read = 2 * rate;
    read = 0;
    start = time();
    while read < to_read
        C_iio_buffer_refill(radio.rx.buf.C_ptr);
        C_iio_channel_read!(radio.rx.iio.rx0_i, radio.rx.buf.C_ptr, radio.rx.buf.i_raw_samples);
        C_iio_channel_read!(radio.rx.iio.rx0_q, radio.rx.buf.C_ptr, radio.rx.buf.q_raw_samples);
        read += radio.rx.buf.C_size;
    end
    stop = time();

    reading_rate = to_read / (stop - start);

    return reading_rate;
end

function bench_refillJuliaBufferRX(radio::PlutoSDR, rate::Int)
    updateSamplingRate!(radio, rate; doLog=false);

    to_refill = 2 * rate;
    refilled = 0;
    start = time();
    while refilled < to_refill
        AdalmPluto.refillJuliaBufferRX(radio);
        refilled += radio.rx.buf.C_size;
    end
    stop = time();

    refill_rate = to_refill / (stop - start);

    return refill_rate;
end

function bench_recv(radio::PlutoSDR, samplingRate::Int)
    updateSamplingRate!(radio, samplingRate; doLog=false);

    # 2 seconds (if effective rate == radio rate)
    to_process = 2 * samplingRate;
    processed = 0;
    sig = zeros(ComplexF32, radio.rx.buf.C_size); # C_size is in samples
    start = time();
    while processed < to_process
        received = recv!(sig, radio);
        processed += received;
    end
    stop = time();

    radio_rate = radio.rx.effectiveSamplingRate;  # effective configuration (≠ effective rate)
    effective_rate = to_process / (stop - start);

    return radio_rate, effective_rate;
end


function bench_all(mode=:rx, doPlot=true)
    carrierFreq::Int = 100e6;
    gain = 64;
    bandwidth::Int = 20e6;

    rates           = Int.(6e5:1e6:5e7);
    radio_rates     = zeros(Int, length(rates));
    effective_rates = zeros(Float64, length(rates));

    radio = openPluto(carrierFreq, Int(1e6), gain; bandwidth=bandwidth);
    progress = Progress(length(rates), barglyphs=BarGlyphs("[=> ]"));
    if mode == :rx
        refill_rates    = zeros(Float64, length(rates));
        read_rates      = zeros(Float64, length(rates));
        refillJL_rates  = zeros(Float64, length(rates));
        for (idx, rate) in enumerate(rates)
            # benches
            refill_rate                = bench_refill(radio, rate);
            read_rate                  = bench_refill_read(radio, rate);
            refillJL_rate              = bench_refillJuliaBufferRX(radio, rate);
            radio_rate, effective_rate = bench_recv(radio, rate);
            # store values
            refill_rates[idx]    = refill_rate;
            read_rates[idx]      = read_rate;
            refillJL_rates[idx]  = refillJL_rate;
            radio_rates[idx]     = radio_rate;
            effective_rates[idx] = effective_rate;

            # progress bar
            update!(progress, idx);
        end
        res = Dict{Symbol, Array{Float64}}();
        res[:refill]    = refill_rates;
        res[:read]      = read_rates;
        res[:refillJL]  = refillJL_rates;
        res[:effective] = effective_rates;
        res[:cfg]       = radio_rates;
    elseif mode == :tx
        # placeholder
    end
    println("");

    close(radio);

    if doPlot
        plt = lineplot(rates, rates; width=2*length(rates), height=length(rates), name="desired");
        lineplot!(plt, rates, refill_rates; name="C_iio_buffer_refill");
        lineplot!(plt, rates, read_rates; name="refill + C_iio_channel_read");
        #  lineplot!(plt, rates, refillJL_rates; name="refill + read + reinterpret");
        lineplot!(plt, rates, radio_rates; name="effective cfg");
        lineplot!(plt, rates, effective_rates; name="effective rate (recv!)");
        return plt, res;
    end

    return res;
end
