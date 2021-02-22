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
Records a 10 seconds FM sample in (pwd=.../AdalmPluto/test)/samples/from_pluto.wav
Returns 0 if no error happens.
Correct functioning has to be verified manually by listening to the generated WAV file.
"""
function test_fmTenSeconds(carrierFreq::Int64 = Int64(96e6), samplingRate::Int64 = Int64(2.8e6), doPlot = false)
    dirpath = joinpath(pwd(), "samples");
    filepath = joinpath(dirpath, "from_pluto.wav");
    if !isdir(dirpath)
        mkdir(dirpath);
    end

    audioRendering = 48e3;
    # initialize audio file with a beep
    t = 0.0:1/audioRendering:prevfloat(1.0);
    f = 1e3;
    y = sin.(2pi * f * t) * 0.1;
    wavwrite(y, joinpath(pwd(), "samples", "from_pluto.wav"), Fs=audioRendering);

    # fm demodulation components
    quadRate = 384e3;
    decim1 = Int(samplingRate ÷ quadRate);
    h1 = digitalfilter(Lowpass(44100, fs=samplingRate), FIRWindow(hamming(128)));
    decim2 = Int(quadRate ÷ audioRendering);
    h2 = digitalfilter(Lowpass(Int(audioRendering ÷ 2), fs=quadRate), FIRWindow(hamming(128)));

    try
        # init pluto
        global pluto = openPluto(carrierFreq, samplingRate, 64);

        @show AdalmPluto.ad9361_baseband_auto_rate(C_iio_context_find_device(pluto.ctx, "ad9361-phy"), Int(samplingRate));

        # demodulation
        global wavSamples = zeros(Float32, Int(11*audioRendering));
        progress = Progress(Int(10*audioRendering), barglyphs=BarGlyphs("[=> ]"));
        wavSmpCount = 0;

        rawSamples = zeros(ComplexF32, 1024*1024);
        while(wavSmpCount < 10*audioRendering)
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

        # write(joinpath(pwd(), "samples", "raw_from_pluto"), reinterpret(Char, rawSamples));
    catch e
        # free allocated C stuff (needed to access pluto again)
        AdalmPluto.close(pluto);
        rethrow(e);
    end

    AdalmPluto.close(pluto);

    if doPlot
        plotly();
        Plots.PlotlyBackend();
        wavPeriodogram = periodogram(wavSamples, fs=audioRendering);
        wavTimePlot = plot(0:length(wavSamples)-1, wavSamples);
        wavSpecPlot = plot(freq(wavPeriodogram), power(wavPeriodogram));
        display(plot(wavTimePlot, wavSpecPlot, layout=(2,1)));
    end
    #  println("press any key to continue"); readline();
    return 0;
end

"""
Tests that the FM demodulation chain is working correctly.
Takes a dirpath/filename and creates dirpath/from_filename.wav
Returns 0 is no error happens.
"""
function test_fmFromFile(rawfilePath::AbstractString, samplingRate=2.8e6)
    path = splitpath(rawfilePath);
    wavfilePath = joinpath(path[1:end-1]..., "from_" * path[end] * ".wav");
    samples = read(rawfilePath);
    samples = reinterpret(Complex{Float32},  samples);

    audioRendering = 48e3;
    # adds a beep at the beginning of the audio file
    t = 0.0:1/audioRendering:prevfloat(1.0);
    f = 1e3;
    y = sin.(2pi * f * t) * 0.1;
    wavwrite(y, wavfilePath, Fs=audioRendering);

    # first filter to only keep the radio band
    h        = digitalfilter(Lowpass(44100, fs = samplingRate), FIRWindow(hamming(128)));
    samples  = filt(h, samples);
    decim    = Int(samplingRate ÷ quadRate);
    samples  = samples[1:decim:end];
    # intermediate result
    #  write(joinpath(path[1:end-1]..., "filtered_" * path[end]), reinterpret(Char, samples));
    # fm demodulation
    samples  = fmDemod(samples);
    # audio filtering
    quadRate = 384e3; # quadrature rate ≡ samplingRate
    h        = digitalfilter(Lowpass(Int(audioRendering ÷ 2), fs = quadRate), FIRWindow(hamming(128)));
    samples  = filt(h, samples);
    decim    = Int(quadRate ÷ audioRendering);
    wavSmp   = samples[1:decim:end];

    wavappend(wavSmp, wavfilePath);

    # always returns 0, manual check of the audio file is needed
    return 0;
end
