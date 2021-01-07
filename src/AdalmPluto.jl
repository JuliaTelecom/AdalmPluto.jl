# --- All libIIO functions wrapped --- #

module AdalmPluto

using Reexport;

include("libIIO/libIIO.jl");
@reexport using .libIIO_jl;

# --- Functions taken from libad9361 --- #
include("libad9361.jl");
# --- utils --- #
include("utils.jl");

# --- struct exports --- #
export
    ChannelCfg,
    Pluto
;

# --- functions exports --- #
export
    open,
    close,
    recv,
    recv!,
    updateRXGain!,
    updateRXGainMode!
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
    ptr::Ptr{iio_buffer};
    size::Csize_t;
    sample_size::Cssize_t;
    first::Ptr{Cuchar};
    last::Ptr{Cuchar};
    step::Cssize_t;
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
    Pluto

Layout :

Pluto
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
|   |   +-- ptr::Ptr{iio_buffer};
|   |   +-- size::Csize_t;
|   |   +-- sample_size::Cssize_t;
|   |   +-- first::Ptr{Cuchar};
|   |   +-- last::Ptr{Cuchar};
|   |   +-- step::Cssize_t;
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
|   |   +-- ptr::Ptr{iio_buffer};
|   |   +-- size::Csize_t;
|   |   +-- sample_size::Cssize_t;
|   |   +-- first::Ptr{Cuchar};
|   |   +-- last::Ptr{Cuchar};
|   |   +-- step::Cssize_t;
|   |
|   +-- effectiveSamplingRate::Float64
|   +-- effectiveCarrierFreq::Float64
|   +-- released::Bool
|
+-- released::Bool

"""
mutable struct Pluto
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

Returns a device uri.

# Arguments
- `backend::String` : the backend to scan (local, xml, ip, usb).
- `infoIndex::Integer=1` : the device index.
- `doPrint::Bool=true` : toggles console printing of the uri.

# C equivalent
https://analogdevicesinc.github.io/libiio/master/libiio/iio-monitor_8c-example.html#_a15
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

# Returns a Ptr{iio_context} from the given URI
# Throws an error if there are no devices in this context
"""
    getContext(uri)

Returns the `iio_context` corresponding the the provided uri. Throws an error if no devices are found in the context.
"""
function getContext(uri::String)
    context = C_iio_create_context_from_uri(uri);
    if(C_iio_context_get_devices_count(context) == 0) error("No device found in context from uri $uri"); end
    return context;
end


"""
    getTRXDevices(context)

Returns `txDevice::Ptr{iio_device}, rxDevice::Ptr{iio_device}` from the given context.
"""
function getTRXDevices(context::Ptr{iio_context})
    txDevice = C_iio_context_find_device(context, TX_DEVICE_NAME);
    rxDevice = C_iio_context_find_device(context, RX_DEVICE_NAME);
    return txDevice, rxDevice;
end

"""
    getTRXChannels(context[, txID, rxID])

Returns `txChannel::Ptr{iio_channel}, rxChannel::Ptr{iio_channel}` from the given context.

# Arguments
- `context::Ptr{iio_context}` : the context to get the channels from.
- `txID::Integer=0` : the tx channel number (ex : 0 for tx channel "voltage0").
- `rxID::Integer=0` : the rx channel number (ex : 0 for rx channel "voltage0").
"""
function getTRXChannels(context::Ptr{iio_context}, txID=0, rxID=0)
    device = C_iio_context_find_device(context, PHY_DEVICE_NAME);
    txChannel = C_iio_device_find_channel(device, "voltage" * string(txID), true);
    rxChannel = C_iio_device_find_channel(device, "voltage" * string(rxID), false);

    return txChannel, rxChannel;
end

"""
    getLoChannels(context[, txLoID, rxLoID])

Returns `txLoChannel::Ptr{iio_channel}, rxLoChannel::Ptr{iio_channel}` from the given context.

# Arguments
- `context::Ptr{iio_context}` : the context to get the channels from.
- `txLoID::Integer=1` : the tx lo channel number (ex : 1 for tx lo channel "altvoltage1").
- `rxLoID::Integer=0` : the rx lo channel number (ex : 0 for rx lo channel "altvoltage0").
"""
function getLoChannels(context::Ptr{iio_context}, txLoID=1, rxLoID=0)
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
"""
function cfgChannels(context::Ptr{iio_context}, txCfg::ChannelCfg, rxCfg::ChannelCfg)
    txChannel, rxChannel = getTRXChannels(context);
    txLoChannel, rxLoChannel = getLoChannels(context);

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
    getIQChannels(device, iID, qID, isOutput)

Returns `IChannel::Ptr{iio_channel}, QChannel::Ptr{iio_channel}` from the given device.

# Arguments
- `device::Ptr{iio_device}` : the device to get the channels from.
- `iID::String` : identification string for the I channel (ex : "voltage0").
- `qID::String` : identification string for the Q channel (ex : "voltage1").
- `isOutput::Bool` : whether the IQ channels are outputs.
"""
function getIQChannels(device::Ptr{iio_device}, iID::String, qID::String, isOutput::Bool)
    IChannel = C_iio_device_find_channel(device, iID, isOutput);
    QChannel = C_iio_device_find_channel(device, qID, isOutput);
    return IChannel, QChannel;
end

"""
    getEffectiveCfg(wrapper)

