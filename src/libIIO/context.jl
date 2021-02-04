"""
    C_iio_context_clone(context)

Duplicate a pre-existing IIO context.

# Parameters
- `context::Ptr{iio_context}` : A pointer to an iio_context structure

# Returns
- On success, A pointer to an iio_context structure
- On failure, throws an error if the assertions are enabled, or NULL otherwise.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Context.html#ga1815e7c39b9a69aa11cf948b0433df01)
"""
function C_iio_context_clone(context::Ptr{iio_context})
    @assert_null_pointer clone = ccall(
        (:iio_context_clone, libIIO),
        Ptr{iio_context}, (Ptr{iio_context},),
        context
    );
    return clone;
end

"""
    C_iio_context_destroy(context)

Destroy the given context.

# Parameters
- `context::Ptr{iio_context}` : A pointer to an iio_context structure

# NOTE
After that function, the iio_context pointer shall be invalid.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Context.html#ga75de8dae515c539818e52b408830d3ba)
"""
function C_iio_context_destroy(context::Ptr{iio_context})
    ccall(
        (:iio_context_destroy, libIIO),
        Cvoid, (Ptr{iio_context},),
        context
    );
end

"""
    C_iio_context_find_device(context, name)

Try to find a device structure by its name of ID.

# Parameters
- `context::Ptr{iio_context}` : A pointer to an iio_context structure
- `name::String` : A NULL-terminated string corresponding to the name or the ID of the device to search for

# Returns
- On success, a pointer to an iio_device structure
- If the name or ID does not correspond to any known device, an error is thrown if the assertions are enabled, or NULL otherwise.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Context.html#gade1dadfb5bc3c3b236add67f803c50c3)
"""
function C_iio_context_find_device(context::Ptr{iio_context}, name::String)
    @assert_null_pointer device = ccall(
        (:iio_context_find_device, libIIO),
        Ptr{iio_device}, (Ptr{iio_context}, Cstring),
        context, name
    );
    return device;
end

"""
    C_iio_context_get_attr(context, index)

Retrieve the name and value of a context-specific attribute.

# Parameters
- `context::Ptr{iio_context}` : A pointer to an iio_context structure
- `index::UInt32` : The index corresponding to the attribute

# Returns
- On success, `(0, name::String, value::String)` is returned.
- On error, `(errno, "", "")` is returned, where errno is a negative code.

Introduced in version 0.9.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Context.html#ga477dfddaefe0acda401f600247e13fc7)
"""
# TODO: TEST
function C_iio_context_get_attr(context::Ptr{iio_context}, index::UInt32)
    name, value = Ref{Cstring}(), Ref{Cstring}();
    ret = ccall(
        (:iio_context_get_attr, libIIO),
        Cint, (Ptr{iio_context}, Cuint, Ptr{Cstring}, Ptr{Cstring}),
        context, index, name, value
    );
    return (ret == 0) ? (ret, Base.unsafe_string(name[]), Base.unsafe_string(value[])) : (ret, "", "");
end

"""
    C_iio_context_get_attr_value(context, name)

Retrieve the value of a context-specific attribute.

# Parameters
- `context::Ptr{iio_context}` : A pointer to an iio_context structure
- `name::String` : The name of the context attribute to read

Returns
- On success, a NULL-terminated string.
- If the name does not correspond to any attribute and the assertions are enabled, throws an error.

Introduced in version 0.9.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Context.html#ga6394d108d425e4a6ed28d00c0e93d6ed)
"""
# TODO: do something about null if the assertions are disabled
function C_iio_context_get_attr_value(context::Ptr{iio_context}, name::String)
    @assert_Cstring value = ccall(
        (:iio_context_get_attr_value, libIIO),
        Cstring, (Ptr{iio_context}, Cstring),
        context, name
    );
    return Base.unsafe_string(value);
end

"""
    C_iio_context_get_attrs_count(context)

Get the number of context-specific attributes.

# Parameters
- `context::Ptr{iio_context}` : A pointer to an iio_context structure

# Returns
- The number of context-specific attributes

Introduced in version 0.9.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Context.html#ga91e0c4ed91d760b411d4cbea28c993da)
"""
function C_iio_context_get_attrs_count(context::Ptr{iio_context})
    return ccall(
        (:iio_context_get_attrs_count, libIIO),
        Cuint, (Ptr{iio_context},),
        context
    );
end

"""
    C_iio_context_get_description(context)

Get a description of the given context.

# Parameters
- `context::Ptr{iio_context}` : A pointer to an iio_context structure

# Returns
- A NULL-terminated string

# NOTE
The returned string will contain human-readable information about the current context.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Context.html#ga5591da0927887e88be4ef7d670cb60a9)
"""
function C_iio_context_get_description(context::Ptr{iio_context})
    return Base.unsafe_string(ccall(
        (:iio_context_get_description, libIIO),
        Cstring, (Ptr{iio_context},),
        context
    ));
