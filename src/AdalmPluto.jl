# --- All libIIO functions wrapped --- #

module AdalmPluto

using Reexport
using Printf

include("libIIO/libIIO.jl");
@reexport using .libIIO_jl;

# --- Functions taken from libad9361 --- #
include("libad9361.jl");
# --- utils --- #
include("utils.jl");

# --- struct exports --- #
export
    ChannelCfg,
    PlutoSDR
;

# --- functions exports --- #
export
    openPluto,
    close,
    recv,
    recv!,
    refillJuliaBufferRX,
    updateGain!,
    updateGainMode!,
    updateCarrierFreq!,
    updateSamplingRate!,
    updateBandwidth!
;

# constants
const TX_DEVICE_NAME  = "cf-ad9361-dds-core-lpc";
const RX_DEVICE_NAME  = "cf-ad9361-lpc";
const PHY_DEVICE_NAME = "ad9361-phy";

@enum GainMode begin
    MANUAL
    FAST_ATTACK
    SLOW_ATTACK
    HYBRID
    DEFAULT
end

# ------------------ #
# --- Structures --- #
# ------------------ #

# --- TRx structure --- #
mutable struct ChannelCfg
    rfport::String;
    bandwidth::Int64;
    samplingRate::Int64;
    carrierFreq::Int64;
end

mutable struct IIO_Buffer
    C_ptr::Ptr{iio_buffer};
    C_size::Csize_t;
    C_sample_size::Cssize_t;
    C_first::Ptr{Cuchar};
    C_last::Ptr{Cuchar};
    C_step::Cssize_t;
    i_raw_samples::Array{UInt8};
    q_raw_samples::Array{UInt8};
    samples::Array{ComplexF32};
    nb_samples::Int;
end

# --- Rx structures --- #
struct rxWrapper
    rx::Ptr{iio_device};
    rx0_i::Ptr{iio_channel};
    rx0_q::Ptr{iio_channel};
    chn::Ptr{iio_channel};
    chn_lo::Ptr{iio_channel};
end

mutable struct PlutoRx
    iio::rxWrapper;
    cfg::ChannelCfg;
    buf::IIO_Buffer;
    effectiveSamplingRate::Float64;
    effectiveCarrierFreq::Float64;
    released::Bool;
end

# --- Tx structures --- #
struct txWrapper
    tx::Ptr{iio_device};
    tx0_i::Ptr{iio_channel};
    tx0_q::Ptr{iio_channel};
    chn::Ptr{iio_channel};
    chn_lo::Ptr{iio_channel};
end

mutable struct PlutoTx
    iio::txWrapper;
    cfg::ChannelCfg;
    buf::IIO_Buffer;
    effectiveSamplingRate::Float64;
    effectiveCarrierFreq::Float64;
    released::Bool;
end