Returns the effective sampling rate and carrier frequency of either a `txWrapper` or `rxWrapper`.
"""
function getEffectiveCfg(wrapper::Union{txWrapper, rxWrapper})
    ret, effectiveSamplingRate = C_iio_channel_attr_read(wrapper.chn, "sampling_frequency");
    if ret < 0
        @warntx "Could not get effective sampling rate (Error $ret):\n" * C_iio_strerror(ret);
    else
        effectiveSamplingRate = parse(Int64, effectiveSamplingRate);
    end
    ret, effectiveCarrierFreq = C_iio_channel_attr_read(wrapper.chn_lo, "frequency");
    if ret < 0
        @warntx "Could not get effective carrier frequency (Error $ret):\n" * C_iio_strerror(ret);
    else
        effectiveCarrierFreq = parse(Int64, effectiveCarrierFreq);
    end

    return effectiveSamplingRate, effectiveCarrierFreq;
end

"""
    getBuffer(device, channel, samplesCount)

Creates a buffer for the provided channel. Returns a wrapper around the buffer with basic info
(pointer, sample size, first sample, last sample, steps between samples).

# Arguments
- `device::Ptr{iio_device}` : the device in which the buffer is created.
- `channel::Ptr{iio_channel}` : the channel from which the buffer will be filled.
- `samplesCound::UInt` : the size of the buffer in samples.

"""
function getBuffer(device::Ptr{iio_device}, channel::Ptr{iio_channel}, samplesCount::UInt)
    sampleSize = C_iio_device_get_sample_size(device);
    buf = C_iio_device_create_buffer(device, samplesCount, false);
    first = C_iio_buffer_first(buf, channel);
    last = C_iio_buffer_end(buf);
    step = C_iio_buffer_step(buf);

    return IIO_Buffer(buf, samplesCount, sampleSize, first, last, step);
end


# ------------------------ #
# --- Module functions --- #
# ------------------------ #

"""
    open(carrierFreq, samplingRate, bandwidth[, uri, backend])

Creates a PlutoSDR struct and configure the radio to stream the samples.

# Arguments
- `carrierFreq::Int` : the carrier frequency for both tx and rx.
- `samplingRate::Int` : the sampling rate for both tx and rx.
- `bandwidth::Int` : the bandwidth for both tx and rx.
- `bufferSize::UInt=1024*1024` : the buffer size in samples.
- `uri::String="auto"` : the radio uri (ex : "usb:1.3.5"). "auto" takes the first uri found for the given backend.
- `backend::String="usb"` : the backend to scan for the auto uri.
"""
function open(carrierFreq::Int, samplingRate::Int, bandwidth::Int, bufferSize::UInt=UInt64(1024*1024), uri="auto", backend="usb")
    return open(
        ChannelCfg("A", carrierFreq, samplingRate, bandwidth),
        ChannelCfg("A_BALANCED", carrierFreq, samplingRate, bandwidth),
        bufferSize,
        uri,
        backend
    );
end

"""
    open(txCfg, rxCfg[, uri, backend])

Creates a PlutoSDR struct and configure the radio to stream the samples.

# Arguments
- `txCfg::ChannelCfg` : the port / bandwidth / sampling rate / carrier frequency for the tx channels.
- `rxCfg::ChannelCfg` : the port / bandwidth / sampling rate / carrier frequency for the rx channels.
- `bufferSize::UInt=1024*1024` : the buffer size in samples.
- `uri::String="auto"` : the radio uri (ex : "usb:1.3.5"). "auto" takes the first uri found for the given backend.
- `backend::String="usb"` : the backend to scan for the auto uri.
"""
function open(txCfg::ChannelCfg, rxCfg::ChannelCfg, bufferSize::UInt=UInt64(1024*1024), uri="auto", backend="usb")
    if uri == "auto"
        uri = scan(backend);
        if uri == ""
            error("Unable to auto-detect the Pluto uri using $backend backend");
        end
    end

    context = getContext(uri);
    tx, rx = getTRXDevices(context);
    txChannel, rxChannel, txLoChannel, rxLoChannel = cfgChannels(context, txCfg, rxCfg);
    tx0_i, tx0_q = getIQChannels(tx, "voltage0", "voltage1", true);
    rx0_i, rx0_q = getIQChannels(rx, "voltage0", "voltage1", false);

    C_iio_channel_enable(tx0_i);
    C_iio_channel_enable(tx0_q);
    C_iio_channel_enable(rx0_i);
    C_iio_channel_enable(rx0_q);

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

    # printing stuff
    description = C_iio_context_get_description(context);
    println("Description :\n$description\n");

    # effective cfg
    txEffectiveSamplingRate, txEffectiveCarrierFreq = getEffectiveCfg(iioTx);
    rxEffectiveSamplingRate, rxEffectiveCarrierFreq = getEffectiveCfg(iioRx);

    # 1 MiS buffers
    txBuffer = getBuffer(tx, tx0_i, bufferSize);
    rxBuffer = getBuffer(rx, rx0_i, bufferSize);

    tx = PlutoTx(
        iioTx,
        txCfg,
        txBuffer,
        txEffectiveSamplingRate,
        txEffectiveCarrierFreq,
        false
    );
    rx = PlutoRx(
        iioRx,
        rxCfg,
        rxBuffer,
        rxEffectiveSamplingRate,
        rxEffectiveCarrierFreq,
        false
    );

    pluto = Pluto(
        context,
        tx,
        rx,
        false
    );

    return pluto;
end

"""
    close(pluto)

