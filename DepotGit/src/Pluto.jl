module Pluto 

using Libdl
using Printf
import Base:close;
import Base:print;


export openPluto
export updateCarrierFreq!
export updateSamplingRate!
export print
export recv, recv!


const libIIO = "/Users/gerzaguet/Documents/Travail/IRISA/Rose/Pluto/libiio-0.19.g5f5af2e-darwin-10.14.4/usr/lib/libiio.dylib"; 
# function __init__()
# 	# ---------------------------------------------------- 
# 	# --- Loading librairies in __init__ 
#     # ---------------------------------------------------- 
#     chemin          = "/Users/gerzaguet/Documents/Travail/IRISA/Rose/Pluto/libiio-0.19.g5f5af2e-darwin-10.14.4/usr/lib/libiio.dylib";
# 	global libIIO		= chemin;
# end

const CHAR_SIZE = 64; ## Size of CHAR for getting info from radio


# ----------------------------------------------------
# --- Print function 
# ---------------------------------------------------- 
# To print fancy message with different colors with Tx and Rx
function customPrint(str, handler;style...)
	msglines = split(chomp(str), '\n')
	printstyled("┌", handler, ": ";style...)
	println(msglines[1])
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


# ----------------------------------------------------
# --- Internal structures 
# ---------------------------------------------------- l
mutable struct iio_context
end
mutable struct iio_device 
end
mutable struct iio_channel
end
mutable struct iio_buffer
end

mutable struct iio_scan_context
end
mutable struct iio_context_info
end
# ----------------------------------------------------
# --- Rx structures
# ---------------------------------------------------- 
struct PlutoBuffer
    pointerBuffer::Ptr{iio_buffer};
    bufferSize::Csize_t;
	pBeg::Ptr{Cuchar};
	pEnd::Ptr{Cuchar};
end

struct PlutoRxWrapper
	rx0_i::Ptr{iio_channel}; 
	rx0_q::Ptr{iio_channel};  
	chnlRx::Ref{Ptr{iio_channel}};
    chnlRxLo::Ref{Ptr{iio_channel}};
    rx::Ref{Ptr{iio_device}};
end
mutable struct PlutoRx
	iio::PlutoRxWrapper;
	carrierFreq::Float64;
	samplingRate::Float64;
	gain::Union{Int,Float64}; 
	antenna::Cstring;
    packetSize::Csize_t;
    plutoBuffer::PlutoBuffer;
	released::Int;
end
# ----------------------------------------------------
# --- Tx structures 
# ---------------------------------------------------- 
struct PlutoTxWrapper
	tx0_i::Ptr{iio_channel}; 
	tx0_q::Ptr{iio_channel};  
	chnlTx::Ref{Ptr{iio_channel}};
	chnlTxLo::Ref{Ptr{iio_channel}};
    tx::Ref{Ptr{iio_device}};
end
mutable struct PlutoTx
	iio::PlutoTxWrapper;
	carrierFreq::Float64;
	samplingRate::Float64;
	gain::Union{Int,Float64}; 
	antenna::Cstring;
	packetSize::Csize_t;
	released::Int;
end
# ----------------------------------------------------
# --- TRX structures
# ---------------------------------------------------- 
mutable struct PlutoSDR 
	ctx::Ptr{iio_context};
	rx::PlutoRx;
	tx::PlutoTx;
	released::Int;
end
@enum iodev begin
	RX = 0;
	TX = 1;
end

"""
" @assert_pluto macro
# Get the current Pluto state and abord if something bad happens
"""
macro assert_pluto(ex)
	quote 
		local flag = $(esc(ex));
		if flag == Ptr{iio_context}(0);
			# --- Error here abort !
			error("Unable to initialize the Pluto SDR - Check the address");
		end
	end
end


