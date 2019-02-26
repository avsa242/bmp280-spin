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
    SLAVE_WR        = core#SLAVE_ADDR
    SLAVE_RD        = core#SLAVE_ADDR|1

    DEF_SCL         = 28
    DEF_SDA         = 29
    DEF_HZ          = 400_000
    I2C_MAX_FREQ    = core#I2C_MAX_FREQ

    MODE_SLEEP      = core#MODE_SLEEP
    MODE_FORCED1    = core#MODE_FORCED1
    MODE_FORCED2    = core#MODE_FORCED2
    MODE_NORMAL     = core#MODE_NORMAL

'' Offset within compensation data where Pressure compensation values start
    PRESS_OFFSET    = 6
    
VAR

    byte    _comp_data[24]
    long    _last_temp, _last_press

OBJ

    core    : "core.con.bmp280"
    i2c     : "jm_i2c_fast"
    time    : "time"
    types   : "system.types"

PUB null
'' This is not a top-level object

PUB Start: okay                                             'Default to "standard" Propeller I2C pins and 400kHz

  okay := Startx (DEF_SCL, DEF_SDA, DEF_HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ)

    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31)'Validate pins and
        if I2C_HZ =< core#I2C_MAX_FREQ                    ' I2C bus freq
            return i2c.setupx (SCL_PIN, SDA_PIN, I2C_HZ) 'Pass cog ID returned from I2C object
        else
          return FALSE
    else
        return FALSE

PUB Start: okay                                                 'Default to "standard" Propeller I2C pins and 400kHz

    okay := Startx (DEF_SCL, DEF_SDA, DEF_HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ): okay

    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31)
        if I2C_HZ =< core#I2C_MAX_FREQ
            if okay := i2c.setupx (SCL_PIN, SDA_PIN, I2C_HZ)    'I2C Object Started?
                time.MSleep (1)
                if i2c.present (SLAVE_WR)                       'Response from device?
                    if ID == core#ID_EXPECTED
                        return okay
    return FALSE                                                'If we got here, something went wrong

PUB Stop

    i2c.terminate

PUB ID
' Chip identification number
'   Returns: $58 (core#ID_EXPECTED)
    readRegX (core#REG_ID, 1, @result)

PUB MeasureMode(mode)

    case mode
        core#MODE_SLEEP:
        core#MODE_FORCED1, core#MODE_FORCED2:
        core#MODE_NORMAL:
        OTHER:
            return

    writeReg8 (core#REG_CTRL_MEAS, (%001_001 << 2) | mode)

PUB Measure | alldata[2], i
'' Queries BMP280 for one "frame" of measurement
''  (burst-reads both barometric pressure and temperature)
'' Call this method, then LastTemp and LastPress to get data from the same measurement
    readReg48 (core#PRESS_MSB, @alldata)
    
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

    readRegX(core#DIG_T1_LSB, @_comp_data, 24)

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
    writeReg8 (core#REG_RESET, core#DO_RESET)

PUB Status
'' Queries status register
    return readReg8 (core#REG_STATUS)

PUB readRegX(reg, nr_bytes, addr_buff) | cmd_packet[2], ackbit
' Read nr_bytes from register 'reg' to address 'addr_buff'
    cmd_packet.byte[0] := SLAVE_WR | _addr_bit
    cmd_packet.byte[1] := reg.byte[MSB]                 'Register MSB
    cmd_packet.byte[2] := reg.byte[LSB]                 'Register LSB

    i2c.start
    ackbit := i2c.pwrite (@cmd_packet, 3)
    if ackbit == i2c#NAK
        i2c.stop
        return

' Handle quirky registers on a case-by-case basis
    case reg
        core#REG1:
        OTHER:

' No data was available, so do nothing
    if ackbit == i2c#NAK
        i2c.stop
        return -1

    i2c.pread (addr_buff, nr_bytes, TRUE)
    i2c.stop

PUB writeRegX(reg, nr_bytes, val) | cmd_packet[2]
' Write nr_bytes to register 'reg' stored in val
' If nr_bytes is
'   0, It's a command that has no arguments - write the command only
'   1, It's a command with a single byte argument - write the command, then the byte
'   2, It's a command with two arguments - write the command, then the two bytes (encoded as a word)
'   3, It's a command with two arguments and a CRC - write the command, then the two bytes (encoded as a word), lastly the CRC
    cmd_packet.byte[0] := SLAVE_WR | _addr_bit

    case nr_bytes
        0:
            cmd_packet.byte[1] := reg.byte[MSB]       'Simple command
            cmd_packet.byte[2] := reg.byte[LSB]
        1:
            cmd_packet.byte[1] := reg.byte[MSB]       'Command w/1-byte argument
            cmd_packet.byte[2] := reg.byte[LSB]
            cmd_packet.byte[3] := val
        2:
            cmd_packet.byte[1] := reg.byte[MSB]       'Command w/2-byte argument
            cmd_packet.byte[2] := reg.byte[LSB]
            cmd_packet.byte[3] := val.byte[0]
            cmd_packet.byte[4] := val.byte[1]
        3:
            cmd_packet.byte[1] := reg.byte[MSB]       'Command w/2-byte argument and CRC
            cmd_packet.byte[2] := reg.byte[LSB]
            cmd_packet.byte[3] := val.byte[0]
            cmd_packet.byte[4] := val.byte[1]
            cmd_packet.byte[5] := val.byte[2]
        OTHER:
            return

    i2c.start
    i2c.pwrite (@cmd_packet, 3 + nr_bytes)
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
