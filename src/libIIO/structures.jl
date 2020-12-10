# ------------------ #
# --- Structures --- #
# ------------------ #

"""
    iio_context_info

Empty struct to manage pointers to the `iio_context_info` C struct.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/structiio__context__info.html)
"""
mutable struct iio_context_info
end

"""
    iio_scan_block

Empty struct to manage pointers to the `iio_scan_block` C struct.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Scan.html#gad7fd2ea05bf5a8cebaff26b60edb8a13)
"""
mutable struct iio_scan_block
end

"""
    iio_scan_context

Empty struct to manage pointers to the `iio_scan_context` C struct.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/group__Scan.html#gaa333dd2e410a2769cf5685019185d99c)
"""
mutable struct iio_scan_context
end

"""
    iio_context

Empty struct to manage pointers to the `iio_context` C struct.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/structiio__context.html)
"""
mutable struct iio_context
end

"""
    iio_device

Empty struct to manage pointers to the `iio_device` C struct.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/structiio__device.html)
"""
mutable struct iio_device
end

"""
    iio_channel

Empty struct to manage pointers to the `iio_channel` C struct.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/structiio__channel.html)
"""
mutable struct iio_channel
end

"""
    iio_buffer

Empty struct to manage pointers to the `iio_buffer` C struct.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/structiio__buffer.html)
"""
mutable struct iio_buffer
end

"""
    iio_data_format

Empty struct to manage pointers to the `iio_data_format` C struct.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/structiio__data__format.html)
"""
mutable struct iio_data_format
end


# -------------- #
# --- Macros --- #
# -------------- #
"""
    @assert_null_pointer expression

    Throws an error if the expression does not return a non-null pointer.
    If the expression return a `Ptr{type}` the error message is "type* null pointer".
"""
macro assert_null_pointer(ex)
    quote
        local val = $(esc(ex));
        typeassert(val, Ptr) != Ptr{Any}(0) || NO_ASSERT || throw(AssertionError(string(typeof(val))[5:end-1] * "* null pointer"));
        val
    end
end

# !!! Replaced by the unique macro assert_null_pointer
# TODO : confirm @assert_null_pointer works properly and remove old macros
macro assert_context_info(ex)
    :($(esc(ex)) != Ptr{iio_context_info}(0) || NO_ASSERT || error("iio_context_info null pointer"));
end

macro assert_scan_block(ex)
    :($(esc(ex)) != Ptr{iio_scan_block}(0) || NO_ASSERT || error("iio_scan_block null pointer"));
end

macro assert_scan_context(ex)
    :($(esc(ex)) != Ptr{iio_scan_context}(0) || NO_ASSERT || error("iio_scan_context null pointer"));
end

macro assert_context(ex)
    :($(esc(ex)) != Ptr{iio_context}(0) || NO_ASSERT || error("iio_context null pointer"));
end

macro assert_device(ex)
    :($(esc(ex)) != Ptr{iio_device}(0) || NO_ASSERT || error("iio_device null pointer"));
end

macro assert_channel(ex)
    :($(esc(ex)) != Ptr{iio_channel}(0) || NO_ASSERT || error("iio_channel null pointer"));
end

macro assert_buffer(ex)
    :($(esc(ex)) != Ptr{iio_buffer}(0) || NO_ASSERT || error("iio_buffer null pointer"));
end

# other C values
macro assert_Cstring(ex)
    :($(esc(ex)) != C_NULL || NO_ASSERT || error("Invalid Cstring: NULL pointer"));
end


# ------------- #
# --- Enums --- #
# ------------- #

"""
    iio_modifier

Copy of the equivalent C enum.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/iio_8h.html#a944ad22f426e09cdbb493081a05472e5)
"""
@enum iio_modifier begin
    IIO_NO_MOD
	IIO_MOD_X
	IIO_MOD_Y
	IIO_MOD_Z
	IIO_MOD_X_AND_Y
	IIO_MOD_X_AND_Z
	IIO_MOD_Y_AND_Z
	IIO_MOD_X_AND_Y_AND_Z
	IIO_MOD_X_OR_Y
	IIO_MOD_X_OR_Z
	IIO_MOD_Y_OR_Z
	IIO_MOD_X_OR_Y_OR_Z
	IIO_MOD_LIGHT_BOTH
	IIO_MOD_LIGHT_IR
	IIO_MOD_ROOT_SUM_SQUARED_X_Y
	IIO_MOD_SUM_SQUARED_X_Y_Z
	IIO_MOD_LIGHT_CLEAR
	IIO_MOD_LIGHT_RED
	IIO_MOD_LIGHT_GREEN
	IIO_MOD_LIGHT_BLUE
	IIO_MOD_QUATERNION
	IIO_MOD_TEMP_AMBIENT
	IIO_MOD_TEMP_OBJECT
	IIO_MOD_NORTH_MAGN
	IIO_MOD_NORTH_TRUE
	IIO_MOD_NORTH_MAGN_TILT_COMP
	IIO_MOD_NORTH_TRUE_TILT_COMP
	IIO_MOD_RUNNING
	IIO_MOD_JOGGING
	IIO_MOD_WALKING
	IIO_MOD_STILL
	IIO_MOD_ROOT_SUM_SQUARED_X_Y_Z
	IIO_MOD_I
	IIO_MOD_Q
	IIO_MOD_CO2
	IIO_MOD_VOC
	IIO_MOD_LIGHT_UV
	IIO_MOD_LIGHT_DUV
	IIO_MOD_PM1
	IIO_MOD_PM2P5
	IIO_MOD_PM4
	IIO_MOD_PM10
	IIO_MOD_ETHANOL
	IIO_MOD_H2
end

"""
    iio_chan_type

Copy of the equivalent C enum.

[libIIO documentation](https://analogdevicesinc.github.io/libiio/master/libiio/iio_8h.html#a29714c3a5add6b599e29be0485ca548b)
"""
@enum iio_chan_type begin
    IIO_VOLTAGE
	IIO_CURRENT
	IIO_POWER
	IIO_ACCEL
	IIO_ANGL_VEL
	IIO_MAGN
	IIO_LIGHT
	IIO_INTENSITY
	IIO_PROXIMITY
	IIO_TEMP
	IIO_INCLI
	IIO_ROT
	IIO_ANGL
	IIO_TIMESTAMP
	IIO_CAPACITANCE
	IIO_ALTVOLTAGE
	IIO_CCT
	IIO_PRESSURE
	IIO_HUMIDITYRELATIVE
	IIO_ACTIVITY
	IIO_STEPS
	IIO_ENERGY
	IIO_DISTANCE
	IIO_VELOCITY
	IIO_CONCENTRATION
	IIO_RESISTANCE
	IIO_PH
	IIO_UVINDEX
	IIO_ELECTRICALCONDUCTIVITY
	IIO_COUNT
	IIO_INDEX
	IIO_GRAVITY
	IIO_POSITIONRELATIVE
	IIO_PHASE
	IIO_MASSCONCENTRATION
	IIO_CHAN_TYPE_UNKNOWN = C_INT_MAX
end
