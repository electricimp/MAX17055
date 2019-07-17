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

class StubbedI2C {

    _writeBuffer = null;
    _readResp    = null;
    _error       = null;
    _enabled     = null;
    _watchers    = null;

    constructor() {
        _writeBuffer = {};
        _readResp    = {};
        _watchers    = {};
        _error       = 0;
        _enabled     = false;
    }

    function configure(clockSpeed) {
        _enabled = true;
    }

    function disable() {
        _enabled = false;
    }

    function read(devAddr, regAddr, numBytes) {
        if (!_enabled) {
            _error = -13;   // NOT_ENABLED
            return null;
        }

        if (devAddr in _readResp && regAddr in _readResp[devAddr]) {
            local data = _readResp[devAddr][regAddr];
            return data;
        } else {
            // Make up an integer that means "No data at device address register in read buffer."
            _error = -100;
        }

        return null;
    }

    function readerror() {
        // Store current error
        local err = _error;
        // Reset stored error to default 0: NO_ERROR
        _error = 0;
        // Return the current error
        return err;
    }

    // Just accept write data, and return i2c error code
    function write(devAddr, regPlusData) {
        if (devAddr in _writeBuffer) {
            local data = _writeBuffer[devAddr];
            _writeBuffer[devAddr] = data + regPlusData;
        } else {
            _writeBuffer[devAddr] <- regPlusData;
        }

        if (devAddr in _watchers) {
            local regAddr = regPlusData.slice(0, _watchers[devAddr]["regLen"]);
            if (regAddr in _watchers[devAddr]) {
                local cb = _watchers[devAddr][regAddr];
                if (typeof cb == "function") imp.wakeup(0, function() {
                    cb();
                }.bindenv(this));
            }
        }

        // Return i2c error code 0: NO_ERROR, -13: NOT_ENABLED
        return (_enabled) ? 0 : -13;
    }

    // Store read response in a table
    function _setReadResp(devAddr, regAddr, data) {
        if (devAddr in _readResp) {
            _readResp[devAddr][regAddr] <- data;
        } else {
            _readResp[devAddr] <- {};
            _readResp[devAddr][regAddr] <- data;
        }
    }

    function _clearReadResp() {
        _readResp = {};
    }

    function _getWriteBuffer(devAddr) {
        return (devAddr in _writeBuffer) ? _writeBuffer[devAddr] : null;
    }

    function _clearWriteBuffer() {
        _writeBuffer = {};
    }

    function _setWriteWatcher(devAddr, regAddr, cb) {
        if (devAddr in _watchers) {
            _watchers[devAddr][regAddr] <- cb;
        } else {
            _watchers[devAddr] <- {
                "regLen" : regAddr.len()
            };
            _watchers[devAddr][regAddr] <- cb;
        }
    }

    function _clearWriteWatcher() {
        _watchers = {};
    }
}