function scan(doPrint=true)
	# Scan context get info list
	con = Base.unsafe_convert(Cstring, "usb");
	scan = ccall((:iio_create_scan_context, libIIO), Ptr{iio_scan_context}, (Cstring, Cint), con, 0);
	# Getting metadata from scan 
	info = Ref{Ptr{Ptr{iio_context_info}}}(0);
	ret = ccall((:iio_scan_context_get_info_list, libIIO), Csize_t, (Ptr{iio_scan_context}, Ptr{Ptr{Ptr{iio_context_info}}}), scan, info)
	# Parse and return parameters
	out = "";
	if ret == 0
		# --- Nothing found
		(doPrint) && (@info "No Pluto device found");
	elseif ret == 1 
		# --- We have one device
		uri = unsafe_load(info[]);
		out = ccall((:iio_context_info_get_uri, libIIO), Cstring, (Ptr{iio_context_info},), uri)
		out = unsafe_string(out);
		(doPrint) && (@info "Found 1 Pluto device with USB address $out");
	end
	return out;
end


function openPluto(carrierFreq, samplingRate, gain;antenna="RX2",ip="auto")

	# --- If ip = auto, scan for USB auto-detection
	if ip == "auto"
		ip = scan(false);
		# If nothing is in output, error
		if ip == ""
			error("Unable to auto-detect address of Pluto device");
		end
	end
	# --- Defining antenna 
	txAntenna = Base.unsafe_convert(Cstring, "A");
	rxAntenna = Base.unsafe_convert(Cstring, "A_BALANCED");
	# --- Create the full context based on remote USB//IP address 
	iioArgs = Base.unsafe_convert(Cstring, ip);
	@assert_pluto ctx = ccall((:iio_create_context_from_uri, libIIO), Ptr{iio_context}, (Cstring,), iioArgs);
	# 
	nbDevice = ccall((:iio_context_get_devices_count, libIIO), Cint, (Ptr{iio_context},), ctx); 

	# --- Init AD9361 
	# Tx
	txM = ccall((:iio_context_find_device, libIIO), Ptr{iio_device}, (Ptr{iio_context}, Cstring), ctx, "cf-ad9361-dds-core-lpc");
	tx = Ref{Ptr{iio_device}}(txM);
	# Rx
	rxM = ccall((:iio_context_find_device, libIIO), Ptr{iio_device}, (Ptr{iio_context}, Cstring), ctx, "cf-ad9361-lpc");
	rx = Ref{Ptr{iio_device}}(rxM);


	# --- Configuring streamers
	chnlTx = get_phy_chan(ctx, TX, 0);
	ccall((:iio_channel_attr_write, libIIO), Cvoid, (Ptr{iio_channel}, Cstring, Cstring), chnlTx[], "rf_port_select", txAntenna);
	ccall((:iio_channel_attr_write_longlong, libIIO), Cvoid, (Ptr{iio_channel}, Cstring, Clonglong), chnlTx[], "rf_bandwidth", samplingRate);
	ccall((:iio_channel_attr_write_longlong, libIIO), Cvoid, (Ptr{iio_channel}, Cstring, Clonglong), chnlTx[], "sampling_frequency", samplingRate);

	chnlRx = get_phy_chan(ctx, RX, 0);
	ccall((:iio_channel_attr_write, libIIO), Cvoid, (Ptr{iio_channel}, Cstring, Cstring), chnlRx[], "rf_port_select", rxAntenna);
	ccall((:iio_channel_attr_write_longlong, libIIO), Cvoid, (Ptr{iio_channel}, Cstring, Clonglong), chnlRx[], "rf_bandwidth", samplingRate);
	ccall((:iio_channel_attr_write_longlong, libIIO), Cvoid, (Ptr{iio_channel}, Cstring, Clonglong), chnlRx[], "sampling_frequency", samplingRate);


	# --- Configuring carrier frequency 
	chnlTxLo = get_lo_chan(ctx, TX, 0);
	chnlRxLo = get_lo_chan(ctx, RX, 0);
	ccall((:iio_channel_attr_write_longlong, libIIO), Cvoid, (Ptr{iio_channel}, Cstring, Clonglong), chnlTxLo[], "frequency", carrierFreq);
	ccall((:iio_channel_attr_write_longlong, libIIO), Cvoid, (Ptr{iio_channel}, Cstring, Clonglong), chnlRxLo[], "frequency", carrierFreq);


	# Configuring I/Q data paths 
	# Rx
	rx0_i = ccall((:iio_device_find_channel, libIIO), Ptr{iio_channel}, (Ptr{iio_device}, Cstring, Cuchar), rx[], "voltage0", false);
	rx0_q = ccall((:iio_device_find_channel, libIIO), Ptr{iio_channel}, (Ptr{iio_device}, Cstring, Cuchar), rx[], "voltage1", false);
	# Tx 
	tx0_i = ccall((:iio_device_find_channel, libIIO), Ptr{iio_channel}, (Ptr{iio_device}, Cstring, Cuchar), tx[], "voltage0", true);
	tx0_q = ccall((:iio_device_find_channel, libIIO), Ptr{iio_channel}, (Ptr{iio_device}, Cstring, Cuchar), tx[], "voltage1", true);

	# Enabling streaming channels 
	ccall((:iio_channel_enable, libIIO), Cvoid, (Ptr{iio_channel},), rx0_i);
	ccall((:iio_channel_enable, libIIO), Cvoid, (Ptr{iio_channel},), rx0_q);
	ccall((:iio_channel_enable, libIIO), Cvoid, (Ptr{iio_channel},), tx0_i);
	ccall((:iio_channel_enable, libIIO), Cvoid, (Ptr{iio_channel},), tx0_q);

	# Printing stuff about context
	# # description = ccall((:iio_context_get_description,libIIO),Cstring,(Ptr{iio_context},),ctx);
	# # pout = unsafe_string(description)
	# # println("description:\n$pout")

	# --- Getting the effective sampling frequency 
	out = repeat(" ", CHAR_SIZE);
	ccS = ccall((:iio_channel_attr_read, libIIO), Clonglong, (Ptr{iio_channel}, Cstring, Cstring, Csize_t), chnlTx[], "sampling_frequency", out, 4 * CHAR_SIZE);
	effectiveSamplingRate = parse(Float64, out[1:ccS - 1]);
	# --- Gettting the effective carrier frequency 
	out = repeat(" ", CHAR_SIZE);
	ccS = ccall((:iio_channel_attr_read, libIIO), Clonglong, (Ptr{iio_channel}, Cstring, Cstring, Csize_t), chnlTxLo[], "frequency", out, 4 * CHAR_SIZE);
    effectiveCarrierFreq = parse(Float64, out[1:ccS - 1]);
    
	# --- Get the packet size & create buffer:
    packetSize = ccall((:iio_device_get_sample_size, libIIO), Clonglong, (Ptr{iio_device},), rx[]);
    plutoBuffer = createBuffer(rx,rx0_i,packetSize);

	# ----------------------------------------------------
	# --- Pack all stuff 
	# ---------------------------------------------------- 
	# --- Create Rx part 
	iioRx = PlutoRxWrapper(
						   rx0_i,
						   rx0_q,
						   chnlRx,
                           chnlRxLo,
                           rx,
						  );
	rx = PlutoRx(
				 iioRx,
				 carrierFreq,
				 effectiveSamplingRate,
				 gain,
				 rxAntenna,
				 packetSize,
                 plutoBuffer,
				 0
				);
	# --- Create Tx part 
	iioTx = PlutoTxWrapper(
						   tx0_i,
						   tx0_q,
						   chnlTx,
                           chnlRxLo,
                           tx
						  );
	tx = PlutoTx(
				 iioTx,
				 effectiveCarrierFreq,
				 effectiveSamplingRate,
				 gain,
				 txAntenna,
                 packetSize,
				 0
				);
	# --- Full structure 
	plutoSDR = PlutoSDR(
						ctx,
						rx,
						tx,
						0,
					   )
	return plutoSDR;
