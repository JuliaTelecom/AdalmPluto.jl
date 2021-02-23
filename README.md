# PlutoSDR

## Documentation

The documentation is available on the [Github Pages](https://juliatelecom.github.io/AdalmPluto.jl/dev/).

## Basic usage

Using the radio through USB.

```jl
using AdalmPluto;

# Opening the radio with 100MHz carrier frequency, 3MHz sampling rate, and 64dB gain.
radio = openPluto(Int(100e6), Int(3e6), 64; bandwidth=Int(20e6));

# Receive the samples
sig = zeros(ComplexF32, 1024*1024) # 1 MiS buffer
recv!(sig, radio);

# Do some treatment
# ...
# ...

# Close the radio
close(radio);
```

## Running the examples

### FM Radio

This example records a few seconds of FM radio as WAV to `.../AdalmPluto.jl/examples/samples/fm.wav`. The duration and station selection have to be modified by editing `.../AdalmPluto.jl/examples/fm.jl`.

To launch the example (from the root folder of the project) : `julia --startup-file=no --project=./examples ./examples/fm.jl`.

### Benchmark

WIP

## Sending samples

:warning: This is not implemented yet, those are just instructions on how you would do it.

The samples sent need to follow the hardware format. There is some information
[here](https://wiki.analog.com/resources/eval/user-guides/ad-fmcomms2-ebz/software/basic_iq_datafiles#binary_format)
and an example
[here](https://analogdevicesinc.github.io/libiio/master/libiio/ad9361-iiostream_8c-example.html).

Functions that should be used :
- [`iio_channel_convert_inverse`](https://analogdevicesinc.github.io/libiio/master/libiio/group__Debug.html#gaf0a9a659af18b62ffa0520301402eabb)
to convert data to the hardware format (endianess and bit alignement).
- [`iio_channel_get_data_format`](https://analogdevicesinc.github.io/libiio/master/libiio/group__Debug.html#gadbb2dabfdd85c3f2c6b168f0512c7748)
to get the data format if you want to do the convertion manually.
- [`iio_buffer_[first|start|step|end]`](https://analogdevicesinc.github.io/libiio/master/libiio/group__Buffer.html#ga000d2f4c8b72060db1c38ec905bf4156)
to get the pointers and distance between samples.
- [`iio_buffer_push`](https://analogdevicesinc.github.io/libiio/master/libiio/group__Buffer.html#gae7033c625d128667a56cf482aa3149bd)
to send the data to the hardware.
