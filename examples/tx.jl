using AdalmPluto 
using FFTW


function normalizePower!(buffer)
    maxI = (buffer |> real .|> abs |> maximum) * 1.05 # Max scale + backoff of I path
    maxQ = (buffer |> imag .|> abs |> maximum) * 1.05 # Max scale + backoff of Q path
    buffer .= real(buffer) ./ maxI + 1im*imag(buffer) / maxQ 
end

function tx()

    # ----------------------------------------------------
    # --- Radio 
    # ---------------------------------------------------- 
    carrierFreq		= 700e6
    samplingRate    = 4e6;

    # ----------------------------------------------------
    # --- Opening radio 
    # ---------------------------------------------------- 
    # global pluto = openPluto(Int(carrierFreq), Int(samplingRate), Int(40),bufferSize=UInt(2048));
    global pluto = openPluto(Int(carrierFreq), Int(samplingRate), Int(40));

    # ----------------------------------------------------
    # --- Create buffer
    # ---------------------------------------------------- 
    f_c     = 1e6
    nbSamples = 2048
    buffer  = 0.9.*[exp.(2im * π * f_c / samplingRate * n)  for n ∈ (0:nbSamples-1)];
    buffer  = convert.(Complex{Cfloat},buffer);
    


    # --- Emulate a simple OFDM signal
    nS = 1024
    bData = ComplexF32.( (rand([0 1],nS) +1im*(rand([0 1],nS)))/sqrt(2))
    buffer = zeros(ComplexF32,nbSamples)
    buffer[1:nS÷2] = bData[1:nS÷2]
    buffer[end-nS÷2+1:end] = bData[1+nS÷2:end]
    buffer = ifft(buffer)
    normalizePower!(buffer)

    # ----------------------------------------------------
    # --- Send buffer
    # ---------------------------------------------------- 
    cnt = 0
    try 
        while (true)
            n = send(pluto,buffer)
            cnt += n
            yield()
        end
    catch exception 
        @info "Get interruption, close radio after $cnt elements "
        close(pluto)
        rethrow(exception)
    end
    close(radio)
    return cnt
end