# --- final wrap --- #
"""
    PlutoSDR
    +-- ctx::Ptr{iio_context}
    |
    +-- tx::PlutoTx
    |   |
    |   +-- iio::txWrapper
    |   |   |
    |   |   +-- tx::Ptr{iio_device};
    |   |   +-- tx0_i::Ptr{iio_channel};
    |   |   +-- tx0_q::Ptr{iio_channel};
    |   |   +-- chn::Ptr{iio_channel};
    |   |   +-- chn_lo::Ptr{iio_channel};
    |   |
    |   +-- cfg::ChannelCfg
    |   |   |
    |   |   +-- rfport::String;
    |   |   +-- bandwidth::Int64;
    |   |   +-- samplingRate::Int64;
    |   |   +-- carrierFreq::Int64;
    |   |
    |   +-- buf::IIO_Buffer
    |   |   |
    |   |   +-- C_ptr::Ptr{iio_buffer};         |< Pointer to the C buffer
    |   |   +-- C_size::Csize_t;                |< Size of the C buffer in samples
    |   |   +-- C_sample_size::Cssize_t;        |< Size of a sample in the C buffer
    |   |   +-- C_first::Ptr{Cuchar};           |< Pointer to the first sample in the C buffer
    |   |   +-- C_last::Ptr{Cuchar};            |< Pointer to the last sample in the C buffer
    |   |   +-- C_step::Cssize_t;               |< Distance between to sample pointers in the C buffer
    |   |   +-- i_raw_samples::Array{UInt8}     |< Temporary buffer to store I bytes
    |   |   +-- q_raw_samples::Array{UInt8}     |< Temporary buffer to store Q bytes
    |   |   +-- samples::Array{ComplexF32}      |< Samples stored in a Julia array
    |   |   +-- nb_samples::Int                 |< Number of samples in the Julia array
    |   |
    |   +-- effectiveSamplingRate::Float64
    |   +-- effectiveCarrierFreq::Float64
    |   +-- released::Bool
    |
    +-- rx::PlutoRx
    |   |
    |   +-- iio::rxWrapper
    |   |   +-- rx::Ptr{iio_device};
    |   |   +-- rx0_i::Ptr{iio_channel};
    |   |   +-- rx0_q::Ptr{iio_channel};
    |   |   +-- chn::Ptr{iio_channel};
    |   |   +-- chn_lo::Ptr{iio_channel};
    |   |
    |   +-- cfg::ChannelCfg
    |   |   |
    |   |   +-- rfport::String;
    |   |   +-- bandwidth::Int64;
    |   |   +-- samplingRate::Int64;
    |   |   +-- carrierFreq::Int64;
    |   |
    |   +-- buf::IIO_Buffer
    |   |   |
    |   |   +-- C_ptr::Ptr{iio_buffer};         |< Pointer to the C buffer
    |   |   +-- C_size::Csize_t;                |< Size of the C buffer in samples
    |   |   +-- C_sample_size::Cssize_t;        |< Size of a sample in the C buffer
    |   |   +-- C_first::Ptr{Cuchar};           |< Pointer to the first sample in the C buffer
    |   |   +-- C_last::Ptr{Cuchar};            |< Pointer to the last sample in the C buffer
    |   |   +-- C_step::Cssize_t;               |< Distance between to sample pointers in the C buffer
    |   |   +-- i_raw_samples::Array{UInt8}     |< Temporary buffer to store I bytes
    |   |   +-- q_raw_samples::Array{UInt8}     |< Temporary buffer to store Q bytes
    |   |   +-- samples::Array{ComplexF32}      |< Samples decoded and stored in a Julia array
    |   |   +-- nb_samples::Int                 |< Number of samples available in the Julia array
    |   |
    |   +-- effectiveSamplingRate::Float64
    |   +-- effectiveCarrierFreq::Float64
    |   +-- released::Bool
    |
    +-- released::Bool
"""
mutable struct PlutoSDR
    ctx::Ptr{iio_context};
    tx::PlutoTx;
    rx::PlutoRx;
    released::Bool;
end

# ------------------------ #
# --- Helper functions --- #
# ------------------------ #
"""
    scan(backend[, infoIndex, doPrint])

Returns a device URI.

# Arguments
- `backend::String` : the backend to scan (local, xml, ip, usb).
- `infoIndex::Integer=1` : the device index.
- `doPrint::Bool=true` : toggles console printing of the uri.

# Returns
- `uri::String` : the device URI.

[C equivalent](https://analogdevicesinc.github.io/libiio/master/libiio/iio-monitor_8c-example.html#_a15)
"""
function scan(backend::String, deviceIndex=1, doPrint=true)
    # Check if backend is available and create scan context
    C_iio_has_backend(backend) || error("Specified backend $backend is not available");
    scan_context = C_iio_create_scan_context(backend);

    # Getting metadata from scan
    info = Ref{Ptr{Ptr{iio_context_info}}}(0);
    ret = C_iio_scan_context_get_info_list(scan_context, info);

    # Get usb address
    uri = "";
    if ret < 0
        C_iio_context_info_list_free(info[]);
        C_iio_scan_context_destroy(scan_context);
        error("iio_scan_context_get_info_list failed with error $ret :\n", C_iio_strerror(ret));
    elseif ret == 0
        (doPrint) && (@info "No $backend device found");
    else
        loaded_info = unsafe_load(info[], deviceIndex);
        description = C_iio_context_info_get_description(loaded_info);
        uri = C_iio_context_info_get_uri(loaded_info);
        (doPrint) && (@info "Found $ret device(s) with $backend backend.\nSelected $description [$uri]");
    end

    C_iio_context_info_list_free(info[]);
    C_iio_scan_context_destroy(scan_context);

    return uri;
end

"""
    createContext(uri)

Returns the `iio_context` corresponding the the provided uri. Throws an error if no devices are found in the context.

# Arguments
- `uri::String` : the radio URI to get the context from.

# Returns
- `context::Ptr{iio_context}` : the context for the given URI.
"""
function createContext(uri::String)
    context = C_iio_create_context_from_uri(uri);
    if(C_iio_context_get_devices_count(context) == 0) error("No device found in context from uri $uri"); end
    return context;
end


"""
    findTRXDevices(context)

Returns `txDevice::Ptr{iio_device}, rxDevice::Ptr{iio_device}` from the given context.

# Arguments
- `context::Ptr{iio_context}` : the IIO context to get the TX and RX devices from.

# Returns
- `txDevice::Ptr{iio_device}` : a pointer to the TX C iio_device structure.
- `rxDevice::Ptr{iio_device}` : a pointer to the RX C iio_device structure.
"""
function findTRXDevices(context::Ptr{iio_context})
    txDevice = C_iio_context_find_device(context, TX_DEVICE_NAME);
    rxDevice = C_iio_context_find_device(context, RX_DEVICE_NAME);
    return txDevice, rxDevice;
