// MIT License
//
// Copyright 2019 Electric Imp
//
// SPDX-License-Identifier: MIT
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

@include __PATH__+ "/StubbedI2C.device.nut"

class StubbedHardwareTests extends ImpTestCase {

    _i2c = null;
    _fg  = null;

    function _cleari2cBuffers() {
        // Clear all buffers
        _i2c._clearWriteBuffer();
        _i2c._clearReadResp();
    }

    function setUp() {
        _i2c = StubbedI2C();
        _i2c.configure(CLOCK_SPEED_400_KHZ);
        _fg = MAX17055(_i2c);
        return "Stubbed hardware test setup complete.";
    }  

    function testConstructorDefaultParams() {
        assertEqual(MAX17055_DEFAULT_I2C_ADDR, _fg._addr, "Defult i2c address did not match expected");
        return "Constructor default params test complete.";
    }

    function testConstructorOptionalParams() {
        local customAddr = 0xBA;
        local _fg = MAX17055(_i2c, customAddr);
        assertEqual(customAddr, _fg._addr, "Non default i2c address did not match expected");
        return "Constructor optional params test complete.";
    }

    function tearDown() {
        return "Stubbed hardware tests finished.";
    }

    function testInitBadParamsAsync() {
        // Note: Limitation of stubbed class, all read values are set before method is called, if inside the 
        // method a value is updated and read again (ie set reg bit called on the same register 2X) the second
        // read will not reflect the updates made by the setter inside the function.
        _cleari2cBuffers();

        return Promise(function(resolve, reject) {
            _fg.init({}, function(err) {
                local expectedErr = "Missing a required setting. Cannot initialize MAX17055";
                assertEqual(err, expectedErr, "Bad init params async did not create expected error");

                return resolve("Init with bad params passed expected error to callback");
            }.bindenv(this))
        }.bindenv(this))
    }

    function testInitBadParamsSync() {
        // Note: Limitation of stubbed class, all read values are set before method is called, if inside the 
        // method a value is updated and read again (ie set reg bit called on the same register 2X) the second
        // read will not reflect the updates made by the setter inside the function.
        _cleari2cBuffers();

        return Promise(function(resolve, reject) {
            try {
                _fg.init({});
            } catch(e) {
                local expectedErr = "Missing a required setting. Cannot initialize MAX17055";
                assertEqual(e, expectedErr, "Bad init params sync did not create expected error");

                return resolve("Init with bad params threw expected error")
            }
        }.bindenv(this))
    }

    function testInitStatusBitI2CReadFail() {
        // Note: Limitation of stubbed class, all read values are set before method is called, if inside the 
        // method a value is updated and read again (ie set reg bit called on the same register 2X) the second
        // read will not reflect the updates made by the setter inside the function.
        _cleari2cBuffers();

        // Test that i2c error bubbles up when reading MAX17055_STATUS_REG
        // Don't set any read data for MAX17055_STATUS_REG to cause error
        return Promise(function(resolve, reject) {
            local settings = {
            "desCap"       : 2000, // mAh
            "senseRes"     : 0.01, // ohms
            "chrgTerm"     : 20,   // mA
            "emptyVTarget" : 3.3,  // V
            "recoveryV"    : 3.88, // V
            "chrgV"        : MAX17055_V_CHRG_4_2,
            "battType"     : MAX17055_BATT_TYPE.LiCoO2
            }
            _fg.init(settings, function(err) {
                local expectedErr = format("Error reading reg: 0x%02X Err: %i", MAX17055_STATUS_REG, -100);
                assertEqual(err, expectedErr, "Status bit i2c error in init did not create expected error");

                return resolve("Init with status i2c error passed expected error to callback");
            }.bindenv(this))
        }.bindenv(this))
    }

