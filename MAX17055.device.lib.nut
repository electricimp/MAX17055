// MIT License
//
// Copyright 2018 Electric Imp
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
// THE SOFTWARE IS PROVIDED &quot;AS IS&quot;, WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

// Register Addresses
const MAX17055_STATUS_REG             = 0x00;
const MAX17055_V_ALRT_TH_REG          = 0x01;
const MAX17055_T_ALRT_TH_REG          = 0x02;
const MAX17055_S_ALRT_TH_REG          = 0x03;
const MAX17055_REP_CAP_REG            = 0x05;
const MAX17055_REP_SOC_REG            = 0x06;
const MAX17055_TEMP_REG               = 0x08;
const MAX17055_V_CELL_REG             = 0x09;
const MAX17055_CURRENT_REG            = 0x0A;
const MAX17055_AVG_CURRENT_REG        = 0x0B;
const MAX17055_TTE_REG                = 0x11;
const MAX17055_DESIGN_CAP_REG         = 0x18;
const MAX17055_CONFIG_REG             = 0x1D;
const MAX17055_I_CHR_TERM_REG         = 0x1E;
const MAX17055_AV_CAP_REG             = 0x1F;
const MAX17055_TTF_REG                = 0x20;
const MAX17055_DEV_NAME_REG           = 0x21;
const MAX17055_V_EMPTY_REG            = 0x3A;
const MAX17055_F_STAT_REG             = 0x3D;
const MAX17055_DQ_ACC_REG             = 0x45;
const MAX17055_DP_ACC_REG             = 0x46;
const MAX17055_SOFT_WAKE_CMD_REG      = 0x60;
const MAX17055_I_ALRT_TH_REG          = 0xB4;
const MAX17055_HIB_CFG_REG            = 0xBA;
const MAX17055_CONFIG_2_REG           = 0xBB;
const MAX17055_MODEL_CFG_REG          = 0xDB;

const MAX17055_DEFAULT_I2C_ADDR       = 0x6C;

const MAX17055_SOFT_WAKE_CMD_CLEAR    = 0x0000;
const MAX17055_SOFT_WAKE_CMD_WAKE     = 0x0090;
const MAX17055_HIBERNATE_CMD_CLEAR    = 0x0000;

const MAX17055_REG_CHECK_TIMEOUT_SEC  = 0.1;
const MAX17055_REG_CHECK_NUM_RETRYS   = 20;
const MAX17055_REG_VERIFY_TIMEOUT_SEC = 0.001;
const MAX17055_REG_VERIFY_NUM_RETRYS  = 3;

const MAX17055_CHRG_VOLT_DEFAULT_THRESH = 0xFF00;
const MAX17055_TEMP_CURR_DEFAULT_THRESH = 0x7F80;

const MAX17055_V_CHRG_4_2             = 0x00;
const MAX17055_V_CHRG_4_4_OR_4_35     = 0x01;

enum MAX17055_BATT_TYPE {
    LiCoO2  = 0,
    NCA_NCR = 2,
    LiFePO4 = 6
}

class MAX17055 {

    static VERSION = "1.0.2";

    _i2c  = null;
    _addr = null;

    _capacityLSB        = null;
    _currLSB            = null;
    _regReadyCounter    = null;
    _writeVerifyCounter = null;

    constructor(i2c, addr = null) {
        _i2c = i2c;
        _addr = (addr == null) ? MAX17055_DEFAULT_I2C_ADDR : addr;
        
        _regReadyCounter    = 0;
        _writeVerifyCounter = 0;
    }