end

"""
    findTRXChannels(context[, txID, rxID])

Returns `txChannel::Ptr{iio_channel}, rxChannel::Ptr{iio_channel}` from the given context.

# Arguments
- `context::Ptr{iio_context}` : the context to get the channels from.
- `txID::Integer=0` : the tx channel number (ex : 0 for tx channel "voltage0").
- `rxID::Integer=0` : the rx channel number (ex : 0 for rx channel "voltage0").

# Returns
- `txChannel::Ptr{iio_channel}` : a pointer to the TX C iio_channel structure.
- `rxChannel::Ptr{iio_channel}` : a pointer to the RX C iio_channel structure.
"""
function findTRXChannels(context::Ptr{iio_context}, txID=0, rxID=0)
    device = C_iio_context_find_device(context, PHY_DEVICE_NAME);
    txChannel = C_iio_device_find_channel(device, "voltage" * string(txID), true);
    rxChannel = C_iio_device_find_channel(device, "voltage" * string(rxID), false);

    return txChannel, rxChannel;
end

"""
    findLoChannels(context[, txLoID, rxLoID])

Returns `txLoChannel::Ptr{iio_channel}, rxLoChannel::Ptr{iio_channel}` from the given context.

# Arguments
- `context::Ptr{iio_context}` : the context to get the channels from.
- `txLoID::Integer=1` : the tx lo channel number (ex : 1 for tx lo channel "altvoltage1").
- `rxLoID::Integer=0` : the rx lo channel number (ex : 0 for rx lo channel "altvoltage0").

# Returns
- `txLoChannel::Ptr{iio_channel}` : a pointer to the TX Lo C iio_channel structure.
- `rxLoChannel::Ptr{iio_channel}` : a pointer to the RX Lo C iio_channel structure.
"""
function findLoChannels(context::Ptr{iio_context}, txLoID=1, rxLoID=0)
    device = C_iio_context_find_device(context, PHY_DEVICE_NAME);
    txLoChannel = C_iio_device_find_channel(device, "altvoltage" * string(txLoID), true);
    rxLoChannel = C_iio_device_find_channel(device, "altvoltage" * string(rxLoID), true);

    return txLoChannel, rxLoChannel;
end

"""
    cfgChannels(context, txCfg, rxCfg)

Configures the RX, RX LO, TX, and TX LO channels from the provided configurations.
Returns the configured channels.

# Arguments
- `context::Ptr{iio_context}` : the context to get the channels from.
- `txCfg::ChannelCfg` : the tx configuration (port / bandwidth / sampling rate / frequency).
- `rxCfg::ChannelCfg` : the rx configuration (port / bandwidth / sampling rate / frequency).

# Returns
- `txChannel::Ptr{iio_channel}` : a pointer to the configured TX C iio_channel structure.
- `rxChannel::Ptr{iio_channel}` : a pointer to the configured RX C iio_channel structure.
- `txLoChannel::Ptr{iio_channel}` : a pointer to the configured TX Lo C iio_channel structure.
- `rxLoChannel::Ptr{iio_channel}` : a pointer to the configured RX Lo C iio_channel structure.
"""
function cfgChannels(context::Ptr{iio_context}, txCfg::ChannelCfg, rxCfg::ChannelCfg)
    txChannel, rxChannel = findTRXChannels(context);
    txLoChannel, rxLoChannel = findLoChannels(context);

    return cfgChannels(txChannel, rxChannel, txLoChannel, rxLoChannel, txCfg, rxCfg);
end

