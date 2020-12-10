## settings in gnu radio block
you need to use the debug function `iio_device_indentify_filename` to get the corresponding channel and attributes names
```
out_altvoltage0_RX_LO_frequency     = 96e6          // needs to be written
in_voltage_sampling_frequency       = 2.8e6         // needs to be written
in_voltage_rf_bandwidth             = 20e6          // needs to be written
in_voltage_quadrature_tracking_en   = true          // default value
in_voltage_rf_dc_offset_tracking_en = true          // default value
in_voltage_bb_dc_offset_tracking_en = true          // default value
in_voltage0_gain_control_mode       = manual        // needs to be written
in_voltage0_hardwaregain            = 64            // needs to be written
in_voltage0_rf_port_select          = A_BALANCED    // needs to be written
// this is the important part that was missing
if auto_filter:
    ad9361_set_bb_rate(phy, samplerate)
```
On a personal note, I don't know exactly why but the indenting is a mess when I open gr-iio files in nvim (probably because of a mix of spaces, tabs, and 2-4 spaces indenting).

## available filters
from `https://github.com/analogdevicesinc/libad9361-iio/blob/master/ad9361_baseband_auto_rate.c`
```
// available filters
static int16_t fir_128_4[] = {
	-15,-27,-23,-6,17,33,31,9,-23,-47,-45,-13,34,69,67,21,-49,-102,-99,-32,69,146,143,48,-96,-204,-200,-69,129,278,275,97,-170,
	-372,-371,-135,222,494,497,187,-288,-654,-665,-258,376,875,902,363,-500,-1201,-1265,-530,699,1748,1906,845,-1089,-2922,-3424,
	-1697,2326,7714,12821,15921,15921,12821,7714,2326,-1697,-3424,-2922,-1089,845,1906,1748,699,-530,-1265,-1201,-500,363,902,875,
	376,-258,-665,-654,-288,187,497,494,222,-135,-371,-372,-170,97,275,278,129,-69,-200,-204,-96,48,143,146,69,-32,-99,-102,-49,21,
	67,69,34,-13,-45,-47,-23,9,31,33,17,-6,-23,-27,-15};

static int16_t fir_128_2[] = {
	-0,0,1,-0,-2,0,3,-0,-5,0,8,-0,-11,0,17,-0,-24,0,33,-0,-45,0,61,-0,-80,0,104,-0,-134,0,169,-0,
	-213,0,264,-0,-327,0,401,-0,-489,0,595,-0,-724,0,880,-0,-1075,0,1323,-0,-1652,0,2114,-0,-2819,0,4056,-0,-6883,0,20837,32767,
	20837,0,-6883,-0,4056,0,-2819,-0,2114,0,-1652,-0,1323,0,-1075,-0,880,0,-724,-0,595,0,-489,-0,401,0,-327,-0,264,0,-213,-0,
	169,0,-134,-0,104,0,-80,-0,61,0,-45,-0,33,0,-24,-0,17,0,-11,-0,8,0,-5,-0,3,0,-2,-0,1,0,-0, 0 };

static int16_t fir_96_2[] = {
	-4,0,8,-0,-14,0,23,-0,-36,0,52,-0,-75,0,104,-0,-140,0,186,-0,-243,0,314,-0,-400,0,505,-0,-634,0,793,-0,
	-993,0,1247,-0,-1585,0,2056,-0,-2773,0,4022,-0,-6862,0,20830,32767,20830,0,-6862,-0,4022,0,-2773,-0,2056,0,-1585,-0,1247,0,-993,-0,
	793,0,-634,-0,505,0,-400,-0,314,0,-243,-0,186,0,-140,-0,104,0,-75,-0,52,0,-36,-0,23,0,-14,-0,8,0,-4,0};

static int16_t fir_64_2[] = {
	-58,0,83,-0,-127,0,185,-0,-262,0,361,-0,-488,0,648,-0,-853,0,1117,-0,-1466,0,1954,-0,-2689,0,3960,-0,-6825,0,20818,32767,
	20818,0,-6825,-0,3960,0,-2689,-0,1954,0,-1466,-0,1117,0,-853,-0,648,0,-488,-0,361,0,-262,-0,185,0,-127,-0,83,0,-58,0};
```