    function testInitDNRNotReady1Fail() {
        // Note: Limitation of stubbed class, all read values are set before method is called, if inside the 
        // method a value is updated and read again (ie set reg bit called on the same register 2X) the second
        // read will not reflect the updates made by the setter inside the function.
        _cleari2cBuffers();

        // Test that i2c error bubbles up when MAX17055_F_STAT_REG times out, never reaches ready state
        // Don't set any read data for MAX17055_F_STAT_REG to cause error
        
        // Set readbuffer values
        // MAX17055_V_CELL_REG to 0x0200 (lib always reads 2 bytes, and flips the bytes)
        _i2c._setReadResp(MAX17055_DEFAULT_I2C_ADDR, MAX17055_STATUS_REG.tochar(), "\x02\x00");

        return Promise(function(resolve, reject) {
            local settings = {
            "desCap"       : 2000, // mAh
            "senseRes"     : 0.01, // ohms
            "chrgTerm"     : 20,   // mA
            "emptyVTarget" : 3.3,  // V
            "recoveryV"    : 3.88, // V
            "chrgV"        : MAX17055_V_CHRG_4_2,
            "battType"     : MAX17055_BATT_TYPE.LiCoO2
            }

            _fg.init(settings, function(err) {
                local expectedErr = format("Error reading reg: 0x%02X Err: %i", MAX17055_F_STAT_REG, -100);
                assertEqual(err, expectedErr, "POR i2c error in init did not create expected error");

                return resolve("Init with POR i2c error passed expected error to callback");
            }.bindenv(this))
        }.bindenv(this))
    }

    function testInitDNRNotReady2Fail() {
        // Note: Limitation of stubbed class, all read values are set before method is called, if inside the 
        // method a value is updated and read again (ie set reg bit called on the same register 2X) the second
        // read will not reflect the updates made by the setter inside the function.
        _cleari2cBuffers();

        // Test that i2c error bubbles up when MAX17055_F_STAT_REG times out, never reaches ready state
        // Set MAX17055_F_STAT_REG to not ready state to cause error
        
        // Set readbuffer values
        // MAX17055_V_CELL_REG to 0x0200 (lib always reads 2 bytes, and flips the bytes)
        _i2c._setReadResp(MAX17055_DEFAULT_I2C_ADDR, MAX17055_STATUS_REG.tochar(), "\x02\x00");
        // MAX17055_F_STAT_REG to 0xFFFF (lib always reads 2 bytes, and flips the bytes)
        _i2c._setReadResp(MAX17055_DEFAULT_I2C_ADDR, MAX17055_F_STAT_REG.tochar(), "\xFF\xFF");

        return Promise(function(resolve, reject) {
            local settings = {
            "desCap"       : 2000, // mAh
            "senseRes"     : 0.01, // ohms
            "chrgTerm"     : 20,   // mA
            "emptyVTarget" : 3.3,  // V
            "recoveryV"    : 3.88, // V
            "chrgV"        : MAX17055_V_CHRG_4_2,
            "battType"     : MAX17055_BATT_TYPE.LiCoO2
            }

            _fg.init(settings, function(err) {
                local expectedErr = format("Error reading reg: 0x%02X Err: reg bit not ready.", MAX17055_F_STAT_REG);
                assertEqual(err, expectedErr, "DNR bit not ready error in init did not create expected error");

                return resolve("Init with DNR bit not ready passed expected error to callback");
            }.bindenv(this))
        }.bindenv(this))
    }