"""
    cfgChannels(txChannel, rxChannel, txLoChannel, rxLoChannel, txCfg, rxCfg)

Configures the RX, RX LO, TX, and TX LO channels from the provided configurations.
Returns the configured channels.

# Arguments
- `txChannel::Ptr{iio_channel}` : the tx channel.
- `rxChannel::Ptr{iio_channel}` : the rx channel.
- `txLoChannel::Ptr{iio_channel}` : the tx lo channel.
- `rxLoChannel::Ptr{iio_channel}` : the rx lo channel.
- `txCfg::ChannelCfg` : the tx configuration (port / bandwidth / sampling rate / frequency).
- `rxCfg::ChannelCfg` : the rx configuration (port / bandwidth / sampling rate / frequency).

# Returns
- `txChannel::Ptr{iio_channel}` : a pointer to the configured TX C iio_channel structure.
- `rxChannel::Ptr{iio_channel}` : a pointer to the configured RX C iio_channel structure.
- `txLoChannel::Ptr{iio_channel}` : a pointer to the configured TX Lo C iio_channel structure.
- `rxLoChannel::Ptr{iio_channel}` : a pointer to the configured RX Lo C iio_channel structure.
"""
function cfgChannels(
    txChannel::Ptr{iio_channel},
    rxChannel::Ptr{iio_channel},
    txLoChannel::Ptr{iio_channel},
    rxLoChannel::Ptr{iio_channel},
    txCfg::ChannelCfg,
    rxCfg::ChannelCfg
)
    C_iio_channel_attr_write(txChannel, "rf_port_select", txCfg.rfport);
    C_iio_channel_attr_write_longlong(txChannel, "rf_bandwidth", txCfg.bandwidth);
    C_iio_channel_attr_write_longlong(txChannel, "sampling_frequency", txCfg.samplingRate);
    C_iio_channel_attr_write_longlong(txLoChannel, "frequency", txCfg.carrierFreq);

    C_iio_channel_attr_write(rxChannel, "rf_port_select", rxCfg.rfport);
    C_iio_channel_attr_write_longlong(rxChannel, "rf_bandwidth", rxCfg.bandwidth);
    C_iio_channel_attr_write_longlong(rxChannel, "sampling_frequency", rxCfg.samplingRate);
    C_iio_channel_attr_write_longlong(rxLoChannel, "frequency", rxCfg.carrierFreq);

    return txChannel, rxChannel, txLoChannel, rxLoChannel;
end

"""
    findIQChannels(device, iID, qID, isOutput)

Returns `IChannel::Ptr{iio_channel}, QChannel::Ptr{iio_channel}` from the given device.

# Arguments
- `device::Ptr{iio_device}` : the device to get the channels from.
- `iID::String` : identification string for the I channel (ex : "voltage0").
- `qID::String` : identification string for the Q channel (ex : "voltage1").
- `isOutput::Bool` : whether the IQ channels are outputs.

# Returns
- `IChannel::Ptr{iio_channel}` : the I channel.
- `QChannel::Ptr{iio_channel}` : the Q channel.
"""
function findIQChannels(device::Ptr{iio_device}, iID::String, qID::String, isOutput::Bool)
    IChannel = C_iio_device_find_channel(device, iID, isOutput);
    QChannel = C_iio_device_find_channel(device, qID, isOutput);
    return IChannel, QChannel;
end

"""
    updateEffectiveCfg!(trx)

Updates the stored values of the effective sampling rate and carrier frequency of either a `PlutoTx` or `PlutoRx`.
If the values are different than the ones in the `ChannelCfg` of the structure, a warning is printed.
Returns the effective values values.

# Arguments
- `trx::Union{PlutoTx, PlutoRx}` : the structure containing the channel to read the current configuration from.

# Keywords
- `doLog::Bool` : toggles the display of the new carrier frequency

# Returns
- `effectiveSamplingRate::Int` : the current sampling rate.
- `effectiveCarrierFreq::Int` : the current carrier frequency.
"""
function updateEffectiveCfg!(trx::Union{PlutoTx, PlutoRx}; doLog=true)
    if typeof(trx) == PlutoRx; global type = :RX; else; global type = :TX; end;

    ret, effectiveSamplingRate = C_iio_channel_attr_read_longlong(trx.iio.chn, "sampling_frequency");
    if ret < 0
        @warnPluto type "Could not get effective sampling rate (Error $ret):\n" * C_iio_strerror(ret);
    end
    ret, effectiveCarrierFreq = C_iio_channel_attr_read_longlong(trx.iio.chn_lo, "frequency");
    if ret < 0
        @warnPluto type "Could not get effective carrier frequency (Error $ret):\n" * C_iio_strerror(ret);
    end

    trx.effectiveSamplingRate = effectiveSamplingRate;
    trx.effectiveCarrierFreq  = effectiveCarrierFreq;

    if effectiveSamplingRate != trx.cfg.samplingRate && doLog
        @warnPluto type "Effective sampling rate ($effectiveSamplingRate) ≠ Requested sampling rate ($(trx.cfg.samplingRate))";
    end
    if effectiveCarrierFreq != trx.cfg.carrierFreq && doLog
        @warnPluto type "Effective carrier frequency ($effectiveCarrierFreq) ≠ Requested carrier frequency ($(trx.cfg.carrierFreq))";
    end

    return effectiveSamplingRate, effectiveCarrierFreq;
end

