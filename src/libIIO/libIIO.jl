module libIIO_jl

using Preferences
using Libdl
# Regarding type convertions :
#   - Basic types as arguments need to be passed as the corresponding Julia type to the wrapper function.
#   - Basic types as return values keep the Ctype alias and are not converted to "native" Julia type.
#   Ex: If the C function returns a size_t, the wrapper function returns a Csize_t (or long long -> Clonglong)
# This is done to keep the maximum transparency as to what the C function needs, does, and returns
# When the C function needs a pointer, a reference to a native Julia type is used.


""" 
Change libIIO Ldriver provider. Support "yggdrasil" to use shipped jll file or "local" to use custom installed library
set_provider("yggdrasil")
or 
set_provider("local")
"""
# We export here to be sure it is seen @AdalmPluto level
function set_provider(new_provider::String)
    if !(new_provider in ("yggdrasil", "local"))
        throw(ArgumentError("Invalid provider: \"$(new_provider)\""))
    end
    # Set it in our runtime values, as well as saving it to disk
    @set_preferences!("provider" => new_provider)
    @info("New provider set; restart your Julia session for this change to take effect!")
end
function get_provider()
    return @load_preference("provider","yggdrasil")
end
const libiio_provider = get_provider()
@static  if libiio_provider == "yggdrasil"
    # --- Using Yggdrasil jll file 
    using libiio_jll
    const libIIO = libiio_jll.libiio
end
@static if libiio_provider == "local"
    # --- Using local install, assuming it works
    libIIO_system_h = dlopen("libiio", false);
    const libIIO = dlpath(libIIO_system_h)
end


# needed for libIIO functions
const BUF_SIZE = 2^12; # same value as iio_common.h
const C_INT_MAX = 2^31 - 1;
# disable Julia errors and return the NULL/error code instead
NO_ASSERT = false;

# adds a udev rule needed for usb devices
# should be a volatile rule and will need to be added each boot
# but it makes it possible to delete the artifact without leftovers
function __init__()
    # This workflow is only valid for Linux machines, as there is no rules for MACOS
    if Sys.islinux()
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
end

# helpers
include("helpers.jl");
export
    toggleNoAssertions
;

# structures exports
include("structures.jl");
export
    iio_context_info,
    iio_scan_block,
    iio_scan_context,
    iio_context,
    iio_device,
    iio_channel,
    iio_buffer,
    iio_data_format,
    iio_modifier,                           # enum
    iio_chan_type                           # enum
;

# scan exports
include("scan.jl");
export
   C_iio_context_info_get_description,
   C_iio_context_info_get_uri,
   C_iio_context_info_list_free,
   C_iio_create_scan_block,
   C_iio_create_scan_context,
   C_iio_scan_block_destroy,
   C_iio_scan_block_get_info,
   C_iio_scan_block_scan,
   C_iio_scan_context_destroy,
   C_iio_scan_context_get_info_list
;

# toplevel exports
include("toplevel.jl");
export
    C_iio_get_backend,
    C_iio_get_backends_count,
    C_iio_has_backend,
    C_iio_library_get_version,
    C_iio_strerror
;

# context exports
include("context.jl");
export
    C_iio_context_clone,
    C_iio_context_destroy,
    C_iio_context_find_device,
    C_iio_context_get_attr,
    C_iio_context_get_attr_value,
    C_iio_context_get_attrs_count,
    C_iio_context_get_description,
    C_iio_context_get_device,
    C_iio_context_get_devices_count,
    C_iio_context_get_name,
    C_iio_context_get_version,
    C_iio_context_get_xml,
    C_iio_context_set_timeout,
    C_iio_create_context_from_uri,
    C_iio_create_default_context,
    C_iio_create_local_context,
    C_iio_create_network_context,
    C_iio_create_xml_context,
    C_iio_create_xml_context_mem
;