    function testInitConfigFail() {
        // Note: Limitation of stubbed class, all read values are set before method is called, if inside the 
        // method a value is updated and read again (ie set reg bit called on the same register 2X) the second
        // read will not reflect the updates made by the setter inside the function.
        _cleari2cBuffers();

        // Test that i2c error bubbles up when MAX17055_HIB_CFG_REG read fails
        // Don't set any read data for MAX17055_HIB_CFG_REG to cause error
        
        // Set readbuffer values
        // MAX17055_V_CELL_REG to 0x0200 (lib always reads 2 bytes, and flips the bytes)
        _i2c._setReadResp(MAX17055_DEFAULT_I2C_ADDR, MAX17055_STATUS_REG.tochar(), "\x02\x00");
        // MAX17055_F_STAT_REG to 0x0000 (lib always reads 2 bytes, and flips the bytes)
        _i2c._setReadResp(MAX17055_DEFAULT_I2C_ADDR, MAX17055_F_STAT_REG.tochar(), "\x00\x00");

        return Promise(function(resolve, reject) {
            local settings = {
            "desCap"       : 2000, // mAh
            "senseRes"     : 0.01, // ohms
            "chrgTerm"     : 20,   // mA
            "emptyVTarget" : 3.3,  // V
            "recoveryV"    : 3.88, // V
            "chrgV"        : MAX17055_V_CHRG_4_2,
            "battType"     : MAX17055_BATT_TYPE.LiCoO2
            }

            _fg.init(settings, function(err) {
                local expectedErr = format("Error reading reg: 0x%02X Err: %i", MAX17055_HIB_CFG_REG, -100);
                assertEqual(err, expectedErr, "Hibernate configuration i2c error in init did not create expected error");

                return resolve("Init hibernate configuration i2c error passed expected error to callback");
            }.bindenv(this))
        }.bindenv(this))
    }

    function testInitModelCfgNotReady1Fail() {
        // Note: Limitation of stubbed class, all read values are set before method is called, if inside the 
        // method a value is updated and read again (ie set reg bit called on the same register 2X) the second
        // read will not reflect the updates made by the setter inside the function.
        _cleari2cBuffers();

        // Test that i2c error bubbles up when MAX17055_MODEL_CFG_REG times out, never reaches ready state
        // Don't set any read data for MAX17055_MODEL_CFG_REG to cause error
        
        // Set readbuffer values
        // MAX17055_V_CELL_REG to 0x0200 (lib always reads 2 bytes, and flips the bytes)
        _i2c._setReadResp(MAX17055_DEFAULT_I2C_ADDR, MAX17055_STATUS_REG.tochar(), "\x02\x00");
        // MAX17055_F_STAT_REG to 0x0000 (lib always reads 2 bytes, and flips the bytes)
        _i2c._setReadResp(MAX17055_DEFAULT_I2C_ADDR, MAX17055_F_STAT_REG.tochar(), "\x00\x00");
        // MAX17055_HIB_CFG_REG to 0xFFFF (lib always reads 2 bytes, and flips the bytes)
        _i2c._setReadResp(MAX17055_DEFAULT_I2C_ADDR, MAX17055_HIB_CFG_REG.tochar(), "\xFF\xFF");
        
        return Promise(function(resolve, reject) {
            local settings = {
            "desCap"       : 2000, // mAh
            "senseRes"     : 0.01, // ohms
            "chrgTerm"     : 20,   // mA
            "emptyVTarget" : 3.3,  // V
            "recoveryV"    : 3.88, // V
            "chrgV"        : MAX17055_V_CHRG_4_2,
            "battType"     : MAX17055_BATT_TYPE.LiCoO2
            }

            _fg.init(settings, function(err) {
                local expectedErr = format("Error reading reg: 0x%02X Err: %i", MAX17055_MODEL_CFG_REG, -100);
                assertEqual(err, expectedErr, "POR i2c error in init did not create expected error");

                return resolve("Init with POR i2c error passed expected error to callback");
            }.bindenv(this))
        }.bindenv(this))
    }