end

"""
    C_iio_context_get_device(context, index)

Get the device present at the given index.

# Parameters
- `context::Ptr{iio_context}` : A pointer to an iio_context structure
- `index::UInt32` : The index corresponding to the device

# Returns
- On success, a pointer to an iio_device structure
- If the index is invalid and the assertions are enabled, an error is thrown.
- If the index is invalid and the assertions are disabled, NULL is returned.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Context.html#ga3f2813ff34bf96c7c85dd05909f1c709)
"""
function C_iio_context_get_device(context::Ptr{iio_context}, index::UInt32)
    @assert_null_pointer device = ccall(
        (:iio_context_get_device, libIIO),
        Ptr{iio_device}, (Ptr{iio_context}, Cuint),
        context, index
    );
    return device;
end

"""
    C_iio_context_get_devices_count(context)

Enumerate the devices found in the given context.

# Parameters
- `context::Ptr{iio_context}` : A pointer to an iio_context structure

# Returns
- The number of devices found

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Context.html#gab4fc2a93fd5824f3c9e06aa81e8097d1)
"""
function C_iio_context_get_devices_count(context::Ptr{iio_context})
    return ccall(
        (:iio_context_get_devices_count, libIIO),
        Cuint, (Ptr{iio_context},),
        context
    );
end

"""
    C_iio_context_get_name(context)

Get the name of the given context.

# Parameters
- `context::Ptr{iio_context}` : A pointer to an iio_context structure

# Returns
- A NULL-terminated string

# NOTE
The returned string will be local, xml or network when the context has been created with the local, xml and network backends respectively.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Context.html#gafed8e036873ad6f70c3db92c7136ad31)
"""
function C_iio_context_get_name(context::Ptr{iio_context})
    return Base.unsafe_string(ccall(
        (:iio_context_get_name, libIIO),
        Cstring, (Ptr{iio_context},),
        context
    ));
end

"""
    C_iio_context_get_version(context)

Get the version of the backend in use.

# Parameters
- `context::Ptr{iio_context}` : A pointer to an iio_context structure

# Returns
- `ret::Int` : 0 if no errors, negative error code otherwise
- `major::Int` : The major version
- `minor::Int` : The minor version
- `git_tag::String` : The git tag

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Context.html#ga342bf90d946e7ed3815372db22c4d3a6)
"""
function C_iio_context_get_version(context::Ptr{iio_context})
    major, minor, git_tag = 0, 0, zeros(UInt8, 8);
    ret = ccall(
        (:iio_context_get_version, libIIO),
        Cint, (Ptr{iio_context}, Ptr{Cuint}, Ptr{Cuint}, Ptr{Cchar}),
        context, Ref{UInt32}(major), Ref{UInt32}(minor), Ref(git_tag)
    );
    return ret, major, minor, toString(git_tag);
end

"""
    C_iio_context_get_xml(context)

Obtain a XML representation of the given context.

# Parameters
- `context::Ptr{iio_context}` : A pointer to an iio_context structure

# Returns
- A NULL-terminated string

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Context.html#ga86554706f17faf41e61e3295dc68a70c)
"""
function C_iio_context_get_xml(context::Ptr{iio_context})
    return Base.unsafe_string(ccall(
        (:iio_context_get_xml, libIIO),
        Cstring, (Ptr{iio_context},),
        context
    ));
end

"""
    C_iio_context_set_timeout(context, timeout_ms)

Set a timeout for I/O operations.

# Parameters
- `context::Ptr{iio_context}` : A pointer to an iio_context structure
- `timeout_ms::UInt32` : A positive integer representing the time in milliseconds after which a timeout occurs. A value of 0 is used to specify that no timeout should occur.

# Returns
- On success, 0 is returned
- On error, a negative errno code is returned

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Context.html#gaba3f4c4f9f885f41a6c0b9ac79b7f28d)
"""
function C_iio_context_set_timeout(context::Ptr{iio_context}, timeout_ms::UInt32)
    return ccall(
        (:iio_context_set_timeout, libIIO),
        Cint, (Ptr{iio_context}, Cuint),
        context, timeout_ms
    );
end

