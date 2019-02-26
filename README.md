# bmp280-spin
---------------

This is a P8X32A/Propeller driver object for the BOSCH BMP280 Barometric Pressure/Temperature sensor written in SPIN.

## Salient Features

* Supports I2C bus connected module up to 3.4MHz

## Requirements

* Requires 1 extra core/cog for PASM I2C driver

## Limitations

* Early development - lacking in functionality, API not stabilized
* The driver supports up to 3.4MHz, although I don't believe the I2C driver is capable of clock speeds this high

## TODO

* Update to current build standards
* Get a basic working demo put together