end 

function createBuffer(rx,rx0_i,bufferSize)
	# -- Create match buffer with same size as signal 
	pointerBuffer = ccall((:iio_device_create_buffer, libIIO), Ptr{iio_buffer}, (Ptr{iio_device}, Csize_t, Cuchar), rx[], bufferSize, false);
	pBeg = ccall((:iio_buffer_first, libIIO), Ptr{Cuchar}, (Ptr{iio_buffer}, Ptr{iio_channel}), pointerBuffer, rx0_i);
	pEnd = ccall((:iio_buffer_end, libIIO), Clonglong, (Ptr{iio_buffer},), pointerBuffer);
	# 
	plutoBuffer = PlutoBuffer(
                              pointerBuffer,
                              bufferSize,
							  pBeg,
							  pEnd
	 )
end


function recv(radio::PlutoRx,nbSamples)
    sig = zeros(UInt8,2*nbSamples);
    recv!(sig,radio);
    return sig;
end
recv(radio::PlutoSDR,nbSamples) = recv(radio.rx,nbSamples)
function recv!(sig,radio::PlutoRx;nbSamples=0,offset=0)
	# --- Defined parameters for multiple buffer reception 
	filled		= false;
	# --- Fill the input buffer @ a specific offset 
	if offset == 0 
		posT		= Csize_t(0);
	else 
		posT 		= Csize_t(offset);
	end
	# --- Managing desired size and buffer size
	if nbSamples == 0
		# --- Fill all the buffer  
		# x2 as input is complex and we feed real words
		nbSamples	= Csize_t(length(sig));
	else 
		# ---  x2 as input is complex and we feed real words
		nbSamples 	= Csize_t(nbSamples);
		# --- Ensure that the allocation is possible
		@assert nbSamples < (length(sig)+posT) "Impossible to fill the buffer (number of samples > residual size";
	end
	while !filled 
		# --- Get a buffer: We should have radio.packetSize or less 
		# radio.packetSize is the complex size, so x2
		(posT+radio.packetSize> nbSamples) ? n = nbSamples - posT : n = radio.packetSize;
		# --- To avoid memcopy, we direclty feed the pointer at the appropriate solution
		# ptr=Ref(Ptr{Cvoid}(pointer(sig,1+posT)));
		ptr = pointer(sig,1+posT);
		# --- Populate buffer with radio samples
		cSamples 	= populateBuffer!(radio,ptr,n);
		# --- Update counters 
		posT += cSamples; 
		# @show Int(cSamples),Int(posT)
		# --- Breaking flag
		(posT == nbSamples) ? filled = true : filled = false;
	end
	return posT
