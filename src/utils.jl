function nbytesToType(nbytes::Cssize_t)
    types = Nothing, Nothing;
    normalizing_factors = Nothing, Nothing;
    if nbytes == 1
        types = UInt8, Int8;
        normalizing_factors = 2^8 - 1, 2^7;
    elseif nbytes == 2
        types = UInt16, Int16;
        normalizing_factors = 2^16 - 1, 2^15;
    elseif nbytes == 4
        types = UInt32, Int32;
        normalizing_factors = 2^32 - 1, 2^31;
    elseif nbytes == 8
        types = UInt64, Int64;
        normalizing_factors = 2^64 - 1, 2^63;
    end
    return types..., normalizing_factors...;
end

# --- Pretty printing functions --- #

# To print fancy message with different colors with Tx and Rx
function customPrint(str, handler;style...)
	msglines = split(chomp(str), '\n');
    length(msglines) > 1 ? symb = "┌" : symb = "[";
	printstyled(symb, handler, ": ";style...);
	println(msglines[1]);
	for i in 2:length(msglines)
		(i == length(msglines)) ? symb = "└ " : symb = "|";
		printstyled(symb;style...);
		println(msglines[i]);
	end
end

"""
    @infoPluto TRX str

Prints custom info messages for either Rx or Tx.

# Example
- `@infoPluto :RX "msg"` to print a warning concerning the Rx part.
- `@infoPluto :TX "msg"` to print a warning concerning the Tx part.
"""

macro infoPluto(TRX, str)
    quote
        TRX = $(TRX);
        if TRX == :RX
            customPrint($(esc(str)), "Rx";bold=true,color=:light_blue)
        else TRX == :TX
            customPrint($(esc(str)), "Tx";bold=true,color=:light_blue)
        end
    end
end

"""
    @warnPluto TRX str

Prints custom warnings for either Rx or Tx.

# Example
- `@warnPluto :RX "msg"` to print a warning concerning the Rx part.
- `@warnPluto :TX "msg"` to print a warning concerning the Tx part.
"""
macro warnPluto(TRX, str)
    quote
        TRX = $(TRX);
        if TRX == :RX
            customPrint($(esc(str)), "Rx Warning";bold=true,color=:light_yellow)
        else TRX == :TX
            customPrint($(esc(str)), "Tx Warning";bold=true,color=:light_yellow)
        end
    end
end
 
""" 
Returns the list of the available backends in Pluto, as a Vector of Strings 
str = getBackends()
    str = ["usb";"ip";"xml"]
"""
function getBackends()
    # We do not have directly the backend names, but we can get the count, and then iterate to get the names
    nbBackend = C_iio_get_backends_count() 
    str = String[] 
    for n ∈ 1 : nbBackend
        # --- Try to get  backend name 
        s = C_iio_get_backend(UInt32(n-1))
        # This should not be "" 
        if !isempty(s)
            # --- Try to load backend to see if everything is fine 
            flag = C_iio_has_backend(s)
            if flag == true
                # --- Store the backend 
                push!(str,s)
            end
        end
    end
    return str 
end

# Export udev rules
set_udev_rules = libIIO_jl.set_udev_rules
