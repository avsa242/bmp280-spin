{
    --------------------------------------------
    Filename: BMP280-Demo.spin
    Description: Demonstrates BMP280 Pressure/Temperature sensor (I2C)
    Author: Jesse Burt
    Copyright (c) 2018
    Created: September 16, 2018
    Updated: September 16, 2018
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode = cfg#_clkmode
    _xinfreq = cfg#_xinfreq

OBJ

    cfg : "core.con.client.flip"
    ser : "com.serial.terminal"
    time: "time"
    bmp : "sensor.baro-alt.bmp280.i2c"

VAR

    long _ser_cog
    long t_fine

PUB Main

    Setup
    ser.Clear

    ser.Str (string("ID: "))
    ser.Hex (bmp.ID, 2)
    ser.Str (string(ser#NL, "STATUS: "))
    bmp.MeasureMode (bmp#MODE_NORMAL)

    repeat
        ser.Position (8, 1)
        ser.Hex (bmp.Status, 2)

        bmp.Measure

        ser.Position (0, 2)
        ser.Str (string("TEMP: "))
        ser.Hex (bmp.LastTemp, 6)

        ser.Position (0, 3)
        ser.Str (string("PRESS: "))
        ser.Hex (bmp.LastPress, 6)

        time.MSleep (100)

PUB cvt_t: T | var1, var2, dig_T1, dig_T2, dig_T3
'' TODO: Read dig_* constants from BMP280 NVM
    var1 := ((bmp.LastTemp/16384) - (dig_T1/1024)) * dig_T2
    var2 := ((bmp.LastTemp/131072) - (dig_T1/8192)) * (bmp.LastTemp / 131072) - (dig_T1 / 8192) * dig_T3
    t_fine := var1 + var2
    T := (var1 + var2) / 5120

PUB cvt_p: P | var1, var2, dig_P6, dig_P5, dig_P4, dig_P3, dig_P2, dig_P1, dig_P9, dig_P8, dig_P7
'' TODO: Read dig_* constants from BMP280 NVM
    var1 := (t_fine / 2) - 64000
    var2 := var1 * var1 * dig_P6 / 32768
    var2 := var2 + var1 * dig_P5 * 2
    var2 := (var2 / 4) + (dig_P4 * 65536)
    var1 := (dig_P3 * var1 * var1 / 524288 + dig_P2 * var1) / 524288
    var1 := (1 + var1 / 32768) * dig_P1
    p := 1048576 - bmp.LastPress
    p := (p - (var2 / 4096)) * 6250 / var1
    var1 := dig_P9 * p * p / 2_147_483_648
    var2 := p * dig_P8 / 32768
    p := p + (var1 + var2 + dig_P7) / 16

PUB waitkey

    ser.Str (string("Press any key to continue"))
    ser.CharIn

PUB Setup

    repeat until _ser_cog := ser.Start (115_200)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#NL))

    ser.Str (string("bmp280 object "))
    if bmp.Start
        ser.Str (string("started", ser#NL))
    else
        ser.Str (string("failed to start"))
        flash(cfg#LED1)
    time.MSleep (10)
    waitkey

PRI flash(led_pin)

    dira[led_pin] := 1
    repeat
        !outa[led_pin]
        time.MSleep (100)

DAT
{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}