end

function populateBuffer!(radio::PlutoRx,ptr,nbSamples::Csize_t=0)
	# --- Getting number of samples 
	# If not specified, we get back to radio.packetSize
	if (nbSamples == Csize_t(0)) 
		nbSamples = radio.packetSize;
	end 
    nbBytes = ccall((:iio_buffer_refill, libIIO), Csize_t, (Ptr{iio_buffer},), radio.plutoBuffer.pointerBuffer);
    # --- Pointer deferencing 
    # unsafe_copyto!(ptr,radio.plutoBuffer.pBeg,nbSamples);
    return Int(nbBytes)
end#



# # function recv!(sig,radio::PlutoSDR;nbSamples=0,offset=0)
# function recv(radio::PlutoSDR, bufferSize);
# 	# --- Create buffer
#     plutoBuffer = createBuffer(radio, bufferSize);

#     # 
#     ccall((:iio_buffer_destroy,libIIO),Cvoid,(Ptr{iio_buffer},),plutoBuffer.pointerBuffer);
# 	return sig;
# end


# function recv!(sig,radio::PlutoSDR,plutoBuffer::PlutoBuffer)
# 	# --- Refill
# 	nbBytes = ccall((:iio_buffer_refill, libIIO), Csize_t, (Ptr{iio_buffer},), plutoBuffer.pointerBuffer);
# 	# @show Int(nbBytes)
#     # --- Populate buffer 
#     @assert (length(sig) == 4 * plutoBuffer.bufferSize) "Input signal does not match internal buffer size";
# 	# sig = zeros(UInt8, 4 * plutoBuffer.bufferSize);
# 	for (i, p) = enumerate(Int(plutoBuffer.pBeg):1:Int(plutoBuffer.pEnd) - 1)
# 		p2 = Ptr{UInt8}(p);
# 		sig[i] = unsafe_load(p2)
#     end
# end



