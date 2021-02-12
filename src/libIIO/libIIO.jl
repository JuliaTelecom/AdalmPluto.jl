module libIIO_jl

# TODO: if I have the time, look into bindgen

# TODO: make it possible to provide buffers / variables
# TODO: convert C numeric types to julia types
# TODO: T E S T S (a lot of implicit conversions)
# Cstring always converted
# No number conversion
# Probably contains typos

using Pkg.Artifacts;

# init globals and lib path
const libIIO_rootpath = artifact"libIIO";
const libIIO = joinpath(libIIO_rootpath, "libiio.so");
# needed for libIIO functions, maybe move them ?
# TODO : remove ?
const BUF_SIZE = 2^12; # same value as iio_common.h
const C_INT_MAX = 2^31 - 1;
# disable Julia errors and return the NULL/error code instead
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

# helpers
include("helpers.jl");
export
    toggleNoAssertions
;

# iio structures
include("structures.jl");

# wrappers
include("scan.jl");
include("toplevel.jl");
include("context.jl");
include("device.jl");
include("channel.jl");
include("buffer.jl");
include("debug.jl");

# structures exports
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
export
    C_iio_get_backend,
    C_iio_get_backends_count,
    C_iio_has_backend,
    C_iio_library_get_version,
    C_iio_strerror
;

# context exports
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
    C_iio_channel_read,
    C_iio_channel_read!,
    C_iio_channel_read_raw,                 # PLACEHOLDER : data format ?
    C_iio_channel_set_data,
    C_iio_channel_write,                    # PLACEHOLDER : data format ?
    C_iio_channel_write_raw                 # PLACEHOLDER : data format ?
;

# buffer exports
export
    C_iio_buffer_cancel,
    C_iio_buffer_destroy,
    C_iio_buffer_end,
    C_iio_buffer_first,
    C_iio_buffer_foreach_sample,            # PLACEHOLDER
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
export
    C_iio_device_get_sample_size,
    C_iio_device_identify_filename
;

end