### configuration explanation
```
if (rate <= 20000000UL) {
		dec = 4;
		taps = 128;
		fir = fir_128_4;
	} else if (rate <= 40000000UL) {
		dec = 2;
		fir = fir_128_2;
		taps = 128;
	} else if (rate <= 53333333UL) {
		dec = 2;
		fir = fir_96_2;
		taps = 96;
	} else {
		dec = 2;
		fir = fir_64_2;
		taps = 64;
	}
// in our case we use fir_128_4
// channel voltage0 output of ad9361-phy
// read current rate from "sampling_frequency"
// read if trx fir enable
	int ret = iio_device_attr_read_bool(dev, "in_out_voltage_filter_fir_en", &value);

	if (ret < 0)
		ret = iio_channel_attr_read_bool(iio_device_find_channel(dev, "out", false),
						 "voltage_filter_fir_en", &value);
// if enabled and current_rate < 2.08333...M (25e6/12) -> sampling_frequency = 3e6 & disable trx fir
// convert filter array into a string
// prefix where 4 is the decimation factor of our filter
"
RX 3 GAIN -6 DEC 4\n
TX 3 GAIN 0 INT 4\n
fir[0],fir[0]\n
fir[1],fir[1]\n
...\n
\n
"
// write raw in filter_fir_config
// some shenanigans if samplerate is below the lowest hardware value available
```

### original source code
```
#define FIR_BUF_SIZE	8192

int ad9361_set_trx_fir_enable(struct iio_device *dev, int enable)
{
	int ret = iio_device_attr_write_bool(dev,
					 "in_out_voltage_filter_fir_en", !!enable);
	if (ret < 0)
		ret = iio_channel_attr_write_bool(iio_device_find_channel(dev, "out", false),
					    "voltage_filter_fir_en", !!enable);
	return ret;
}

int ad9361_get_trx_fir_enable(struct iio_device *dev, int *enable)
{
	bool value;

	int ret = iio_device_attr_read_bool(dev, "in_out_voltage_filter_fir_en", &value);

	if (ret < 0)
		ret = iio_channel_attr_read_bool(iio_device_find_channel(dev, "out", false),
						 "voltage_filter_fir_en", &value);

	if (!ret)
		*enable	= value;

	return ret;
}

int ad9361_set_bb_rate(struct iio_device *dev, unsigned long rate)
{
	struct iio_channel *chan;
	long long current_rate;
	int dec, taps, ret, i, enable, len = 0;
	int16_t *fir;
	char *buf;

	if (rate <= 20000000UL) {
		dec = 4;
		taps = 128;
		fir = fir_128_4;
	} else if (rate <= 40000000UL) {
		dec = 2;
		fir = fir_128_2;
		taps = 128;
	} else if (rate <= 53333333UL) {
		dec = 2;
		fir = fir_96_2;
		taps = 96;
	} else {
		dec = 2;
		fir = fir_64_2;
		taps = 64;
	}

	chan = iio_device_find_channel(dev, "voltage0", true);
	if (chan == NULL)
		return -ENODEV;

	ret = iio_channel_attr_read_longlong(chan, "sampling_frequency", &current_rate);
	if (ret < 0)
		return ret;

	ret = ad9361_get_trx_fir_enable(dev, &enable);
	if (ret < 0)
		return ret;

	if (enable) {
		if (current_rate <= (25000000 / 12))
			iio_channel_attr_write_longlong(chan, "sampling_frequency", 3000000);

		ret = ad9361_set_trx_fir_enable(dev, false);
		if (ret < 0)
			return ret;
	}

	buf = malloc(FIR_BUF_SIZE);
	if (!buf)
		return -ENOMEM;

	len += snprintf(buf + len, FIR_BUF_SIZE - len, "RX 3 GAIN -6 DEC %d\n", dec);
	len += snprintf(buf + len, FIR_BUF_SIZE - len, "TX 3 GAIN 0 INT %d\n", dec);

	for (i = 0; i < taps; i++)
		len += snprintf(buf + len, FIR_BUF_SIZE - len, "%d,%d\n", fir[i], fir[i]);

	len += snprintf(buf + len, FIR_BUF_SIZE - len, "\n");

	ret = iio_device_attr_write_raw(dev, "filter_fir_config", buf, len);
	free (buf);

	if (ret < 0)
		return ret;

	if (rate <= (25000000 / 12))  {
		int dacrate, txrate, max;
		char readbuf[100];

		ret = iio_device_attr_read(dev, "tx_path_rates", readbuf, sizeof(readbuf));
		if (ret < 0)
			return ret;
		ret = sscanf(readbuf, "BBPLL:%*d DAC:%d T2:%*d T1:%*d TF:%*d TXSAMP:%d", &dacrate, &txrate);
		if (ret != 2)
			return -EFAULT;

		if (txrate == 0)
			return -EINVAL;

		max = (dacrate / txrate) * 16;
		if (max < taps)
			iio_channel_attr_write_longlong(chan, "sampling_frequency", 3000000);

		ret = ad9361_set_trx_fir_enable(dev, true);
		if (ret < 0)
			return ret;
		ret = iio_channel_attr_write_longlong(chan, "sampling_frequency", rate);
		if (ret < 0)
			return ret;
	} else {
		ret = iio_channel_attr_write_longlong(chan, "sampling_frequency", rate);
		if (ret < 0)
			return ret;
		ret = ad9361_set_trx_fir_enable(dev, true);
		if (ret < 0)
			return ret;
	}

	return 0;
}
```