"""
    createBuffer(device, samplesCount)

Creates a buffer for the provided device. Returns a wrapper around the buffer with basic info
(C pointer, sample size, first sample, last sample, steps between samples, Julia complex samples, number of non-queried Julia complex samples).

# Arguments
- `device::Ptr{iio_device}` : the device for which the buffer is created.
- `samplesCound::UInt` : the size of the buffer in samples.

# Returns
- `buffer::IIO_Buffer` : a buffer for the given channel with space for samplesCount samples.
"""
function createBuffer(device::Ptr{iio_device}, samplesCount::UInt)
    sampleSize = C_iio_device_get_sample_size(device);
    buf        = C_iio_device_create_buffer(device, samplesCount, false);
    first      = C_iio_buffer_start(buf);
    last       = C_iio_buffer_end(buf);
    step       = C_iio_buffer_step(buf);

    return IIO_Buffer(
        buf, samplesCount, sampleSize, first, last, step,   # values regarding the C buffers
        zeros(UInt8, (samplesCount * sampleSize) ÷ 2),      # array to store raw I samples
        zeros(UInt8, (samplesCount * sampleSize) ÷ 2),      # array to store raw Q samples
        zeros(ComplexF32, samplesCount),                    # array to store decoded complex samples
        0);                                                 # number of samples not yet queried
end


# ------------------------ #
# --- Module functions --- #
# ------------------------ #

"""
    openPluto(carrierFreq, samplingRate, bandwidth[, uri, backend])

Creates a PlutoSDR struct and configures the radio to stream the samples.

# Arguments
- `carrierFreq::Int` : the carrier frequency for both tx and rx.
- `samplingRate::Int` : the sampling rate for both tx and rx.
- `gain::Int` : the analog RX gain.

# Keywords
- `addr::String="auto"` : the radio address (ex: "usb:1.3.5"). "auto" takes the first uri found for the given backend.
- `backend::String="usb"` : the backend to scan for the auto uri.
- `bufferSize::UInt=1024*1024` : the buffer size in samples.
- `bandwidth::Int` : the bandwidth for both tx and rx.

# Returns
- `radio::PlutoSDR` : a fully initialized PlutoSDR structure.
"""
function openPluto(
    carrierFreq::Int, samplingRate::Int, gain::Int, antenna="A;A_BALANCED";
    addr::String="auto", backend::String="usb", bufferSize::UInt=UInt64(1024*1024), bandwidth::Int=Int(20e6)
)
    antenna = split(antenna, ";");
    if !(length(antenna) == 2)
        throw(ArgumentError("Couldn't parse antenna ports. Expected syntax: TXport;RXport"));
    end
    radio = openPluto(
        ChannelCfg(antenna[1], bandwidth, samplingRate, carrierFreq),
        ChannelCfg(antenna[2], bandwidth, samplingRate, carrierFreq),
        bufferSize,
        addr,
        backend
    );
    updateGain!(radio, gain);
    return radio;
end

"""
    openPluto(txCfg, rxCfg[, uri, backend])

Creates a PlutoSDR struct and configures the radio to stream the samples.

# Arguments
- `txCfg::ChannelCfg` : the port / bandwidth / sampling rate / carrier frequency for the tx channels.
- `rxCfg::ChannelCfg` : the port / bandwidth / sampling rate / carrier frequency for the rx channels.
- `bufferSize::UInt=1024*1024` : the buffer size in samples.
- `uri::String="auto"` : the radio uri (ex : "usb:1.3.5"). "auto" takes the first uri found for the given backend.
- `backend::String="usb"` : the backend to scan for the auto uri.

# Returns
- `radio::PlutoSDR` : a fully initialized PlutoSDR structure.
"""
function openPluto(txCfg::ChannelCfg, rxCfg::ChannelCfg, bufferSize::UInt=UInt64(1024*1024), uri="auto", backend="usb")
    if uri == "auto"
        uri = scan(backend);
        if uri == ""
            error("Unable to auto-detect the Pluto uri using $backend backend");
        end
    end

    context = createContext(uri);
    # printing stuff
    description = C_iio_context_get_description(context);
    println("Description :\n$description\n");

    tx, rx = findTRXDevices(context);

    tx0_i, tx0_q = findIQChannels(tx, "voltage0", "voltage1", true);
    rx0_i, rx0_q = findIQChannels(rx, "voltage0", "voltage1", false);

    C_iio_channel_enable(tx0_i);
    C_iio_channel_enable(tx0_q);
    C_iio_channel_enable(rx0_i);
    C_iio_channel_enable(rx0_q);

    txChannel, rxChannel, txLoChannel, rxLoChannel = cfgChannels(context, txCfg, rxCfg);

    iioTx = txWrapper(
        tx,
        tx0_i,
        tx0_q,
        txChannel,
        txLoChannel
    );
    iioRx = rxWrapper(
        rx,
        rx0_i,
        rx0_q,
        rxChannel,
        rxLoChannel
    );

    # 1 MiS buffers
    txBuffer = createBuffer(tx, bufferSize);
    rxBuffer = createBuffer(rx, bufferSize);

    tx = PlutoTx(
        iioTx,
        txCfg,
        txBuffer,
        -1,
        -1,
        false
    );
    rx = PlutoRx(
        iioRx,
        rxCfg,
        rxBuffer,
        -1,
        -1,
        false
    );

    # effective cfg
    updateEffectiveCfg!(tx);
    updateEffectiveCfg!(rx);

    pluto = PlutoSDR(
        context,
        tx,
        rx,
        false
    );

    return pluto;