#     # Try to get a buffer 
# #    packetSize = ccall((:iio_device_get_sample_size,libIIO),Clonglong,(Ptr{iio_device},),rx[]);
# #    @show packetSize
# #     sig     = zeros(Csize_t,1024);
# #     ptr     = Ptr{Cvoid}(pointer(sig,1));
# #     nbBytes = ccall((:iio_device_read_raw,libIIO),Clonglong,(Ptr{iio_device},Ptr{Cvoid},Csize_t))
#     bufferSize = 1024;
#     pointerBuffer = ccall((:iio_device_create_buffer,libIIO),Ptr{iio_buffer},(Ptr{iio_device},Csize_t,Cuchar),rx[],bufferSize,false);
#     @show pointerBuffer

#     nbBytes = ccall((:iio_buffer_refill,libIIO),Csize_t,(Ptr{iio_buffer},),pointerBuffer);
#     @show Int(nbBytes)

#     addr = ccall((:iio_buffer_first,libIIO),Ptr{Cuchar},(Ptr{iio_buffer},Ptr{iio_channel}),pointerBuffer,rx0_i);
#     @show addr
#     pInc = ccall((:iio_buffer_step,libIIO),Clonglong,(Ptr{iio_buffer},),pointerBuffer);
#     @show Int(pInc)
#     pEnd = ccall((:iio_buffer_end,libIIO),Clonglong,(Ptr{iio_buffer},),pointerBuffer);
#     @show Int(pEnd)

#     @show Int(pointerBuffer)
#     @show Int(addr)- Int(pointerBuffer) 
#     global sig = zeros(UInt8,4*bufferSize);
#     for (i,p) = enumerate(Int(addr):1:Int(pEnd)-1)
#         p2 = Ptr{UInt8}(p);
#         sig[i] = unsafe_load(p2)
#     end
#     # @show sig
#     # --- Close stuff 
#     flag = ccall((:iio_context_destroy,libIIO),Cint,(Ptr{iio_context},),ctx);

function close(plutoSDR::PlutoSDR)
	if plutoSDR.released == 0
		# --- Disable channels 
		ccall((:iio_channel_disable, libIIO), Cvoid, (Ptr{iio_channel},), plutoSDR.rx.iio.rx0_i);
		ccall((:iio_channel_disable, libIIO), Cvoid, (Ptr{iio_channel},), plutoSDR.rx.iio.rx0_q);
		ccall((:iio_channel_disable, libIIO), Cvoid, (Ptr{iio_channel},), plutoSDR.tx.iio.tx0_i);
        ccall((:iio_channel_disable, libIIO), Cvoid, (Ptr{iio_channel},), plutoSDR.tx.iio.tx0_q);
        # --- Destroy buffer 
        ccall((:iio_buffer_destroy,libIIO),Cvoid,(Ptr{iio_buffer},),plutoSDR.rx.plutoBuffer.pointerBuffer);
		# --- Destroy context 
		flag = ccall((:iio_context_destroy, libIIO), Cint, (Ptr{iio_context},), plutoSDR.ctx); 
		# --- Adding released flags
		plutoSDR.released = 1;
		plutoSDR.tx.released = 1;
		plutoSDR.rx.released = 1;
	else 
		@warn "Pluto has already been released, abord call";
	end
end


function updateCarrierFreq!(rx::PlutoRx, carrierFreq)
	# --- Calling the function to update the carrier frequency 
	ccall((:iio_channel_attr_write_longlong, libIIO), Cvoid, (Ptr{iio_channel}, Cstring, Clonglong), rx.iio.chnlRxLo[], "frequency", carrierFreq); 
	# --- Get the obtained frequency 
	#  Init the container 
	out = repeat(" ", CHAR_SIZE);
	# Calling read method 
	ccS = ccall((:iio_channel_attr_read, libIIO), Clonglong, (Ptr{iio_channel}, Cstring, Cstring, Csize_t), rx.iio.chnlRxLo[], "frequency", out, 4 * CHAR_SIZE);
	# Convert the result into a float
	updateCarrierFrequency = parse(Float64, out[1:ccS - 1]); 
	# Raise a warning if carrier frequency is not the one desired
	if updateCarrierFrequency != carrierFreq
		@warnrx "Effective carrier frequency is $(updateCarrierFrequency / 1e6) MHz and not $(carrierFreq / 1e6) MHz\n" 
	end
	return updateCarrierFrequency;
