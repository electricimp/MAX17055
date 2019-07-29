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

// Test Hardware: impC001 Breakout board with 3.7V 2000mAh LiIon battery
class ManualTests extends ImpTestCase {

    _i2c = null;
    _fg  = null;

    function setUp() {
        // impC001 breakout board rev5.0 
        _i2c = hardware.i2cKL;
        _i2c.configure(CLOCK_SPEED_400_KHZ);
        _fg = MAX17055(_i2c);
        // initialize here (async blocking)
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
                return (err) ? reject("Manual setup failed. Fuel gauge init failed with error: " + err) : resolve("Manual test setup complete.");
            }.bindenv(this))
        }.bindenv(this))
    }  
    
    function testGetVoltage() {
        local v = _fg.getVoltage();
        assertBetween(v, 3.5, 4.3, "Voltage not in range: " + v + "V");

        return "Get voltage test complete";
    }

    function testGetCurrent() {
        local curr = _fg.getCurrent();
        assertBetween(curr, -2000, 2000, "Current not in range: " + curr + "mA");

        return "Get current test complete";
    }

    function testGetTemp() {
        local temp = _fg.getTemperature();
        assertBetween(temp, 0, 40, "Temp not in range: " + temp + "°C");

        return "Get temperature test complete";
    }

    function testGetDevRev() {
        local actual = _fg.getDeviceRev();
        local expected = 0x4010;
        assertEqual(expected, actual, "Unexpected device rev: " + actual);

        return "Get device rev test complete";
    }

    function testGetSOC() {
        local soc = _fg.getStateOfCharge();

        assertTrue("percent" in soc, "State of charge missing percent key");
        assertTrue("capacity" in soc, "State of charge missing capacity key");

        // actual, from, to, msg
        assertBetween(soc.capacity, 0, 3000, "SOC capacity not in range: " + soc.capacity + "mAh");
        assertBetween(soc.percent, 0, 120, "SOC percent not in range: " + soc.percent + "%");

        return "State or charge test complete";
    }

    function tearDown() {
        return "Manual tests finished.";
    }

}