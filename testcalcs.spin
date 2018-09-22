{
    --------------------------------------------
    Filename:
    Author:
    Copyright (c) 20__
    See end of file for terms of use.
    --------------------------------------------
}

CON

  _clkmode = cfg#_clkmode
  _xinfreq = cfg#_xinfreq

OBJ

    cfg   : "core.con.client.flip"
    ser   : "com.serial.terminal"
    time  : "time"
    umath : "umath"
VAR

    long _ser_cog
    long dig_T1, dig_T2, dig_T3
    long dig_P1, dig_P2, dig_P3, dig_P4, dig_P5, dig_P6, dig_P7, dig_P8, dig_P9
    long t_fine
    long _scl

PUB Main | t1, p1

    Setup
'    ser.CharIn
    ser.Clear
    _scl := 1000
    dig_T1 := 27504 * _scl
    dig_T2 := 26435
    dig_T3 := -1000

    dig_P1 := 36477' * _scl
    dig_P2 := -10685' * _scl
    dig_P3 := 3024' * _scl
    dig_P4 := 2855' * _scl
    dig_P5 := 140' * _scl
    dig_P6 := -7' * _scl
    dig_P7 := 15500' * _scl
    dig_P8 := -14600' * _scl
    dig_P9 := 6000' * _scl

    t1 := 519888 * _scl
    p1 := 415148 * _scl
    
'    ser.Dec (cvt_t(t1))
'    ser.NewLine
'    ser.Dec (cvt_p(p1))
    cvt_t(t1)
    ser.NewLine
    ser.NewLine
    cvt_p(p1)
    repeat

PUB cvt_t(adc_T): T | var1, var2
'' TODO: Read dig_* constants from BMP280 NVM
    var1 := (adc_T/16384 - dig_T1/1024) * dig_T2
    ser.Str (string("var1= "))
    ser.Dec (var1)
    ser.NewLine
    
    var2 := ((adc_T/131072 - dig_T1/8192) * (adc_T / 131072 - dig_T1 / 8192)) * dig_T3
    var2 /= 1000
    ser.Str (string("var2= "))
    ser.Dec (var2)
    ser.NewLine
    
    t_fine := (var1 + var2)
    t_fine /= 1000
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

    var2 := var1 * var1 * dig_P6 / 32768
    ser.Str (string("var2= "))
    ser.Dec (var2)
    ser.NewLine

    var2 := var2 + var1 * dig_P5 << 1{* 2}
    ser.Str (string("var2= "))
    ser.Dec (var2)
    ser.NewLine

    var2 := (var2 >> 2{/ 4}) + (dig_P4 << 16{* 65536})
    ser.Str (string("var2= "))
    ser.Dec (var2)
    ser.NewLine

    var1 := (dig_P3 * var1 * var1 >> 19{/ 524288} + dig_P2 * var1) / 524288
    ser.Str (string("var1= "))
    ser.Dec (var1)
    ser.NewLine

    var1 := (1 + var1 / 32768) * dig_P1
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

    var1 := dig_P9 * p
    var1 := umath.multdiv (var1, p, 100000)
    var1 := umath.multdiv (var1, 100000, 2147483648)
    ser.Str (string("var1= "))
    ser.Dec (var1)
    ser.NewLine

    var2 := (p * dig_P8) / 32768
    ser.Str (string("var2= "))
    ser.Dec (var2)
    ser.NewLine

    p := p + (var1 + var2 + dig_P7) / 16
    ser.Str (string("p= "))
    ser.Dec (p)
    ser.NewLine

PUB Setup

  repeat until _ser_cog := ser.Start (115_200)
  ser.Clear
  ser.Str(string("Serial terminal started", ser#NL))


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
