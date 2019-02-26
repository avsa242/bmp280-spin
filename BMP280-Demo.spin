{
    --------------------------------------------
    Filename: BMP280-Demo.spin
    Description: Demonstrates BMP280 Pressure/Temperature sensor driver (I2C)
    Author: Jesse Burt
    Copyright (c) 2019
    Created: Sep 16, 2018
    Updated: Feb 25, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode = cfg#_clkmode
    _xinfreq = cfg#_xinfreq

OBJ

    cfg : "core.con.boardcfg.flip"
    ser : "com.serial.terminal"
    time: "time"
    bmp : "sensor.baro-alt.bmp280.i2c"
    umath : "umath"

VAR

    long _ser_cog
    long t_fine
    long ptr_comp_data
    long _scl

PUB Main | i

    Setup
    ser.Clear
    _scl := 1000

    ser.Str (string("ID: "))
    ser.Hex (bmp.ID, 2)
    ser.Str (string(ser#NL, "STATUS: "))
    bmp.MeasureMode (bmp#MODE_NORMAL)
    bmp.ReadTrim
    ptr_comp_data := bmp.TrimAddr
    ser.NewLine
{
    repeat i from 0 to 23
        ser.Position (i * 3, 3)
        ser.Hex ($88+i, 2)
        ser.Position (i * 3, 4)
        ser.Hex (byte[ptr_comp_data][i], 2)
        ser.Char (" ")
    ser.NewLine

    repeat i from 1 to 3
        ser.Str (string("dig_T("))
        ser.Dec (i)
        ser.Str (string("): "))
        ser.Hex (bmp.dig_T (i), 4)
        ser.Char ("/")
        ser.Dec (bmp.dig_T (i))
        ser.NewLine
    ser.NewLine

    repeat i from 1 to 9
        ser.Str (string("dig_P("))
        ser.Dec (i)
        ser.Str (string("): "))
        ser.Hex (bmp.dig_P (i), 4)
        ser.Char ("/")
        ser.Dec (bmp.dig_P (i))
        ser.NewLine
}
    repeat
        bmp.Measure
        ser.Position (0, 3)
        ser.Hex (bmp.LastTemp, 5)
        ser.Char ("(")
        ser.Dec (bmp.LastTemp)
        ser.Char ("/")
        ser.Dec (t_fine)
        ser.Char (")")
        ser.Char ("/")
        ser.Dec (fpcvt_t(bmp.LastTemp))

        ser.Position (0, 4)
        ser.Hex (bmp.LastPress, 5)
        ser.Char ("(")
        ser.Dec (bmp.LastPress)
        ser.Char (")")
        ser.Char ("/")
'        ser.Dec (fpcvt_p(bmp.LastPress))
        ser.Dec (cvt_p(bmp.LastPress))
        ser.Char (" ")
{        cvt_T(bmp.LastTemp)
        ser.NewLine
        ser.NewLine
        cvt_P(bmp.LastPress)
}
        time.MSleep (100)

PUB fpcvt_t(adc_T): T | var1, var2

    var1 :=  ((adc_T >> 3) - (bmp.dig_T(1) << 1)) * (bmp.dig_T(2) >> 11)
    var2 :=  ((adc_T >> 4) - bmp.dig_T(1)) * ((adc_T >> 4) - (bmp.dig_T(1)) >> 12) * bmp.dig_T(3) >> 14
    t_fine := var1 + var2
    T := (t_fine * 5 + 128) >> 8

PUB fpcvtp(adc_P) | var1, var2, p

    var1 := (t_fine >> 1) - 64000
    var2 := (((var1 >> 2) * (var1 >> 2)) >> 11 ) * bmp.dig_P(6)
    var2 := var2 + ((var1 * bmp.dig_P(5)) << 1)
    var2 := (var2 >> 2) + (bmp.dig_P(4) << 16)
    var1 := (((bmp.dig_P(3) * (((var1 >> 2) * (var1 >> 2)) >> 13 )) >> 3) + (bmp.dig_P(2) * var1)>>1) >> 18
    var1 :=((32768 + var1) * bmp.dig_P(1)) >> 15
    if var1 == 0
        return 0
    
    p := ((1048576 - adc_P) - (var2 >> 12)) * 3125
    if p < $8000_0000
        p := (p << 1) / var1
    else
        p := (p / var1) * 2
    var1 := (bmp.dig_P(9) * ( ((p >> 3) * (p >> 3)) >> 13) ) >> 12
    var2 := ((p >> 2) * bmp.dig_P(8)) >> 13
    p := p + (var1 + var2 + bmp.dig_P(7) >> 4)
    return p

'---
PUB fpcvt_p(adc_P): P | var1, var2

    var1 := (t_fine >> 1) - 64000'
    var2 := (((var1 >> 2) * (var1 >> 2)) >> 11) * bmp.dig_P(6)'
    var2 := var2 + ((var1 * bmp.dig_P(5)) << 1)'
    var2 := (var2 >> 2) + (bmp.dig_P(4) << 16)'
    var1 := (((bmp.dig_P(3) * (((var1 >> 2) * (var1 >> 2)) >> 13)) >> 3) + (bmp.dig_P(2) * var1) >> 1) >> 18'
    var1 := ((32768 + var1) * bmp.dig_P(1)) >> 15'
    if var1 == 0
        return 0
    p := ((1048576 - adc_P)-(var2 >> 12)) * 3125'
    if p < $8000_0000'
        p := (p << 1) / var1
    else
        p := (p / var1) * 2
    var1 := (bmp.dig_P(9) * (((p >> 3) * (p >> 3)) >> 13)) >> 12'
    var2 := ((p >> 2) * bmp.dig_P(8)) >> 13'
    p := (p + (var1 + var2 + bmp.dig_P(7)) >> 4)

PUB cvt_t(adc_T): T | var1, var2
'' TODO: Read dig_* constants from BMP280 NVM
    adc_T *= _scl
    var1 := (adc_T/16384 - (bmp.dig_T(1)*_scl)/1024) * bmp.dig_T(2)
    ser.Str (string("var1= "))
    ser.Dec (var1)
    ser.NewLine
    
    var2 := ((adc_T/131072 - (bmp.dig_T(1)*_scl)/8192) * (adc_T / 131072 - (bmp.dig_T(1)*_scl) / 8192)) * bmp.dig_T(3)
    var2 /= _scl
    ser.Str (string("var2= "))
    ser.Dec (var2)
    ser.NewLine
    
    t_fine := (var1 + var2)
    t_fine /= _scl
    ser.Str (string("tfine= "))
    ser.Dec (t_fine)
    ser.NewLine
    
    T := (var1 + var2) / 5120
    ser.Str (string("T= "))
    ser.Dec (T)
' 12900280
'    37210
PUB cvt_p(adc_P): P | var1, var1_h, var2
'' TODO: Read dig_* constants from BMP280 NVM
    var1 := (t_fine / 2) - 63999'64000
    ser.Str (string("var1= "))
    ser.Dec (var1)
    ser.NewLine

    var2 := var1 * var1 * bmp.dig_P(6) / 32768
    ser.Str (string("var2= "))
    ser.Dec (var2)
    ser.NewLine

    var2 := var2 + var1 * bmp.dig_P(5) << 1{* 2}
    ser.Str (string("var2= "))
    ser.Dec (var2)
    ser.NewLine

    var2 := (var2 >> 2{/ 4}) + (bmp.dig_P(4) << 16{* 65536})
    ser.Str (string("var2= "))
    ser.Dec (var2)
    ser.NewLine

    var1 := (bmp.dig_P(3) * var1 * var1 >> 19{/ 524288} + bmp.dig_P(2) * var1) / 524288
    ser.Str (string("var1= "))
    ser.Dec (var1)
    ser.NewLine

    var1 := (1 + var1 / 32768) * bmp.dig_P(1)
    ser.Str (string("var1= "))
    ser.Dec (var1)
    ser.NewLine

    p := (1048576*_scl) - adc_P
    p /= _scl
    ser.Str (string("p= "))
    ser.Dec (p)
    ser.NewLine

    p := (p - (var2 >> 12{/ 4096})) * (6250/10) / (var1/10)
    ser.Str (string("p= "))
    ser.Dec (p)
    ser.NewLine

    var1 := bmp.dig_P(9) * p
    var1 := umath.multdiv (var1, p, 100000)
    var1 := umath.multdiv (var1, 100000, 2147483648)
    ser.Str (string("var1= "))
    ser.Dec (var1)
    ser.NewLine

    var2 := (p * bmp.dig_P(8)) / 32768
    ser.Str (string("var2= "))
    ser.Dec (var2)
    ser.NewLine

    p := p + (var1 + var2 + bmp.dig_P(7)) / 16
    ser.Str (string("p= "))
    ser.Dec (p)
    ser.NewLine

'----
{PUB cvt_t(adc_T): T | var1, var2
'' TODO: Read dig_* constants from BMP280 NVM
    var1 := (adc_T/16384 - bmp.dig_T(1)/1024) * bmp.dig_T(2)
    var2 := ((adc_T/131072 - bmp.dig_T(1)/8192) * (adc_T / 131072 - bmp.dig_T(1) / 8192)) * bmp.dig_T(3)
    t_fine := var1 + var2
    T := (var1 + var2) / 5120

PUB cvt_p(adc_P): P | var1, var2
'' TODO: Read dig_* constants from BMP280 NVM
    var1 := (t_fine / 2) - 64000'
    var2 := var1 * var1 * bmp.dig_P(6) / 32768'
    var2 := var2 + var1 * bmp.dig_P(5) * 2'
    var2 := (var2 / 4) + (bmp.dig_P(4) * 65536)'
    var1 := (bmp.dig_P(3) * var1 * var1 / 524288 + bmp.dig_P(2) * var1) / 524288'
    var1 := (1 + var1 / 32768) * bmp.dig_P(1)'
    p := 1048576 - adc_P'
    p := (p - (var2 / 4096)) * 6250 / var1'
    var1 := bmp.dig_P(9) * p * p / 2_147_483_647'
    var2 := p * bmp.dig_P(8) / 32768'
    p := p + (var1 + var2 + bmp.dig_P(7)) / 16'
}
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