"""
    C_iio_create_context_from_uri(uri)

Create a context from a URI description.

# Parameters
- `uri::String` : A URI describing the context location

# Returns
- On success, a pointer to a iio_context structure
- On failure, if the assertions are enabled, an error is thrown.
- On failure, if the assertions are disabled, NULL is returned.

# NOTE
The following URIs are supported based on compile time backend support:

- Local backend, "local:":
    Does not have an address part. For example "local:"

- XML backend, "xml:"
    Requires a path to the XML file for the address part. For example "xml:/home/user/file.xml"

- Network backend, "ip:"
    Requires a hostname, IPv4, or IPv6 to connect to a specific running IIO Daemon or no address part for automatic discovery when library is compiled with ZeroConf support. For example "ip:192.168.2.1", or "ip:localhost", or "ip:" or "ip:plutosdr.local"

- USB backend, "usb:"
    When more than one usb device is attached, requires bus, address, and interface parts separated with a dot. For example "usb:3.32.5". Where there is only one USB device attached, the shorthand "usb:" can be used.

- Serial backend, "serial:" requires :
    + a port (/dev/ttyUSB0),
    + baud_rate (default 115200)
    + serial port configuration
        - data bits (5 6 7 8 9)
        - parity ('n' none, 'o' odd, 'e' even, 'm' mark, 's' space)
        - stop bits (1 2)
        - flow control ('\0' none, 'x' Xon Xoff, 'r' RTSCTS, 'd' DTRDSR)
    + For example "serial:/dev/ttyUSB0,115200" or "serial:/dev/ttyUSB0,115200,8n1"

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Context.html#gafdcee40508700fa395370b6c636e16fe)
"""
function C_iio_create_context_from_uri(uri::String)
    @assert_null_pointer context = ccall(
        (:iio_create_context_from_uri, libIIO),
        Ptr{iio_context}, (Cstring,),
        uri
    );
    return context;
end

"""
    C_iio_create_default_context()

Create a context from local or remote IIO devices.

# Returns
- On success, A pointer to an iio_context structure
- On failure, if the assertions are enabled, an error is thrown
- On failure, if the assertions are disabled, NULL is returned

# NOTE
This function will create a network context if the IIOD_REMOTE environment variable is set to the hostname where the IIOD server runs.
If set to an empty string, the server will be discovered using ZeroConf. If the environment variable is not set, a local context will be created instead.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Context.html#ga21076125f817a680e0c01d4a490f0416)
"""
function C_iio_create_default_context()
    @assert_null_pointer context = ccall(
        (:iio_create_default_context, libIIO),
        Ptr{iio_context}, ()
    );
    return context;
end

"""
    C_iio_create_local_context()

Create a context from local IIO devices (Linux only)

# Returns
- On success, A pointer to an iio_context structure
- On failure, if the assertions are enabled, an error is thrown.
- On failure, if the assertions are disabled, NULL is returned.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Context.html#gaf31acec2d0f9f498870cc52a1d49783e)
"""
function C_iio_create_local_context()
    @assert_null_pointer context = ccall(
        (:iio_create_local_context, libIIO),
        Ptr{iio_context}, ()
    );
    return context;
end

"""
    C_iio_create_network_context(host)

Create a context from the network.

# Parameters
- `host::String` : Hostname, IPv4 or IPv6 address where the IIO Daemon is running

# Returns
- On success, A pointer to an iio_context structure
- On failure, if the assertions are enabled, an error is thrown.
- On failure, if the assertions are disabled, NULL is returned.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Context.html#ga8adf2ef4d2b62aa34201469cd7049617)
"""
function C_iio_create_network_context(host::String)
    @assert_null_pointer context = ccall(
        (:iio_create_network_context, libIIO),
        Ptr{iio_context}, (Cstring,),
        host
    );
    return context;
end

"""
    C_iio_create_xml_context(xml_file)

Create a context from a XML file.

# Parameters
- `xml_file::String` : Path to the XML file to open

# Returns
- On success, A pointer to an iio_context structure
- On failure, if the assertions are enabled, an error is thrown.
- On failure, if the assertions are disabled, NULL is returned.

# NOTE
The format of the XML must comply to the one returned by `iio_context_get_xml`.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Context.html#ga9925a84e596c3003e30b1cdd2b65d029)
"""
function C_iio_create_xml_context(xml_file::String)
    @assert_null_pointer context = ccall(
        (:iio_create_xml_context, libIIO),
        Ptr{iio_context}, (Cstring,),
        xml_file
    );
    return context;
end

"""
    C_iio_create_xml_context_mem(xml, length)

Create a context from XML data in memory.

# Parameters
- `xml::String` : Pointer to the XML data in memory
- `length::UInt` : Length of the XML string in memory (excluding the final \0)

# Returns
- On success, A pointer to an iio_context structure
- On failure, if the assertions are enabled, an error is thrown.
- On failure, if the assertions are disabled, NULL is returned.

# NOTE
The format of the XML must comply to the one returned by `iio_context_get_xml`

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Context.html#gabaa848ca554af5723a44b9b7fd0ba6a3)
"""
function C_iio_create_xml_context_mem(xml::String, length::UInt)
    @assert_null_pointer context = ccall(
        (:iio_create_xml_context_mem, libIIO),
        Ptr{iio_context}, (Cstring, Csize_t),
        xml, length
    );
end