    // Currently only supports (EZ config not INI file, all calculations taken from software implementaion guide)
    // Params:
        // settings - table with required keys: desCap, senseRes, chrgTerm,
            // emptyVTarget, recoveryV, chrgV, battType
        // cb - callback function called when initialization finished
    function init(settings, cb = null) {
        // Make sure we have all required settings
        if (settings.len() < 7 || !("desCap" in settings) || !("senseRes" in settings) ||
            !("chrgTerm" in settings) || !("emptyVTarget" in settings) || !("recoveryV" in settings) ||
            !("chrgV" in settings) || !("battType" in settings)) {
            _handleErr("Missing a required setting. Cannot initialize MAX17055", cb);
            return;
        }

        // Set Register Standard Resolution vars (these are based on resistor value)
        _setLSBScalr(settings.senseRes);

        // Get POR bit in status register (bit 1)
        local status = _readReg(MAX17055_STATUS_REG, false);
        if (status == null) {
            return _handleErr(format("Error reading reg: 0x%02X Err: %i", MAX17055_STATUS_REG, _i2c.readerror()), cb);
        } else if (status & 0x0002) {
            // Get DNR (data not ready) bit in status register (bit 0) - may take (710ms from powerup)
            _regReady(MAX17055_F_STAT_REG, 0x0001, 0, function(error) {
                // Pass error to callback if we don't get expected value after multiple re-checks
                if (error) return _handleErr(error, cb);

                local hibCfg = null;

                // Catch any i2c read/write errors
                try {
                    // Store Hibernate Configuration
                    hibCfg = _readReg(MAX17055_HIB_CFG_REG);

                    // Exit Hibernate mode
                    _writeReg(MAX17055_SOFT_WAKE_CMD_REG, MAX17055_SOFT_WAKE_CMD_WAKE);
                    _writeReg(MAX17055_HIB_CFG_REG, MAX17055_HIBERNATE_CMD_CLEAR);
                    _writeReg(MAX17055_SOFT_WAKE_CMD_REG, MAX17055_SOFT_WAKE_CMD_CLEAR);

                    // Set Battery Config - these must be passed in
                    local desCap = (settings.desCap / _capacityLSB).tointeger();

                    _writeReg(MAX17055_DESIGN_CAP_REG, desCap);
                    _writeReg(MAX17055_DQ_ACC_REG, (desCap / 32));

                    local chrgTherm = (settings.chrgTerm / _currLSB).tointeger();
                    _writeReg(MAX17055_I_CHR_TERM_REG, _twosComp(chrgTherm));

                    // Empty Voltage Target set in 10mV increments to bits 7-15,
                    // Recovery Voltage set in 40mV increments to bits 0-6
                    // ie defaults 3.3V and 3.8V sets reg to 0xA561, ((3.3 * 1000 / 10) << 7) | (3.88 * 1000 / 40)
                    local mt = (settings.emptyVTarget * 100).tointeger();
                    local recovery = ( settings.recoveryV * 25).tointeger();
                    _writeReg(MAX17055_V_EMPTY_REG, (mt << 7) | recovery);

                    // Simplified from example code: (desCap / 32) * (dPAccCoefficient / descap) = dPAccCoefficient / 32
                    local dPAcc = (settings.chrgV) ? (51200 / 32) : (44138 / 32);
                    _writeReg(MAX17055_DP_ACC_REG, dPAcc);

                    // Refresh (bit 15), VChg (bit 10), ModelId (bits 4-7)
                    local model = (0x8000 | (settings.chrgV << 10) | (settings.battType << 4));
                    _writeReg(MAX17055_MODEL_CFG_REG, model);
                } catch(err) {
                    return _handleErr(err, cb);
                }

                // Wait for refresh bit to clear (bit 15)
                _regReady(MAX17055_MODEL_CFG_REG, 0x8000, 0, function(er) {
                    // Pass error to callback if we don't get expected value after multiple re-checks
                    if (er) return _handleErr(er, cb);
                    try {
                        // Reset original values of Hibernate Configuration
                        _writeReg(MAX17055_HIB_CFG_REG, hibCfg);
                        // Clear POR aler bit
                        _writeVerify(MAX17055_STATUS_REG, 0xFFFD, cb);
                    } catch(e) {
                        return _handleErr(e, cb);
                    }
                }.bindenv(this))
            }.bindenv(this));
        } else {
            if (cb) cb(null);
        }
    }

    function getVoltage() {
        // Register values calculated based on (datasheet table 6)
        // ModelGauge Register Standard Resolutions Table
        // Voltage 1.25mV / 16 (0.078125)
        local voltage = _readReg(MAX17055_V_CELL_REG);
        // Return value in Volts
        return (voltage * 0.078125) / 1000;
    }

