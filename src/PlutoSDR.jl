module PlutoSDR

using Pkg.Artifacts;

# init globals and lib path
const libIIO_rootpath = artifact"libIIO";
const libIIO = joinpath(libIIO_rootpath, "libiio.so");
# needed for libIIO functions, maybe move them ?
const BUF_SIZE = 16384; # same value as iio_common.h
const C_INT_MAX = 2^31 - 1;
NO_ASSERT = false;

# adds a udev rule needed for usb devices
# should be a volatile rule and will need to be added each boot
# but it makes it possible to delete the artifact without leftovers
function __init__()
    if !isfile("/run/udev/rules.d/90-libiio.rules")
        println("Could not find the necessary udev rule.\nAdding it to /run/udev/rules.d/90-libiio.rules.\nDirectory is write protected, password prompt does not come from Julia");
        rule = """SUBSYSTEM=="usb", PROGRAM=="/bin/sh -c '$libIIO_rootpath/tests/iio_info -S usb | grep -oE [[:alnum:]]{4}:[[:alnum:]]{4}'", RESULT!="", MODE="666"\n""";
        open("/tmp/90-libiio.rules", "w") do f
            write(f, rule);
        end
        run(`sudo mkdir -p /run/udev/rules.d`);
        run(`sudo cp /tmp/90-libiio.rules /run/udev/rules.d/90-libiio.rules`);
    end
end

# --- All libIIO functions wrapped --- #
include("libIIO/libIIO.jl");

# --- Pretty printing functions --- #

# To print fancy message with different colors with Tx and Rx
function customPrint(str, handler;style...)
	msglines = split(chomp(str), '\n');
	printstyled("┌", handler, ": ";style...);
	println(msglines[1]);
	for i in 2:length(msglines)
		(i == length(msglines)) ? symb = "└ " : symb = "|";
		printstyled(symb;style...);
		println(msglines[i]);
	end
end

# define macro for printing Rx info
macro inforx(str)
	quote
		customPrint($(esc(str)), "Rx";bold=true,color=:light_green)
	end
end

# define macro for printing Rx warning
macro warnrx(str)
	quote
		customPrint($(esc(str)), "Rx Warning";bold=true,color=:light_yellow)
	end
end

# define macro for printing Tx info
macro infotx(str)
	quote
		customPrint($(esc(str)), "Tx";bold=true,color=:light_blue)
	end
end

# define macro for printing Tx warning
macro warntx(str)
	quote
		customPrint($(esc(str)), "Tx Warning";bold=true,color=:light_yellow)
	end
end

# TODO: macro/function to print errors


# ------------------ #
# --- Structures --- #
# ------------------ #

# --- TRx structure --- #
mutable struct streamCfg
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
    cfg::streamCfg;
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
    cfg::streamCfg;
    buf::IIO_Buffer;
    effectiveSamplingRate::Float64;
    effectiveCarrierFreq::Float64;
    released::Bool;
end

# --- final wrap --- #
mutable struct Pluto
    ctx::Ptr{iio_context};
    tx::PlutoTx;
    rx::PlutoRx;
    released::Bool;
end

# ------------------------ #
# --- Helper functions --- #
# ------------------------ #
#=
Corresponding doc/example
https://analogdevicesinc.github.io/libiio/master/libiio/iio-monitor_8c-example.html#_a15
=#
function scan(backend::String, infoIndex=1, doPrint=true)
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
        loaded_info = unsafe_load(info[], infoIndex);
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
function getContext(uri::String)
    context = C_iio_create_context_from_uri(uri);
    if(C_iio_context_get_devices_count(context) == 0) error("No device found in context from uri $uri"); end
    return context;
end

# Returns a Ptr{iio_device} to the pluto TX device.
function getTXStreamingDevice(context::Ptr{iio_context})
    return C_iio_context_find_device(context, "cf-ad9361-dds-core-lpc");
end

# Returns a Ptr{iio_device} to the pluto RX device.
function getRXStreamingDevice(context::Ptr{iio_context})
    return C_iio_context_find_device(context, "cf-ad9361-lpc");
end

# Returns two Ptr{iio_device} for TX and RX.
# Throws an error if the devices are not found in the context provided.
function getStreamingDevices(context::Ptr{iio_context})
    txDevice = getTXStreamingDevice(context);
    rxDevice = getRXStreamingDevice(context);
    return txDevice, rxDevice;
end