end

"""
    close(pluto)

Frees the C allocated memory associated to the PlutoSDR structure.
"""
function Base.close(pluto::PlutoSDR)
    if pluto.released
        @warn "Pluto has already been released, abort call";
    else
        C_iio_channel_disable(pluto.rx.iio.rx0_i);
        C_iio_channel_disable(pluto.rx.iio.rx0_q);
        C_iio_channel_disable(pluto.tx.iio.tx0_i);
        C_iio_channel_disable(pluto.tx.iio.tx0_q);
        C_iio_buffer_destroy(pluto.rx.buf.C_ptr);
        C_iio_buffer_destroy(pluto.tx.buf.C_ptr);
        C_iio_context_destroy(pluto.ctx);
        pluto.tx.released = true;
        pluto.rx.released = true;
        pluto.released = true;
    end
end

"""
    updateGainMode!(pluto[, mode])

Modifies the pluto RX channel gain control mode.
Returns an error code < 0 if it doesn't succeed.

# Arguments
- `pluto::PlutoSDR` : the radio to modify.
- `mode::GainMode=DEFAULT` : the new gain mode. DEFAULT ≡ FAST_ATTACK.

# Returns
- `errno::Int` : 0 or a negative error code.
"""
function updateGainMode!(pluto::PlutoSDR, mode::GainMode=DEFAULT)
    control_mode = "";
    if mode == MANUAL
        control_mode = "manual"
    elseif mode == FAST_ATTACK
        control_mode = "fast_attack"
    elseif mode == SLOW_ATTACK
        control_mode = "slow_attack"
    elseif mode == HYBRID
        control_mode = "hybrid"
    else
        control_mode = "fast_attack"
    end

    return C_iio_channel_attr_write(pluto.rx.iio.chn, "gain_control_mode", control_mode);
end

"""
    updateGain!(pluto, value)

Changes the gain control mode to manual et sets the given value.
Prints a warning and returns the error code if it doesn't succeed.

# Arguments
- `pluto::PlutoSDR` : the radio to modify.
- `value::Int64` : the manual gain value.

# Returns
- `errno::Int` : 0 or a negative error code.
"""
function updateGain!(pluto::PlutoSDR, value::Int64)
    ret = updateGainMode!(pluto, MANUAL);
    if ret < 0
        @warnPluto :RX "Could not set gain_control_mode to manual (Error $ret):\n" * C_iio_strerror(ret);
        return ret;
    end
    ret = C_iio_channel_attr_write_longlong(pluto.rx.iio.chn, "hardwaregain", value);
    if ret < 0
        @warnPluto :RX "Could not set hardwaregain to $value (Error $ret):\n" * C_iio_strerror(ret);
    end
    return ret;
end

"""
    updateCarrierFreq!(pluto, value; doLog)

Changes the carrier frequency. Prints the new effective frequency.

# Arguments
- `pluto::PlutoSDR` : the radio to modify.
- `value::Int64` : the new carrier frequency.

# Keywords
- `doLog::Bool` : toggles the display of the new carrier frequency

# Returns
- `errno::Int` : 0 or a negative error code.
"""
function updateCarrierFreq!(pluto::PlutoSDR, value::Int64; doLog=true)
    # set the carrier frequencie for RX
    errno = C_iio_channel_attr_write_longlong(pluto.rx.iio.chn_lo, "frequency", value);
    if (errno < 0); return errno; end;

    # store the requested configuration and effective configuration for RX
    pluto.rx.cfg.carrierFreq = value;
    effectiveCarrierFreq = updateEffectiveCfg!(pluto.rx; doLog=doLog)[2];
    if doLog; @infoPluto :RX "New RX carrier frequency : $effectiveCarrierFreq ($value)"; end;

    # set the carrier frequencie for TX
    errno = C_iio_channel_attr_write_longlong(pluto.tx.iio.chn_lo, "frequency", value);
    if (errno < 0); return errno; end;

    # store the requested configuration and effective configuration for TX
    pluto.tx.cfg.carrierFreq = value;
    effectiveCarrierFreq = updateEffectiveCfg!(pluto.tx; doLog=doLog)[2];
    if doLog; @infoPluto :TX "New TX carrier frequency : $effectiveCarrierFreq ($value)"; end;

    # not actually errno because it's equal to the number of bytes written
    return 0;
end