    function testInitModelCfgNotReady2Fail() {
        // Note: Limitation of stubbed class, all read values are set before method is called, if inside the 
        // method a value is updated and read again (ie set reg bit called on the same register 2X) the second
        // read will not reflect the updates made by the setter inside the function.
        _cleari2cBuffers();

        // Test that i2c error bubbles up when MAX17055_MODEL_CFG_REG times out, never reaches ready state
        
        // Set readbuffer values
        // MAX17055_V_CELL_REG to 0x0200 (lib always reads 2 bytes, and flips the bytes)
        _i2c._setReadResp(MAX17055_DEFAULT_I2C_ADDR, MAX17055_STATUS_REG.tochar(), "\x02\x00");
        // MAX17055_F_STAT_REG to 0x0000 (lib always reads 2 bytes, and flips the bytes)
        _i2c._setReadResp(MAX17055_DEFAULT_I2C_ADDR, MAX17055_F_STAT_REG.tochar(), "\x00\x00");
        // MAX17055_HIB_CFG_REG to 0xFFFF (lib always reads 2 bytes, and flips the bytes)
        _i2c._setReadResp(MAX17055_DEFAULT_I2C_ADDR, MAX17055_HIB_CFG_REG.tochar(), "\xFF\xFF");
        // MAX17055_MODEL_CFG_REG to 0xFFFF (lib always reads 2 bytes, and flips the bytes)
        _i2c._setReadResp(MAX17055_DEFAULT_I2C_ADDR, MAX17055_MODEL_CFG_REG.tochar(), "\xFF\xFF");

        return Promise(function(resolve, reject) {
            local settings = {
            "desCap"       : 2000, // mAh
            "senseRes"     : 0.01, // ohms
            "chrgTerm"     : 20,   // mA
            "emptyVTarget" : 3.3,  // V
            "recoveryV"    : 3.88, // V
            "chrgV"        : MAX17055_V_CHRG_4_2,
            "battType"     : MAX17055_BATT_TYPE.LiCoO2
            }

            _fg.init(settings, function(err) {
                local expectedErr = format("Error reading reg: 0x%02X Err: reg bit not ready.", MAX17055_MODEL_CFG_REG);
                assertEqual(err, expectedErr, "Model config i2c error in init did not create expected error");

                return resolve("Init with Model config i2c error passed expected error to callback");
            }.bindenv(this))
        }.bindenv(this))
    }

    // Init tests

    // Failures 
        // MAX17055_HIB_CFG_REG write verify fails
            // try/catch causes error (clear value for MAX17055_STATUS_REG, so read fails here);
            // read MAX17055_STATUS_REG, mask 0xFFFD, 2x+ verify that after the write that the values match
            // TODO - look into testing _writeVerify/_verify method by it's self

    // Successes
        // status bit no need to initialize
        // successfull init if status bit triggers init seq (check write buffer at end to see if it matches expected)

    function testGetVoltage() {
        // Note: Limitation of stubbed class, all read values are set before method is called, if inside the 
        // method a value is updated and read again (ie set reg bit called on the same register 2X) the second
        // read will not reflect the updates made by the setter inside the function.
        _cleari2cBuffers();
        
        // Set readbuffer values
        // MAX17055_V_CELL_REG to 0xFFFF (lib always reads 2 bytes, and flips the bytes)
        _i2c._setReadResp(MAX17055_DEFAULT_I2C_ADDR, MAX17055_V_CELL_REG.tochar(), "\xFF\xFF");
        
        local expected = 5.11992;
        local actual   = _fg.getVoltage();
        local failMsg = format("getVoltage test failed actual %.5f did not match expected %.5f", actual, expected);
        assertEqual(format("%.5f", expected), format("%.5f", actual), failMsg);

        _cleari2cBuffers();
        return "getVoltage test passed";
    }

    function testGetCurrent() {
        // Note: Limitation of stubbed class, all read values are set before method is called, if inside the 
        // method a value is updated and read again (ie set reg bit called on the same register 2X) the second
        // read will not reflect the updates made by the setter inside the function.
        _cleari2cBuffers();
        
        // Set _currLSB value (for a 0.01 ohm sense resistor)
        _fg._currLSB = 0.15625;

        // Set readbuffer values
        // MAX17055_CURRENT_REG to 0xFFFF (lib always reads 2 bytes, and flips the bytes)
        _i2c._setReadResp(MAX17055_DEFAULT_I2C_ADDR, MAX17055_CURRENT_REG.tochar(), "\xFF\xFF");
        
        local expected = -0.15625;
        local actual   = _fg.getCurrent();
        local failMsg = format("getCurrent test failed actual %.5f did not match expected %.5f", actual, expected);
        assertEqual(format("%.5f", expected), format("%.5f", actual), failMsg);

        _cleari2cBuffers();
        return "getCurrent test passed";
    }