end
function updateCarrierFreq!(rx::PlutoTx, carrierFreq)
	# --- Calling the function to update the carrier frequency 
	ccall((:iio_channel_attr_write_longlong, libIIO), Cvoid, (Ptr{iio_channel}, Cstring, Clonglong), rx.iio.chnlTxLo[], "frequency", carrierFreq); 
	# --- Get the obtained frequency 
	#  Init the container 
	out = repeat(" ", CHAR_SIZE);
	# Calling read method 
	ccS = ccall((:iio_channel_attr_read, libIIO), Clonglong, (Ptr{iio_channel}, Cstring, Cstring, Csize_t), rx.iio.chnlTxLo[], "frequency", out, 4 * CHAR_SIZE);
	# Convert the result into a float
	updateCarrierFrequency = parse(Float64, out[1:ccS - 1]); 
	# Raise a warning if carrier frequency is not the one desired
	if updateCarrierFrequency != carrierFreq
		@warntx "Effective carrier frequency is $(updateCarrierFrequency / 1e6) MHz and not $(carrierFreq / 1e6) MHz\n" 
	end
	return updateCarrierFrequency;
end
function updateCarrierFreq!(pluto::PlutoSDR, carrierFreq)
	updateCarrierFreq!(pluto.tx, carrierFreq);
	carrierFreq = updateCarrierFreq!(pluto.rx, carrierFreq);
	return carrierFreq;
end

function updateSamplingRate!(tx::PlutoTx, samplingRate)
	# --- Calling the functions to update the sampling frequency
	ccall((:iio_channel_attr_write_longlong, libIIO), Cvoid, (Ptr{iio_channel}, Cstring, Clonglong), tx.iio.chnlTx[], "rf_bandwidth", samplingRate);
	ccall((:iio_channel_attr_write_longlong, libIIO), Cvoid, (Ptr{iio_channel}, Cstring, Clonglong), tx.iio.chnlTx[], "sampling_frequency", samplingRate);
	# --- Get the obtained sampling frequency 
	#  Init the container 
	out = repeat(" ", CHAR_SIZE);
	# Calling read method 
	ccS = ccall((:iio_channel_attr_read, libIIO), Clonglong, (Ptr{iio_channel}, Cstring, Cstring, Csize_t), tx.iio.chnlTx[], "sampling_frequency", out, 4 * CHAR_SIZE);
	updateRate = parse(Float64, out[1:ccS - 1]); 
	if updateRate != samplingRate
		@warntx "Effective Rate is $(updateRate / 1e6) MHz and not $(samplingRate / 1e6) MHz\n" 
	end
	return updateRate;
end
function updateSamplingRate!(rx::PlutoRx, samplingRate)
	# --- Calling the functions to update the sampling frequency
	ccall((:iio_channel_attr_write_longlong, libIIO), Cvoid, (Ptr{iio_channel}, Cstring, Clonglong), rx.iio.chnlRx[], "rf_bandwidth", samplingRate);
	ccall((:iio_channel_attr_write_longlong, libIIO), Cvoid, (Ptr{iio_channel}, Cstring, Clonglong), rx.iio.chnlRx[], "sampling_frequency", samplingRate);
	# --- Get the obtained sampling frequency 
	#  Init the container 
	out = repeat(" ", CHAR_SIZE);
	# Calling read method 
	ccS = ccall((:iio_channel_attr_read, libIIO), Clonglong, (Ptr{iio_channel}, Cstring, Cstring, Csize_t), rx.iio.chnlRx[], "sampling_frequency", out, 4 * CHAR_SIZE);
	updateRate = parse(Float64, out[1:ccS - 1]); 
	if updateRate != samplingRate
		@warnrx "Effective Rate is $(updateRate / 1e6) MHz and not $(samplingRate / 1e6) MHz\n" 
	end
	return updateRate;
end
function updateSamplingRate!(pluto::PlutoSDR, samplingRate)
	updateSamplingRate!(pluto.tx, samplingRate);
	updateRate = updateSamplingRate!(pluto.rx, samplingRate);
	return updateRate;
