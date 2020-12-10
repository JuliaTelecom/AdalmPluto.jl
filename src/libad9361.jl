# clone of https://github.com/analogdevicesinc/libad9361-iio/blob/master/ad9361_baseband_auto_rate.c

export
    ad9361_get_trx_fir_enable,
    ad9361_set_trx_fir_enable,
    ad9361_baseband_auto_rate
;

# size of the string buffer
const FIR_BUF_SIZE = 8192;

# default filters
const fir_128_4 = Int16[
    -15,-27,-23,-6,17,33,31,9,-23,-47,-45,-13,34,69,67,21,-49,-102,-99,-32,69,146,143,48,-96,-204,-200,-69,129,278,275,97,-170,
    -372,-371,-135,222,494,497,187,-288,-654,-665,-258,376,875,902,363,-500,-1201,-1265,-530,699,1748,1906,845,-1089,-2922,-3424,
    -1697,2326,7714,12821,15921,15921,12821,7714,2326,-1697,-3424,-2922,-1089,845,1906,1748,699,-530,-1265,-1201,-500,363,902,875,
    376,-258,-665,-654,-288,187,497,494,222,-135,-371,-372,-170,97,275,278,129,-69,-200,-204,-96,48,143,146,69,-32,-99,-102,-49,21,
    67,69,34,-13,-45,-47,-23,9,31,33,17,-6,-23,-27,-15
];
const fir_128_2 = Int16[
    -0,0,1,-0,-2,0,3,-0,-5,0,8,-0,-11,0,17,-0,-24,0,33,-0,-45,0,61,-0,-80,0,104,-0,-134,0,169,-0,
	-213,0,264,-0,-327,0,401,-0,-489,0,595,-0,-724,0,880,-0,-1075,0,1323,-0,-1652,0,2114,-0,-2819,0,4056,-0,-6883,0,20837,32767,
	20837,0,-6883,-0,4056,0,-2819,-0,2114,0,-1652,-0,1323,0,-1075,-0,880,0,-724,-0,595,0,-489,-0,401,0,-327,-0,264,0,-213,-0,
	169,0,-134,-0,104,0,-80,-0,61,0,-45,-0,33,0,-24,-0,17,0,-11,-0,8,0,-5,-0,3,0,-2,-0,1,0,-0, 0
];
const fir_96_2 = Int16[
    -4,0,8,-0,-14,0,23,-0,-36,0,52,-0,-75,0,104,-0,-140,0,186,-0,-243,0,314,-0,-400,0,505,-0,-634,0,793,-0,
	-993,0,1247,-0,-1585,0,2056,-0,-2773,0,4022,-0,-6862,0,20830,32767,20830,0,-6862,-0,4022,0,-2773,-0,2056,0,-1585,-0,1247,0,-993,-0,
	793,0,-634,-0,505,0,-400,-0,314,0,-243,-0,186,0,-140,-0,104,0,-75,-0,52,0,-36,-0,23,0,-14,-0,8,0,-4,0
];
const fir_64_2 = Int16[
    -58,0,83,-0,-127,0,185,-0,-262,0,361,-0,-488,0,648,-0,-853,0,1117,-0,-1466,0,1954,-0,-2689,0,3960,-0,-6825,0,20818,32767,
	20818,0,-6825,-0,3960,0,-2689,-0,1954,0,-1466,-0,1117,0,-853,-0,648,0,-488,-0,361,0,-262,-0,185,0,-127,-0,83,0,-58,0
];

# returns the return code of the C function
function ad9361_set_trx_fir_enable(device::Ptr{iio_device}, enable::Bool)
    ret, channel, attribute = C_iio_device_identify_filename(device, "in_out_voltage_filter_fir_en");
    if ret < 0
        return ret;
    end
    return C_iio_channel_attr_write_bool(channel, attribute, enable);
end

# returns the return code of the C function and the value (needs to be discarded if the code < 0)
function ad9361_get_trx_fir_enable(device::Ptr{iio_device})
    ret, channel, attribute = C_iio_device_identify_filename(device, "in_out_voltage_filter_fir_en");
    if ret < 0
        return ret, false;
    end
    return C_iio_channel_attr_read_bool(channel, attribute);
end

function ad9361_baseband_auto_rate(device::Ptr{iio_device}, rate::Int64)
    if rate <= 2e7
        decimation = 4;
        taps = 128;
        fir = fir_128_4;
    elseif rate <= 4e7
        decimation = 2;
        taps = 128;
        fir = fir_128_2;
    elseif rate <= 53_333_333
        decimation = 2;
        taps = 96;
        fir = fir_96_2;
    else
        decimation = 2;
        taps = 64;
        fir = fir_64_2;
    end

    try
        global channel = C_iio_device_find_channel(device, "voltage0", true);
    catch
        return -19 # -ENODEV (I think)
    end

    ret, current_rate = C_iio_channel_attr_read_longlong(channel, "sampling_frequency");
    if ret < 0; return ret; end;
    ret, is_fir_enabled = ad9361_get_trx_fir_enable(device);
    if ret < 0; return ret; end;

    if is_fir_enabled
        if current_rate <= 25e6 / 2
            C_iio_channel_attr_write_longlong(channel, "sampling_frequency", 3e6);
        end
        if (ret = ad9361_set_trx_fir_enable(device, false)) < 0
            return ret;
        end
    end

    fir_buffer = "RX 3 GAIN -6 DEC $decimation\nTX 3 GAIN 0 INT $decimation\n";
    fir_buffer *= join(map(c -> "$c,$c\n", fir));
    fir_buffer *= "\n";

    ret = C_iio_device_attr_write_raw(device, "filter_fir_config", fir_buffer);
    if ret < 0; return ret; end;

    if rate <= 25e6 / 12
        ret, value_buffer = C_iio_device_attr_read(device, "tx_path_rates");
        dac_rate = parse(Int64, match(r"(?:DAC:)(\d+)", value_buffer).captures[]);
        tx_rate  = parse(Int64, match(r"(?:TXSAMP:)(\d+)", value_buffer).captures[]);
        if tx_rate == 0; return -22; end; # -EINVAL

        max = (dac_rate / tx_rate) * 16;
        if max < taps
            C_iio_channel_attr_write_longlong(channel, "sampling_frequency", 3e6);
        end
        if (ret = ad9361_set_trx_fir_enable(device, true)) < 0
            return ret;
        end
        if (ret = C_iio_channel_attr_write_longlong(channel, "sampling_frequency", rate)) < 0
            return ret;
        end
    else
        if (ret = C_iio_channel_attr_write_longlong(channel, "sampling_frequency", rate)) < 0
            return ret;
        end
        if (ret = ad9361_set_trx_fir_enable(device, true)) < 0
            return ret;
        end
    end

    return 0;
end
