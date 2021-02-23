#  using PortAudio;
using FileIO;
using DSP;
using WAV;
using ProgressMeter;

using AdalmPluto;


"""
FM demodulation
"""
function fmDemod(sig)
    out = zeros(Float32,length(sig));
    @inbounds @simd for n ∈ (1:length(sig)-1)
        out[n+1] = angle(sig[n+1]*conj(sig[n]));
    end
    return out;
end

"""
Records a `seconds` long FM sample in (pwd=.../AdalmPluto/examples)/samples/fm.wav
Returns 0 if no error happens.
"""
function fmRecord(seconds, carrierFreq::Int64 = Int64(96e6), samplingRate::Int64 = Int64(2.8e6))
    if last(split(pwd(), "/")) == "AdalmPluto.jl"; cd("./examples"); end;
    dirpath = joinpath(pwd(), "samples");
    filepath = joinpath(dirpath, "fm.wav");
    if !isdir(dirpath)
        mkdir(dirpath);
    end

    audioRendering = 48e3;
    # initialize audio file with a beep
    t = 0.0:1/audioRendering:prevfloat(1.0);
    f = 1e3;
    y = sin.(2pi * f * t) * 0.1;
    wavwrite(y, joinpath(pwd(), "samples", "fm.wav"), Fs=audioRendering);

    # fm demodulation components
    quadRate = 384e3;
    decim1 = Int(samplingRate ÷ quadRate);
    h1 = digitalfilter(Lowpass(44100, fs=samplingRate), FIRWindow(hamming(128)));
    decim2 = Int(quadRate ÷ audioRendering);
    h2 = digitalfilter(Lowpass(Int(audioRendering ÷ 2), fs=quadRate), FIRWindow(hamming(128)));

    try
        # init pluto
        global pluto = openPluto(carrierFreq, samplingRate, 64);

        AdalmPluto.ad9361_baseband_auto_rate(C_iio_context_find_device(pluto.ctx, "ad9361-phy"), Int(samplingRate));

        # demodulation
        rawSamples = zeros(ComplexF32, 1024*1024);
        wavSmpCount = 0;
        progress = Progress(Int(seconds*audioRendering), barglyphs=BarGlyphs("[=> ]"));
        while(wavSmpCount < seconds*audioRendering)
            n = recv!(rawSamples, pluto);
            samples = filt(h1, rawSamples);
            samples = samples[1+64:decim1:end-64];
            samples = fmDemod(samples);
            samples = filt(h2, samples);
            wavSamples = samples[1+64:decim2:end-64];
            wavSmpCount += length(wavSamples);
            update!(progress, Int(wavSmpCount));
            wavappend(wavSamples, filepath);
        end
        println(""); # progress bar fix
    catch e
        # free allocated C stuff (needed to access pluto again)
        AdalmPluto.close(pluto);
        rethrow(e);
    end

    AdalmPluto.close(pluto);

    return 0;
end

fmRecord(10);