    function getCurrent() {
        // Register values calculated based on (datasheet table 6)
        // ModelGauge Register Standard Resolutions Table
        // Current 1.5625μV/R_SENSE
        local curr = _readReg(MAX17055_CURRENT_REG);
        curr = _twosComp(curr);
        // Convert to mA
        return (curr * _currLSB);
    }

    // Return time til empty
    function getTimeTilEmpty() {
        // Register values calculated based on (datasheet table 6)
        // ModelGauge Register Standard Resolutions Table
        // Time 5.625s
        local tte = _readReg(MAX17055_TTE_REG);
        // Convert to hours
        return (tte * 5.625 / 3600);
    }

    // Return time til full
    function getTimeTilFull() {
        // Register values calculated based on (datasheet table 6)
        // ModelGauge Register Standard Resolutions Table
        // Time 5.625s
        local ttf = _readReg(MAX17055_TTF_REG);
        // Convert to hours
        return (ttf * 5.625 / 3600);
    }

    function getAvgCurrent() {
        // Register values calculated based on (datasheet table 6)
        // ModelGauge Register Standard Resolutions Table
        // Current 1.5625μV/R_SENSE
        local curr = _readReg(MAX17055_AVG_CURRENT_REG);
        curr = _twosComp(curr);
        // Convert to mA
        return (curr * _currLSB);
    }

    function getAvgCapacity() {
        // Register values calculated based on (datasheet table 6)
        // ModelGauge Register Standard Resolutions Table
        // Capacity 5.0μVH/ R_SENSE
        local capacity = _readReg(MAX17055_AV_CAP_REG);
        capacity = _twosComp(capacity);
        // Convert to mAh
        return (capacity * _capacityLSB);
    }

    function getDeviceRev() {
        return _readReg(MAX17055_DEV_NAME_REG);
    }

    // Return state of charge
    function getStateOfCharge() {
        // Register values calculated based on (datasheet table 6)
        // ModelGauge Register Standard Resolutions Table
        // Percent 1/256%, Capacity 5.0μVH/ R_SENSE
        local percent  = _readReg(MAX17055_REP_SOC_REG);
        percent /= 256.0;
        local capacity = _readReg(MAX17055_REP_CAP_REG);
        capacity = _twosComp(capacity);
        // Convert to mAh
        capacity *= _capacityLSB;

        return {
            "percent"  : percent,
            "capacity" : capacity
        };
    }

    function getTemperature() {
        // Register values calculated based on (datasheet table 6)
        // ModelGauge Register Standard Resolutions Table
        local temp  = _readReg(MAX17055_TEMP_REG);
        temp = _twosComp(temp);
        return (temp / 256.0);
    }

    function getAlertStatus() {
        local status = _readReg(MAX17055_STATUS_REG);
        return {
            "powerOnReset"              : (status & 0x0002),
            "battRemovalDetected"       : (status & 0x8000),
            "battInsertDetected"        : (status & 0x0800),
            "battAbsent"                : (status & 0x0008),
            "chargeStatePercentChange"  : (status & 0x0080)
        };
    }

    function clearStatusAlerts() {
        _writeReg(MAX17055_STATUS_REG, 0x0000);
    }

    function enableAlerts(alerts) {
        local config  = _readReg(MAX17055_CONFIG_REG);
        local config2 = _readReg(MAX17055_CONFIG_2_REG);
        if ("enBattRemove" in alerts) {
            // Config bit 0
            local bit = 0;
            config = (alerts.enBattRemove) ? (config | (0x01 << bit)) : (config & ~(0x01 << bit));
        }
        if ("enBattInsert" in alerts) {
            // Config bit 1
            local bit = 1;
            config = (alerts.enBattInsert) ? (config | (0x01 << bit)) : (config & ~(0x01 << bit));
        }
        if ("enAlertPin" in alerts) {
            // Config bit 2
            local bit = 2;
            config = (alerts.enAlertPin) ? (config | (0x01 << bit)) : (config & ~(0x01 << bit));
        }
        if ("enChargeStatePercentChange" in alerts) {
            // Config2 bit 7
            local bit = 7
            config2 = (alerts.enChargeStatePercentChange) ? (config2 | (0x01 << bit)) : (config2 & ~(0x01 << bit));
        }
        _writeReg(MAX17055_CONFIG_REG, config);
        _writeReg(MAX17055_CONFIG_2_REG, config2);
    }

