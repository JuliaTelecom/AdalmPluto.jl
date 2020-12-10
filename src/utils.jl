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

# TODO: macro/function to print errors

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