    function testGetTimeTilEmpty() {
        // Note: Limitation of stubbed class, all read values are set before method is called, if inside the 
        // method a value is updated and read again (ie set reg bit called on the same register 2X) the second
        // read will not reflect the updates made by the setter inside the function.
        _cleari2cBuffers();
        
        // Set readbuffer values
        // MAX17055_TTE_REG to 0xFFFF (lib always reads 2 bytes, and flips the bytes)
        _i2c._setReadResp(MAX17055_DEFAULT_I2C_ADDR, MAX17055_TTE_REG.tochar(), "\xFF\xFF");
        
        local expected = 102.3984;
        local actual   = _fg.getTimeTilEmpty();
        local failMsg = format("getTimeTilEmpty test failed actual %.4f did not match expected %.4f", actual, expected);
        assertEqual(format("%.4f", expected), format("%.4f", actual), failMsg);

        _cleari2cBuffers();
        return "getTimeTilEmpty test passed";
    }

    function testGetTimeTilFull() {
        // Note: Limitation of stubbed class, all read values are set before method is called, if inside the 
        // method a value is updated and read again (ie set reg bit called on the same register 2X) the second
        // read will not reflect the updates made by the setter inside the function.
        _cleari2cBuffers();
        
        // Set readbuffer values
        // MAX17055_TTF_REG to 0xFFFF (lib always reads 2 bytes, and flips the bytes)
        _i2c._setReadResp(MAX17055_DEFAULT_I2C_ADDR, MAX17055_TTF_REG.tochar(), "\xFF\xFF");
        
        local expected = 102.3984;
        local actual   = _fg.getTimeTilFull();
        local failMsg = format("getTimeTilFull test failed actual %.4f did not match expected %.4f", actual, expected);
        assertEqual(format("%.4f", expected), format("%.4f", actual), failMsg);

        _cleari2cBuffers();
        return "getTimeTilFull test passed";
    }

    function testGetAvgCurrent() {
        // Note: Limitation of stubbed class, all read values are set before method is called, if inside the 
        // method a value is updated and read again (ie set reg bit called on the same register 2X) the second
        // read will not reflect the updates made by the setter inside the function.
        _cleari2cBuffers();
        
        // Set _currLSB value (for a 0.01 ohm sense resistor)
        _fg._currLSB = 0.15625;

        // Set readbuffer values
        // MAX17055_AVG_CURRENT_REG to 0xFFFF (lib always reads 2 bytes, and flips the bytes)
        _i2c._setReadResp(MAX17055_DEFAULT_I2C_ADDR, MAX17055_AVG_CURRENT_REG.tochar(), "\xFF\xFF");
        
        local expected = -0.15625;
        local actual   = _fg.getAvgCurrent();
        local failMsg = format("getAvgCurrent test failed actual %.5f did not match expected %.5f", actual, expected);
        assertEqual(format("%.5f", expected), format("%.5f", actual), failMsg);

        _cleari2cBuffers();
        return "getAvgCurrent test passed";
    }

    function testGetAvgCapacity() {
        // Note: Limitation of stubbed class, all read values are set before method is called, if inside the 
        // method a value is updated and read again (ie set reg bit called on the same register 2X) the second
        // read will not reflect the updates made by the setter inside the function.
        _cleari2cBuffers();
        
        // Set _currLSB value (for a 0.01 ohm sense resistor)
        _fg._capacityLSB = 0.5;

        // Set readbuffer values
        // MAX17055_AV_CAP_REG to 0xFFFF (lib always reads 2 bytes, and flips the bytes)
        _i2c._setReadResp(MAX17055_DEFAULT_I2C_ADDR, MAX17055_AV_CAP_REG.tochar(), "\xFF\xFF");
        
        local expected = -0.5;
        local actual   = _fg.getAvgCapacity();
        local failMsg = format("getAvgCapacity test failed actual %.1f did not match expected %.1f", actual, expected);
        assertEqual(format("%.1f", expected), format("%.1f", actual), failMsg);

        _cleari2cBuffers();
        return "getAvgCapacity test passed";
    }