end


function get_ad9361_phy(ctx)
	p   = Base.unsafe_convert(Cstring, "ad9361-phy");
	dev = ccall((:iio_context_find_device, libIIO), Ptr{iio_device}, (Ptr{iio_context}, Cstring), ctx, p);
	return dev; 
end
function get_phy_chan(ctx, type, chid)
	# --- Board parameters 
	dev = get_ad9361_phy(ctx);
	# --- Channel index 
	p   = Base.unsafe_convert(Cstring, "voltage0");
	#
	if type == TX 
		cc = ccall((:iio_device_find_channel, libIIO), Ptr{iio_channel}, (Ptr{iio_device}, Cstring, Cuchar), dev, p, true);
	else 
		cc = ccall((:iio_device_find_channel, libIIO), Ptr{iio_channel}, (Ptr{iio_device}, Cstring, Cuchar), dev, p, false);
	end
	chnl = Ref(cc);
end
function get_lo_chan(ctx, type, chid)
	# --- Board parameters 
	dev = get_ad9361_phy(ctx);
	# --- Channel index 
	#
	if type == TX 
		p   = Base.unsafe_convert(Cstring, "altvoltage1");
		cc = ccall((:iio_device_find_channel, libIIO), Ptr{iio_channel}, (Ptr{iio_device}, Cstring, Cuchar), dev, p, true);
	else 
		p   = Base.unsafe_convert(Cstring, "altvoltage0");
		cc = ccall((:iio_device_find_channel, libIIO), Ptr{iio_channel}, (Ptr{iio_device}, Cstring, Cuchar), dev, p, true);
	end
	chnl = Ref(cc);
end


function Base.print(pluto::PlutoSDR)
	print(pluto.rx);
	print(pluto.tx);
end
function Base.print(rx::PlutoRx)
	# --- Getting the effective sampling frequency 
	out = repeat(" ", CHAR_SIZE);
	ccS = ccall((:iio_channel_attr_read, libIIO), Clonglong, (Ptr{iio_channel}, Cstring, Cstring, Csize_t), rx.iio.chnlRx[], "sampling_frequency", out, 4 * CHAR_SIZE);
	effectiveSamplingRate = parse(Float64, out[1:ccS - 1]); 
	# --- Getting the effective carrier frequency 
	out = repeat(" ", CHAR_SIZE);
	ccS = ccall((:iio_channel_attr_read, libIIO), Clonglong, (Ptr{iio_channel}, Cstring, Cstring, Csize_t), rx.iio.chnlRxLo[], "frequency", out, 4 * CHAR_SIZE);
	effectiveCarrierFreq = parse(Float64, out[1:ccS - 1]); 
	# --- Packing and print 
	strF = @sprintf(" Carrier Frequency: %2.3f MHz\n\tSampling Frequency: %2.3f MHz\n",effectiveCarrierFreq / 1e6,effectiveSamplingRate / 1e6);
	@inforx strF;
end
function Base.print(tx::PlutoTx)
	# --- Getting the effective sampling frequency 
	out = repeat(" ", CHAR_SIZE);
	ccS = ccall((:iio_channel_attr_read, libIIO), Clonglong, (Ptr{iio_channel}, Cstring, Cstring, Csize_t), tx.iio.chnlTx[], "sampling_frequency", out, 4 * CHAR_SIZE);
	effectiveSamplingRate = parse(Float64, out[1:ccS - 1]); 
	# --- Getting the effective carrier frequency 
	out = repeat(" ", CHAR_SIZE);
	ccS = ccall((:iio_channel_attr_read, libIIO), Clonglong, (Ptr{iio_channel}, Cstring, Cstring, Csize_t), tx.iio.chnlTxLo[], "frequency", out, 4 * CHAR_SIZE);
	effectiveCarrierFreq = parse(Float64, out[1:ccS - 1]); 
	# --- Packing and print 
	strF = @sprintf(" Carrier Frequency: %2.3f MHz\n\tSampling Frequency: %2.3f MHz\n",effectiveCarrierFreq / 1e6,effectiveSamplingRate / 1e6);
	@infotx strF;
end

end