# Returns two Ptr{iio_channel} for TX and RX.
# Throws an error if the device or channels are not found in the context provided.
function getPhyChannels(context::Ptr{iio_context}, txID=0, rxID=0)
    device = C_iio_context_find_device(context, "ad9361-phy");
    txChannel = C_iio_device_find_channel(device, "voltage" * string(txID), true);
    rxChannel = C_iio_device_find_channel(device, "voltage" * string(rxID), false);

    return txChannel, rxChannel;
end

# Returns two Ptr{iio_channel} for TXLo et RXLo.
# Throws an error if the device or channels are not found in the context provided.
function getLoChannels(context::Ptr{iio_context}, txLoID=1, rxLoID=0)
    device = C_iio_context_find_device(context, "ad9361-phy");
    txLoChannel = C_iio_device_find_channel(device, "altvoltage" * string(txLoID), true);
    rxLoChannel = C_iio_device_find_channel(device, "altvoltage" * string(rxLoID), true);

    return txLoChannel, rxLoChannel;
end

function cfgStreamingChannels(context::Ptr{iio_context}, txCfg::streamCfg, rxCfg::streamCfg)
    txChannel, rxChannel = getPhyChannels(context);
    txLoChannel, rxLoChannel = getLoChannels(context);

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

function getIQChannels(device::Ptr{iio_device}, iID::String, qID::String, isOutput::Bool)
    ichannel = C_iio_device_find_channel(device, iID, isOutput);
    qchannel = C_iio_device_find_channel(device, qID, isOutput);
    return ichannel, qchannel;
end

# TODO: cleaner warning printing
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

function openPluto(txCfg::streamCfg, rxCfg::streamCfg, uri="auto", backend="usb")
    if uri == "auto"
        uri = scan(backend);
        if uri == ""
            error("Unable to auto-detect the Pluto uri using $backend backend");
        end
    end

    context = getContext(uri);
    tx, rx = getStreamingDevices(context);
    txChannel, rxChannel, txLoChannel, rxLoChannel = cfgStreamingChannels(context, txCfg, rxCfg);
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
    txBuffer = getBuffer(tx, tx0_i, UInt64(1024*1024));
    rxBuffer = getBuffer(rx, rx0_i, UInt64(1024*1024));

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

function closePluto(pluto::Pluto)
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

function updateRXGain!(pluto::Pluto, value::Int64)
    ret = C_iio_channel_attr_write(pluto.rx.iio.chn, "gain_control_mode", "manual");
    if ret < 0
        @warnrx "Could not set gain_control_mode to manual (Error $ret):\n" * C_iio_strerror(ret);
    end
    ret = C_iio_channel_attr_write_longlong(pluto.rx.iio.chn, "hardwaregain", value);
    if ret < 0
        @warnrx "Could not set hardwaregain to $value (Error $ret):\n" * C_iio_strerror(ret);
    end
end

function nbytesToType(nbytes::Cssize_t)
    type = Nothing, Nothing;
    if nbytes == 1
        type = UInt8, Int8;
    elseif nbytes == 2
        type = UInt16, Cshort;
    elseif nbytes == 4
        type = UInt32, Cint;
    elseif nbytes == 8
        type = UInt64, Clonglong;
    end
    return type;
end

function recv(pluto::Pluto)
    nbytes = C_iio_buffer_refill(pluto.rx.buf.ptr);
    if (nbytes < 0)
        return nbytes, [];
    end
    # demux and convert samples, loads into a julia array
    nbytes, sig = C_iio_channel_read(pluto.rx.iio.rx0_i, pluto.rx.buf.ptr);
    # TODO: find out if it's needed or those values are constants
    pluto.rx.buf.first = C_iio_buffer_first(pluto.rx.buf.ptr, pluto.rx.iio.rx0_i);
    pluto.rx.buf.last = C_iio_buffer_end(pluto.rx.buf.ptr);
    pluto.rx.buf.step = C_iio_buffer_step(pluto.rx.buf.ptr);

    bytes_per_value = div(pluto.rx.buf.step, 2); # i and q
    utype, type = nbytesToType(bytes_per_value);
    # ugly one liner to convert and bitshift into a new array
    #  tmp = map(x -> utype(x[2]) << (8 * ((x[1] - 1) % bytes_per_value)), enumerate(sig));
    #  res = map(x -> reduce(+, tmp[(x-1)*bytes_per_value+1:x*bytes_per_value]), 1:div(nbytes, bytes_per_value));
    # TODO: clean previous lines (always same data type ?)
    # TODO: check byte ordering
    res = collect(reinterpret(Complex{type}, sig));

    # @show div(nbytes, bytes_per_value);

    return sig, res;
end


end