    function testDeviceRev() {
        // Note: Limitation of stubbed class, all read values are set before method is called, if inside the 
        // method a value is updated and read again (ie set reg bit called on the same register 2X) the second
        // read will not reflect the updates made by the setter inside the function.
        _cleari2cBuffers();
        
        // Set readbuffer values
        // MAX17055_DEV_NAME_REG to 0x1040 (lib always reads 2 bytes, and flips the bytes)
        _i2c._setReadResp(MAX17055_DEFAULT_I2C_ADDR, MAX17055_DEV_NAME_REG.tochar(), "\x10\x40");
        
        local expected = 0x4010;
        local actual   = _fg.getDeviceRev();
        local failMsg = format("getDeviceRev test failed actual %i did not match expected %i", actual, expected);
        assertEqual(format("%i", expected), format("%i", actual), failMsg);

        _cleari2cBuffers();
        return "getDeviceRev test passed";
    }

    function testGetSOC() {
        // Note: Limitation of stubbed class, all read values are set before method is called, if inside the 
        // method a value is updated and read again (ie set reg bit called on the same register 2X) the second
        // read will not reflect the updates made by the setter inside the function.
        _cleari2cBuffers();
        
        // Set _currLSB value (for a 0.01 ohm sense resistor)
        _fg._capacityLSB = 0.5;

        // Set readbuffer values
        // MAX17055_REP_SOC_REG to 0xFFFF (lib always reads 2 bytes, and flips the bytes)
        // MAX17055_REP_CAP_REG to 0xFFFF (lib always reads 2 bytes, and flips the bytes)
        _i2c._setReadResp(MAX17055_DEFAULT_I2C_ADDR, MAX17055_REP_SOC_REG.tochar(), "\xFF\xFF");
        _i2c._setReadResp(MAX17055_DEFAULT_I2C_ADDR, MAX17055_REP_CAP_REG.tochar(), "\xFF\xFF");
        
        local exSOC  = 255.9961;
        local exCap  = -0.5;
        local actual = _fg.getStateOfCharge();
        local failSOCMsg = format("getSOC test failed actual SOC %.4f did not match expected SOC %.4f", actual.percent, exSOC);
        local failCapMsg = format("getSOC test failed actual capacity %i did not match expected capacity %i", actual.capacity, exCap);
        assertEqual(format("%i", exSOC), format("%i", actual.percent), failSOCMsg);
        assertEqual(format("%i", exCap), format("%i", actual.capacity), failCapMsg);

        _cleari2cBuffers();
        return "getSOC test passed";        
    }

    function testGetTemperature() {
        // Note: Limitation of stubbed class, all read values are set before method is called, if inside the 
        // method a value is updated and read again (ie set reg bit called on the same register 2X) the second
        // read will not reflect the updates made by the setter inside the function.
        _cleari2cBuffers();
        
        // Set readbuffer values
        // MAX17055_TEMP_REG to 0xFF7F (lib always reads 2 bytes, and flips the bytes)
        _i2c._setReadResp(MAX17055_DEFAULT_I2C_ADDR, MAX17055_TEMP_REG.tochar(), "\xFF\x7F");
        
        local expected = 127.996;
        local actual   = _fg.getTemperature();
        local failMsg = format("getTemperature test failed actual %.3f did not match expected %.3f", actual, expected);
        assertEqual(format("%.3f", expected), format("%.3f", actual), failMsg);

        _cleari2cBuffers();
        return "getTemperature test passed";
    }