Frees the C allocated memory associated to the pluto structure.
"""
function close(pluto::Pluto)
    if pluto.released
        @warn "Pluto has already been released, abort call";
    else
        C_iio_channel_disable(pluto.rx.iio.rx0_i);
        C_iio_channel_disable(pluto.rx.iio.rx0_q);
        C_iio_channel_disable(pluto.tx.iio.tx0_i);
        C_iio_channel_disable(pluto.tx.iio.tx0_q);
        C_iio_buffer_destroy(pluto.rx.buf.ptr);
        C_iio_buffer_destroy(pluto.tx.buf.ptr);
        C_iio_context_destroy(pluto.ctx);
        pluto.tx.released = true;
        pluto.rx.released = true;
        pluto.released = true;
    end
end

"""
    updateRXGainMode!(pluto[, mode])

Modifies the pluto RX channel gain control mode.
Returns an error code < 0 if it doesn't succeed.

Arguments :
- `pluto::Pluto` : the radio to modify.
- `mode::GainMode=DEFAULT` : the new gain mode. DEFAULT ≡ FAST_ATTACK.
"""
function updateRXGainMode!(pluto::Pluto, mode::GainMode=DEFAULT)
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
    updateRXGain!(pluto, value)

Changes the gain control mode to manual et sets the given value.
Prints a warning and returns the error code if it doesn't succeed.

Arguments :
- `pluto::Pluto` : the radio to modify.
- `value::Int64` : the manual gain value.
"""
function updateRXGain!(pluto::Pluto, value::Int64)
    ret = updateRXGainMode!(pluto, MANUAL);
    if ret < 0
        @warnrx "Could not set gain_control_mode to manual (Error $ret):\n" * C_iio_strerror(ret);
        return ret;
    end
    ret = C_iio_channel_attr_write_longlong(pluto.rx.iio.chn, "hardwaregain", value);
    if ret < 0
        @warnrx "Could not set hardwaregain to $value (Error $ret):\n" * C_iio_strerror(ret);
    end
    return ret;
end

"""
    recv(pluto)

Refills the buffers, read them, converts the samples to complex numbers.
Returns the number of bytes received, the samples as comlex numbers, and the raw i and q samples as UInt8 arrays.
"""
function recv(pluto::Pluto)
    buffer_size = UInt(pluto.rx.buf.size * pluto.rx.buf.sample_size ÷ 2);
    dst_i = zeros(UInt8, buffer_size);
    dst_q = zeros(UInt8, buffer_size);
    nbytes, complex_samples = recv!(pluto, dst_i, dst_q);
    return nbytes, complex_samples, dst_i, dst_q;
end

"""
    recv!(pluto, dst_i, dst_q)

Refills the buffers, read them, converts the samples to complex numbers.
Modifies dst_i and dst_q to store the raw samples.
Returns the total number of bytes received and an array containing the samples as complex numbers.
"""
function recv!(pluto::Pluto, dst_i::Array{UInt8}, dst_q::Array{UInt8});
    nbytes = C_iio_buffer_refill(pluto.rx.buf.ptr);
    if (nbytes < 0)
        return nbytes, [];
    end
    # demux and convert samples, loads into a julia array
    # TODO: find out if the arrays are smaller than the buffers, does multiple iio_channel_read calls read the whole buffer?
    nbytes_i = C_iio_channel_read!(pluto.rx.iio.rx0_i, pluto.rx.buf.ptr, dst_i);
    nbytes_q = C_iio_channel_read!(pluto.rx.iio.rx0_q, pluto.rx.buf.ptr, dst_q);
    # TODO: find out if it's needed or those values are constants
    #  pluto.rx.buf.first = C_iio_buffer_first(pluto.rx.buf.ptr, pluto.rx.iio.rx0_i);
    #  pluto.rx.buf.last = C_iio_buffer_end(pluto.rx.buf.ptr);
    #  pluto.rx.buf.step = C_iio_buffer_step(pluto.rx.buf.ptr);

    bytes_per_value = div(pluto.rx.buf.step, 2); # i and q
    utype, type, utype_norm, type_norm = nbytesToType(bytes_per_value); # get the appropriate types and their max values
    # interleave I and Q channels, reinterpret as Complex, "normalize" so that real and imaginary part don't exceed 1
    res = reinterpret(Complex{type}, [dst_i dst_q]'[:]) / Float32(type_norm);

    return nbytes_i + nbytes_q, res;
end

end