"""
    updateSamplingRate!(pluto, value; doLog)

Changes the sampling rate. Prints the new effective sampling rate.

# Arguments
- `pluto::PlutoSDR` : the radio to modify.
- `value::Int64` : the new sampling rate.

# Keywords
- `doLog::Bool` : toggles the display of the new carrier frequency

# Returns
- `errno::Int` : 0 or a negative error code.
"""
function updateSamplingRate!(pluto::PlutoSDR, value::Int64; doLog=true)
    # set the sampling rate for RX
    errno = C_iio_channel_attr_write_longlong(pluto.rx.iio.chn, "sampling_frequency", value);
    if (errno < 0); return errno; end;

    # store the requested configuration and effective configuration for RX
    pluto.rx.cfg.samplingRate = value;
    effectiveSamplingRate = updateEffectiveCfg!(pluto.rx; doLog=doLog)[1];
    if doLog; @infoPluto :RX "New RX sampling rate : $effectiveSamplingRate ($value)"; end;

    # set the sampling rate for TX
    errno = C_iio_channel_attr_write_longlong(pluto.tx.iio.chn, "sampling_frequency", value);
    if (errno < 0); return errno; end;

    # store the requested configuration and effective configuration for TX
    pluto.tx.cfg.samplingRate = value;
    effectiveSamplingRate = updateEffectiveCfg!(pluto.tx; doLog=doLog)[1];
    if doLog; @infoPluto :TX "New TX sampling rate : $effectiveSamplingRate ($value)"; end;

    # not actually errno because it's equal to the number of bytes written
    return 0;
end

"""
    updateBandwidth!(pluto, value)

Changes the bandwidth. Prints the new value.

# Arguments
- `pluto::PlutoSDR` : the radio to modify.
- `value::Int64` : the new sampling rate.

# Keywords
- `doLog::Bool` : toggles the display of the new carrier frequency

# Returns
- `errno::Int` : 0 or a negative error code.
"""
function updateBandwidth!(pluto, value::Int64; doLog=true)
    # set the bandwidth for RX
    errno = C_iio_channel_attr_write_longlong(pluto.rx.iio.chn, "rf_bandwidth", value);
    if (errno < 0); return errno; end;

    # store the new configuration for RX
    if doLog; @infoPluto :RX "New Rx bandwidth : $value"; end;
    pluto.rx.cfg.bandwidth = value;

    # set the bandwidth for TX
    errno = C_iio_channel_attr_write_longlong(pluto.tx.iio.chn, "rf_bandwidth", value);
    if (errno < 0); return errno; end;

    # store the new configuration for TX
    if doLog; @infoPluto :TX "New Tx bandwidth : $value"; end;
    pluto.tx.cfg.bandwidth = value;

    return 0;
end

"""
    recv(pluto, nbSamples)

Reads nbSamples from the Julia buffer. If there are less than nbSamples samples in the Julia buffer,
the remaining samples are read, the buffer is refilled, and a total of the nbSamples is read.
Returns a newly allocated `Array{ComplexF32}`.

# Arguments
- `pluto::PlutoSDR` : the radio to get receive the samples from.
- `nbSamples::Int` : the number of samples to receive.

# Returns
- `buffer::Array{ComplexF32}` : an array with nbSamples complex values.
"""
function recv(pluto::PlutoSDR, nbSamples::Int)
    buffer = zeros(ComplexF32, nbSamples);
    recv!(buffer, pluto);
    return buffer;
end

"""
    recv!(sig, pluto)

Fills the `sig` input buffer with samples from the Julia buffer. If there are not enough samples in the Julia buffer,
it is refilled until `sig` is full.
Returns the number of samples filled or a negative error number.

# Arguments
- `sig::Array{ComplexF32}` : the buffer to be filled.
- `pluto::PlutoSDR` : the radio to read the samples from.
"""
function recv!(sig::Array{ComplexF32}, pluto::PlutoSDR)
    # FIXME: make this function somewhat error resilient
    samplesNeeded = length(sig);

    while (samplesNeeded > 0)
        # if needed refill the Julia buffer
        if (pluto.rx.buf.nb_samples == 0)
            nbNewSamples = refillJuliaBufferRX(pluto);
        end
        samplesQueried = min(samplesNeeded, pluto.rx.buf.nb_samples);
        # assuming the Julia buffer is filled until the end (which it should)
        sig[(end - samplesNeeded + 1):(end - samplesNeeded + samplesQueried)] =
            pluto.rx.buf.samples[(end - pluto.rx.buf.nb_samples + 1):(end - pluto.rx.buf.nb_samples + samplesQueried)];
        pluto.rx.buf.nb_samples -= samplesQueried;
        samplesNeeded -= samplesQueried;
    end

    return length(sig);
end