    function testGetAlertStatus() {
        // Note: Limitation of stubbed class, all read values are set before method is called, if inside the 
        // method a value is updated and read again (ie set reg bit called on the same register 2X) the second
        // read will not reflect the updates made by the setter inside the function.
        _cleari2cBuffers();
        
        // Set readbuffer values
        // MAX17055_STATUS_REG to 0x8A88 (lib always reads 2 bytes, and flips the bytes)
        _i2c._setReadResp(MAX17055_DEFAULT_I2C_ADDR, MAX17055_STATUS_REG.tochar(), "\x8A\x88");
        
        local status = _fg.getAlertStatus();
        local failMsg = "getAlertStatus test failed %s did not match expected";
        assertTrue(status.powerOnReset, format(failMsg, "powerOnReset"));
        assertTrue(status.battRemovalDetected, format(failMsg, "battRemovalDetected"));
        assertTrue(status.battInsertDetected, format(failMsg, "battInsertDetected"));
        assertTrue(status.battAbsent, format(failMsg, "battAbsent"));
        assertTrue(status.chargeStatePercentChange, format(failMsg, "chargeStatePercentChange"));

        _cleari2cBuffers();
        return "getAlertStatus test passed";
    }

    function testClearAlertStatus() {
        // Note: Limitation of stubbed class, all read values are set before method is called, if inside the 
        // method a value is updated and read again (ie set reg bit called on the same register 2X) the second
        // read will not reflect the updates made by the setter inside the function.
        _cleari2cBuffers();
        
        _fg.clearStatusAlerts();

        // Register (MAX17055_STATUS_REG 0x00) and data (0x0000)
        local expected = "\x00\x00\x00";
        local wb = _i2c._getWriteBuffer(MAX17055_DEFAULT_I2C_ADDR);
        assertEqual(expected, wb, "clearStatusAlerts write buffer did not match expected");

        _cleari2cBuffers();
        return "clearStatusAlerts test passed";
    }

    function testEnableAlerts() {
        // Note: Limitation of stubbed class, all read values are set before method is called, if inside the 
        // method a value is updated and read again (ie set reg bit called on the same register 2X) the second
        // read will not reflect the updates made by the setter inside the function.
        _cleari2cBuffers();
        
        // Set readbuffer values
        // MAX17055_CONFIG_REG to 0xF9FF (0,1,2) (lib always reads 2 bytes, and flips the bytes)
        // MAX17055_CONFIG_2_REG to 0x7FFF (7) (lib always reads 2 bytes, and flips the bytes)
        _i2c._setReadResp(MAX17055_DEFAULT_I2C_ADDR, MAX17055_CONFIG_REG.tochar(), "\xF9\xFF");
        _i2c._setReadResp(MAX17055_DEFAULT_I2C_ADDR, MAX17055_CONFIG_2_REG.tochar(), "\x7F\xFF");
        
        _fg.enableAlerts({
            "enBattRemove" : false,
            "enBattInsert" : true,
            "enAlertPin" : false,
            "enChargeStatePercentChange" : true
        });

        // Get Write Buffer 
        local expWB = MAX17055_CONFIG_REG.tochar() + "\xFA\xFF" + MAX17055_CONFIG_2_REG.tochar() + "\xFF\xFF";
        local wb = _i2c._getWriteBuffer(MAX17055_DEFAULT_I2C_ADDR);

        assertEqual(expWB, wb, "enableAlerts write buffer did not match expected");

        _cleari2cBuffers();
        return "enableAlerts test passed";
    }

    function testClearThresholds() {
        // Note: Limitation of stubbed class, all read values are set before method is called, if inside the 
        // method a value is updated and read again (ie set reg bit called on the same register 2X) the second
        // read will not reflect the updates made by the setter inside the function.
        _cleari2cBuffers();
        
        _fg.clearThresholds();

        local expected = MAX17055_V_ALRT_TH_REG.tochar() + "\x00\xFF" +
                         MAX17055_T_ALRT_TH_REG.tochar() + "\x80\x7F" +
                         MAX17055_S_ALRT_TH_REG.tochar() + "\x00\xFF" +
                         MAX17055_I_ALRT_TH_REG.tochar() + "\x80\x7F";

        local wb = _i2c._getWriteBuffer(MAX17055_DEFAULT_I2C_ADDR);

        assertEqual(expected, wb, "clearThresholds write buffer did not match expected");

        _cleari2cBuffers();
        return "clearThresholds test passed";
    }
}