    function clearThresholds() {
        _writeReg(MAX17055_V_ALRT_TH_REG, MAX17055_CHRG_VOLT_DEFAULT_THRESH);
        _writeReg(MAX17055_T_ALRT_TH_REG, MAX17055_TEMP_CURR_DEFAULT_THRESH);
        _writeReg(MAX17055_S_ALRT_TH_REG, MAX17055_CHRG_VOLT_DEFAULT_THRESH);
        _writeReg(MAX17055_I_ALRT_TH_REG, MAX17055_TEMP_CURR_DEFAULT_THRESH);
    }

    function _setLSBScalr(res) {
        // Register values calculated based on (datasheet table 6)
        // ModelGauge Register Standard Resolutions Table
        // Capacity 5.0μVH/ R_SENSE, Current 1.5625μV/R_SENSE

        // Convert from ohms to milli
        local res = res * 1000;
        // LSB vals in millis
        _capacityLSB = (5.0 / res);
        _currLSB = (1.5625 / res);
    }

    function _handleErr(err, cb) {
        if (cb == null) {
            throw err;
        } else {
            cb(err);
        }
    }

    function _regReady(reg, mask, expected, next) {
        local val = _readReg(reg, false);
        if (val != null && (val & mask) == expected) {
            _regReadyCounter = 0;
            next(null);
        } else {
            if (_regReadyCounter++ < MAX17055_REG_CHECK_NUM_RETRYS) {
                imp.wakeup(MAX17055_REG_CHECK_TIMEOUT_SEC, function() {
                    _regReady(reg, mask, expected, next);
                }.bindenv(this))
            } else {
                _regReadyCounter = 0;
                local err = (val == null) ? format("Err: %i", _i2c.readerror()) : "Err: reg bit not ready.";
                next(format("Error reading reg: 0x%02X %s", reg, err));
            }
        }
    }

    function _writeVerify(reg, mask, next) {
        local value = _readReg(reg);
        value = value & mask;
        _verify(reg, value, next);
    }

    function _verify(reg, value, next) {
        local actual;
        try {
            _writeReg(reg, value);
            imp.sleep(MAX17055_REG_VERIFY_TIMEOUT_SEC);
            actual = _readReg(reg);
        } catch (err) {
            return _handleErr(error, next);
        }
        if (value == actual) {
            // Reset counter
            _writeVerifyCounter = 0;
            next(null);
        } else {
            if (_writeVerifyCounter++ < MAX17055_REG_VERIFY_NUM_RETRYS) {
                imp.wakeup(MAX17055_REG_VERIFY_TIMEOUT_SEC, function() {
                    _verify(reg, value, next);
                }.bindenv(this))
            } else {
                _writeVerifyCounter = 0;
                next(format("Error write verify to reg: 0x%02X failed. Verification did not match write.", reg));
            }
        }
    }

    // Reads 2 bytes from the specified register
    // Returns null if i2c read error, otherwise an integer
    function _readReg(reg, throwErr = true) {
        local result = _i2c.read(_addr, reg.tochar(), 2);
        if (result == null) {
            if (throwErr) {
                throw format("Error reading reg: 0x%02X Err: %i", reg, _i2c.readerror());
            } else {
                return result;
            }
        }
        return (result[1] << 8 | result[0]);
    }

    // Writes 2 bytes of data to the specified register
    // Returns 0 if write was successful, otherwise and i2c error code
    function _writeReg(reg, data, throwErr = true) {
        // Write data com protocol - from user guide
        // start, slave addr, WR, ack, memory addr, ack, data0 (LSB), ack, data0 (MSB), ack, data1 (LSB) ... dataN (MSB), ack, stop
        local result = _i2c.write(_addr, format("%c%c%c", reg, (data & 0x00FF), (data >> 8)));
        if (result != 0 && throwErr) {
            throw format("Error writing to reg: 0x%02X Err: %i", reg, result);
        }
        return result;
    }

    function _twosComp(value) {
        return (value << 16) >> 16;
    }

}