"""
    refillJuliaBufferRX(pluto)

Refills the radio buffer, decode the samples into `ComplexF32` values, and store those values in the `pluto` structure.
To access those samples : `pluto.rx.buf.samples`.

# Arguments
- `pluto::PlutoSDR` : the radio to receive the samples from, and the structure storing those samples.

# Returns
- `nbSamples::Int` : the number of samples stored into the Julia buffer.
"""
function refillJuliaBufferRX(pluto::PlutoSDR)
    nbytes = C_iio_buffer_refill(pluto.rx.buf.C_ptr);
    if (nbytes < 0)
        return nbytes;
    end
    # intermediary buffers from which complex values are computed
    nbytes_i = C_iio_channel_read!(pluto.rx.iio.rx0_i, pluto.rx.buf.C_ptr, pluto.rx.buf.i_raw_samples);
    nbytes_q = C_iio_channel_read!(pluto.rx.iio.rx0_q, pluto.rx.buf.C_ptr, pluto.rx.buf.q_raw_samples);

    # find the appropriate types and their max values for normalization
    bytes_per_value = pluto.rx.buf.C_step ÷ 2;
    utype, type, utype_norm, type_norm = nbytesToType(bytes_per_value);

    pluto.rx.buf.samples = reinterpret(Complex{type}, [pluto.rx.buf.i_raw_samples pluto.rx.buf.q_raw_samples]'[:]) / Float32(type_norm);
    pluto.rx.buf.nb_samples = (nbytes_i + nbytes_q) ÷ pluto.rx.buf.C_step;

    return pluto.rx.buf.nb_samples;
end


""" 
   print(pluto)
   Print the current radio configuration 
# Arguments
- `pluto::PlutoSDR` : the radio to receive the samples from, and the structure storing those samples.

# Returns
- A string with the different configuration aspects
"""
function Base.print(pluto::PlutoSDR)
	# Print message 
	strF  = @sprintf(" Carrier Frequency: %2.3f MHz\n Sampling Frequency: %2.3f MHz\n",pluto.rx.effectiveCarrierFreq/1e6,pluto.rx.effectiveSamplingRate/1e6);
    println("Current Pluto Configuration in Rx mode\n$strF");
	strF  = @sprintf(" Carrier Frequency: %2.3f MHz\n Sampling Frequency: %2.3f MHz\n",pluto.tx.effectiveCarrierFreq/1e6,pluto.tx.effectiveSamplingRate/1e6);
    println("Current Pluto Configuration in Tx mode\n$strF");

end

##
# This function is significantly slower than the one above despite using less arrays and doing stuff manually.
# It is kept here to remind me why the weird interleaving of arrays is still my best solution.
##
# function refillJuliaBufferRX_ButItsSlower(pluto::PlutoSDR)
#     nbytes_C = C_iio_buffer_refill(pluto.rx.buf.C_ptr);
#     #  nbytes_Julia = C_iio_channel_read!(pluto.rx.iio.chn, pluto.rx.buf.C_ptr, pluto.rx.buf.raw_samples); # doesn't work ?
#
#     pluto.rx.buf.C_first = C_iio_buffer_first(pluto.rx.buf.C_ptr, pluto.rx.iio.rx0_i);
#     pluto.rx.buf.C_last  = C_iio_buffer_end(pluto.rx.buf.C_ptr);
#     pluto.rx.buf.C_step  = C_iio_buffer_step(pluto.rx.buf.C_ptr);
#
#     format = unsafe_load(ccall(
#         (:iio_channel_get_data_format, libIIO_jl.libIIO),
#         Ptr{iio_data_format}, (Ptr{iio_channel},),
#         pluto.rx.iio.rx0_q
#     ));
#
#     src_ptr = C_iio_buffer_first(pluto.rx.buf.C_ptr, pluto.rx.iio.rx0_i);
#     dst_ptr = pointer(pluto.rx.buf.raw_samples, 1);
#     len = Int64(format.length / 8 * format.repeat);
#
#     foreach(src_ptr:pluto.rx.buf.C_step:pluto.rx.buf.C_last-1) do src_ptr
#         ccall(
#             (:iio_channel_convert, libIIO_jl.libIIO),
#             Cvoid, (Ptr{iio_channel}, Ptr{Cvoid}, Ptr{Cvoid}),
#             pluto.rx.iio.chn, dst_ptr, src_ptr
#         );
#         dst_ptr += len;
#     end
#
#     bytes_per_value = pluto.rx.buf.C_step ÷ 2;
#     utype, type, utype_norm, type_norm = nbytesToType(bytes_per_value);
#
#     pluto.rx.buf.samples = reinterpret(Complex{type}, pluto.rx.buf.raw_samples) / Float32(type_norm);
#     pluto.rx.buf.nb_samples = pluto.rx.buf.C_size;
#
#     return pluto.rx.buf.nb_samples;
# end

end
