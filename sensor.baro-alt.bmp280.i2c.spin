{
    --------------------------------------------
    Filename: sensor.baro-alt.bmp280.i2c.spin
    Description: Driver object for the BOSCH BMP280 Barometric Pressure/Temperature sensor
    Author: Jesse Burt
    Copyright (c) 2018
    Created: September 16, 2018
    Updated: September 16, 2018
    See end of file for terms of use.
    --------------------------------------------
}

CON
'' I2C Defaults
    DEF_ADDR    = bmp280#SLAVE_ADDR
    W           = 0
    R           = 1
    BMP280_W    = DEF_ADDR|W
    BMP280_R    = DEF_ADDR|R

    DEF_SCL     = 28
    DEF_SDA     = 29
    DEF_HZ      = bmp280#I2C_DEF_FREQ

    MODE_SLEEP  = bmp280#MODE_SLEEP
    MODE_FORCED1= bmp280#MODE_FORCED1
    MODE_FORCED2= bmp280#MODE_FORCED2
    MODE_NORMAL = bmp280#MODE_NORMAL

'' Offset within compensation data where Pressure compensation values start
    PRESS_OFFSET= 6
    
VAR

    byte    _comp_data[24]
    long    _last_temp, _last_press

OBJ

    bmp280  : "core.con.bmp280"
    i2c     : "jm_i2c_fast"
    time    : "time"
    types   : "system.types"

PUB null
'' This is not a top-level object

PUB Start: okay                                             'Default to "standard" Propeller I2C pins and 400kHz

  okay := Startx (DEF_SCL, DEF_SDA, DEF_HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ)

    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31)'Validate pins and
        if I2C_HZ =< bmp280#I2C_MAX_FREQ                    ' I2C bus freq
            return i2c.setupx (SCL_PIN, SDA_PIN, I2C_HZ) 'Pass cog ID returned from I2C object
        else
          return FALSE
    else
        return FALSE

PUB ID
'' Queries ID register
''  Should always return $58
    return readReg8 (bmp280#REG_ID)

PUB MeasureMode(mode)

    case mode
        bmp280#MODE_SLEEP:
        bmp280#MODE_FORCED1, bmp280#MODE_FORCED2:
        bmp280#MODE_NORMAL:
        OTHER:
            return

    writeReg8 (bmp280#REG_CTRL_MEAS, (%001_001 << 2) | mode)

PUB Measure | alldata[2], i
'' Queries BMP280 for one "frame" of measurement
''  (burst-reads both barometric pressure and temperature)
'' Call this method, then LastTemp and LastPress to get data from the same measurement
    readReg48 (bmp280#PRESS_MSB, @alldata)
    
    repeat i from 0 to 2
        _last_temp.byte[i] := alldata.byte[5-i]
        _last_press.byte[i] := alldata.byte[2-i]
'    _last_temp &= $1F_FF_FF
'    _last_press &= $1F_FF_FF
    _last_temp >>= 4
    _last_press >>= 4

PUB Pressure
'' Takes measurement and returns pressure data
    Measure
    return _last_press

PUB Temperature
'' Takes measurement and returns temperature data
    Measure
    return _last_temp

PUB LastTemp
'' Returns Temperature data from last read using Measure
    return _last_temp

PUB LastPress
'' Returns Pressure data from last read using Measure
    return _last_press

PUB ReadTrim

    readRegX(bmp280#DIG_T1_LSB, @_comp_data, 24)

PUB dig_T(param)

    case param
        1:
            return (_comp_data.byte[1] << 8) | _comp_data.byte[0]
        2, 3:
            return types.s16 (_comp_data.byte[((param - 1) * 2) + 1{param+1}], _comp_data.byte[((param - 1) * 2){param}])
        OTHER:
            return FALSE

PUB dig_P(param)
'   param-1 * 2 + offset
'   1-1 * 2=0 + 6 = 6
'   2-1 * 2=2 + 6 = 8
'   3-1 * 2=4 + 6 = 10
'   4-1 * 2=6 + 6 = 12
'   5-1 * 2=8 + 6 = 14
'   6-1 * 2=10 +6 = 16
'   7-1 * 2=12 +6 = 18
'   8-1 * 2=14 +6 = 20
'   9-1 * 2=16 +6 = 22
    case param
        1:
            return (_comp_data.byte[PRESS_OFFSET + 1] << 8) | _comp_data.byte[PRESS_OFFSET + 0]
        2..9:
            return types.s16 (_comp_data.byte[((param - 1) * 2) + PRESS_OFFSET+1{param+1}], _comp_data.byte[((param - 1) * 2) + PRESS_OFFSET{param}])
        OTHER:
            return FALSE

PUB TrimAddr

    return @_comp_data

PUB SoftReset
'' Sends soft-reset command to BMP280
    writeReg8 (bmp280#REG_RESET, bmp280#DO_RESET)

PUB Status
'' Queries status register
    return readReg8 (bmp280#REG_STATUS)

PRI readReg8(reg)

    writeOne (reg)
    return read8

PRI readReg24(reg_base)
'' Intended for reading one of Temperature or Pressure
    writeOne (reg_base)
    readX (@result, 3)

PRI readReg48(reg_base, ptr_data)
'' Intended for reading both Temperature and Pressure
    writeOne (reg_base)
    readX (ptr_data, 6)

PRI readRegX(reg_base, ptr_data, count)
'' Read up to 'count' registers in one transaction
    writeOne (reg_base)
    readX (ptr_data, count)

PRI read8

    i2c.start
    i2c.write (BMP280_R)
    return i2c.read (i2c#NAK)
    i2c.stop

PRI readX(ptr_buff, num_bytes)

    i2c.start
    i2c.write (BMP280_R)
    i2c.pread (ptr_buff, num_bytes, i2c#NAK)
    i2c.stop
    
PRI writeReg8(reg, data) | cmd_packet

    cmd_packet.byte[0] := BMP280_W
    cmd_packet.byte[1] := reg
    cmd_packet.byte[2] := data
    
    i2c.start
    i2c.pwrite (@cmd_packet, 3)
    i2c.stop

PRI writeOne(data) | cmd_packet

    cmd_packet.byte[0] := BMP280_W
    cmd_packet.byte[1] := data

    i2c.start
    i2c.pwrite (@cmd_packet, 2)
    i2c.stop

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