# device exports
include("device.jl");
export
    C_iio_device_attr_read,
    C_iio_device_attr_read_all,             # PLACEHOLDER : function pointer needed
    C_iio_device_attr_read_bool,
    C_iio_device_attr_read_double,
    C_iio_device_attr_read_longlong,
    C_iio_device_attr_write,
    C_iio_device_attr_write_all,            # PLACEHOLDER : function pointer needed
    C_iio_device_attr_write_bool,
    C_iio_device_attr_write_double,
    C_iio_device_attr_write_longlong,
    C_iio_device_attr_write_raw,
    C_iio_device_buffer_attr_read,
    C_iio_device_buffer_attr_read_all,      # PLACEHOLDER : function pointer needed
    C_iio_device_buffer_attr_read_bool,
    C_iio_device_buffer_attr_read_double,
    C_iio_device_buffer_attr_read_longlong,
    C_iio_device_buffer_attr_write,
    C_iio_device_buffer_attr_write_all,     # PLACEHOLDER : function pointer needed
    C_iio_device_buffer_attr_write_bool,
    C_iio_device_buffer_attr_write_double,
    C_iio_device_buffer_attr_write_longlong,
    C_iio_device_buffer_attr_write_raw,
    C_iio_device_find_attr,
    C_iio_device_find_buffer_attr,
    C_iio_device_find_channel,
    C_iio_device_get_attr,
    C_iio_device_get_attrs_count,
    C_iio_device_get_buffer_attr,
    C_iio_device_get_buffer_attrs_count,
    C_iio_device_get_channel,
    C_iio_device_get_channels_count,
    C_iio_device_get_context,
    C_iio_device_get_data,
    C_iio_device_get_id,
    C_iio_device_get_name,
    C_iio_device_get_trigger,
    C_iio_device_is_trigger,
    C_iio_device_set_data,
    C_iio_device_set_kernel_buffers_count,
    C_iio_device_set_trigger
;

# channel exports
include("channel.jl");
export
    C_iio_channel_attr_get_filename,
    C_iio_channel_attr_read,
    C_iio_channel_attr_read_all,            # PLACEHOLDER : function pointer needed
    C_iio_channel_attr_read_bool,
    C_iio_channel_attr_read_double,
    C_iio_channel_attr_read_longlong,
    C_iio_channel_attr_write,
    C_iio_channel_attr_write_all,           # PLACEHOLDER : function pointer needed
    C_iio_channel_attr_write_bool,
    C_iio_channel_attr_write_double,
    C_iio_channel_attr_write_longlong,
    C_iio_channel_attr_write_raw,
    C_iio_channel_disable,
    C_iio_channel_enable,
    C_iio_channel_find_attr,
    C_iio_channel_get_attr,
    C_iio_channel_get_attrs_count,
    C_iio_channel_get_data,
    C_iio_channel_get_device,
    C_iio_channel_get_id,
    C_iio_channel_get_modifier,
    C_iio_channel_get_name,
    C_iio_channel_get_type,
    C_iio_channel_is_enabled,
    C_iio_channel_is_output,
    C_iio_channel_is_scan_element,
    #  C_iio_channel_read,
    C_iio_channel_read!,
    C_iio_channel_read_raw,                 # PLACEHOLDER : data format
    C_iio_channel_set_data,
    C_iio_channel_write,                    # PLACEHOLDER : data format
    C_iio_channel_write_raw                 # PLACEHOLDER : data format
;

# buffer exports
include("buffer.jl");
export
    C_iio_buffer_cancel,
    C_iio_buffer_destroy,
    C_iio_buffer_end,
    C_iio_buffer_first,
    C_iio_buffer_foreach_sample,            # PLACEHOLDER : function pointer needed
    C_iio_buffer_get_data,
    C_iio_buffer_get_device,
    C_iio_buffer_get_poll_fd,
    C_iio_buffer_push,
    C_iio_buffer_push_partial,
    C_iio_buffer_refill,
    C_iio_buffer_set_blocking_mode,
    C_iio_buffer_set_data,
    C_iio_buffer_start,
    C_iio_buffer_step,
    C_iio_device_create_buffer
;

# debug exports
include("debug.jl");
export
    C_iio_device_get_sample_size,
    C_iio_device_identify_filename
;

end
