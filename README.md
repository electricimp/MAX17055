# MAX170555 #

The MAX17055 is a low power 7μA operating current fuel gauge IC that implements Maxim ModelGauge m5 EZ algorithm. It measures voltage, current, and temperature to produce fuel gauge results.

**To add this library to your project, add the following to the top of your device code:**

`#require "MAX170555.lib.nut:1.0.0"`

## Class Usage ##

### Constructor: MAX17055(*i2cBus[, i2cAddress]*) ###

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *i2cBus* | i2c bus object | Yes | The imp i2c bus that the fuel gauge is wired to. The i2c bus must be preconfigured. The library will not configure the bus. |
| *i2cAddress* | integer | No | The i2c address of the fuel gauge. Default value is `0x6C` |

#### Return Value ####

None.

#### Example ####

```squirrel
local i2c = hardware.i2cKL
i2c.configure(CLOCK_SPEED_400_KHZ);
fuelGauge <- MAX17055(i2c);
```

## Class Methods ##

### init(*settings[, callback]*) ###

Initializes the fuel gauge. If a power on reset alert is detected the *settings* parameter will be used to configure the fuel gauge. Initialization is an asynchonous process, the optional callback funciton will be triggered when initialization is complete.


#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *settings* | table | Yes | A table with the configuration settings. See below. |
| *callback* | function | No | Function that is triggered when initialization is complete. The *callback* function takes one required parameter that contains an error string if an error was encountered while initializing otherwise the parameter will be `null`. |

##### Settings Table #####

| Slot Name | Type | Required | Description |
| --- | --- | --- | --- |
| *desCap* | integer | Yes | The designed capacity of the battery in mAh. |
| *senseRes* | float | Yes | The size of the sense resistor in ohms. |
| *chrgTerm* | integer | Yes | The battery's termination charge in mA. |
| *emptyVTarget* | float | Yes | The empty target voltage. Resolution is 10mV the value should be given in Volts. |
| *recoveryV* | float | Yes | Once the cell voltage rises above this point, empty voltage detection is reenabled. Resolution is 40mV the value should be given in Volts. |
| *chrgV* | integer | Yes | The charge voltage. Use class constants: *MAX17055_V_CHRG_4_2* (4.2V) or *MAX17055_V_CHRG_4_4_OR_4_35* (4.35V or 4.4V). |
| *battType* | integer | Yes | Select the type of battery from the following class enum: *MAX17055_BATT_TYPE.LiCoO2* (most common), *MAX17055_BATT_TYPE.NCA_NCR*, or *MAX17055_BATT_TYPE.LiFePO4*. |

#### Return Value ####

None.

#### Example ####

```squirrel
local settings = {
    "desCap"       : 2000, // mAh
    "senseRes"     : 0.01, // ohms
    "chrgTerm"     : 20,   // mA
    "emptyVTarget" : 3.3,  // V
    "recoveryV"    : 3.88, // V
    "chrgV"        : MAX17055_V_CHRG_4_4_OR_4_35,
    "battType"     : MAX17055_BATT_TYPE.LiCoO2
}

fuelGauge.init(settings, function(err) {
    if (err != null) {
        server.error(err);
    } else {
        server.log("Fuel gauge initialized.");
        // Start using fuel gauge.
    }
});
```

### getStateOfCharge() ###

Returns the reported remaining capacity in mAh and state-of-charge percentage output. The reported capacity is protected from making sudden jumps during load changes.

#### Parameters ####

None.

#### Return Value ####

Table — with keys "percent" and "capacity" returned in mAh.

#### Example ####

```squirrel
local state = fuelGauge.getStateOfCharge();
server.log("Remaining cell capacity: " + state.capacity + "mAh");
server.log("Percent of battery remaining: " + state.percent + "%");
```

### getTimeTilEmpty() ###

Returns the estimated time to empty (TTE) for the application under present temperature and load conditions. The TTE value is determined by relating average capacity with avgerage current. The corresponding avgerage current filtering gives a delay in TTE, but provides more stable results. **Note:** This may take a few charge cycles before it returns a non-default value.

#### Parameters ####

None.

#### Return Value ####

Float — The estimated time in hours until battery is empty.

#### Example ####

```squirrel
local tte = fuelGauge.getTimeTilEmpty();
server.log("Time til empty: " + tte + "h");
```

### getTimeTilFull() ###

Returns the estimated time to full (TTF) for the application under present conditions. The TTF value is determined by learning the constant current and constant voltage portions of the charge cycle based on experience of prior charge cycles. Time to full is then estimated by comparing present charge current to the charge termination current. Operation of the TTF register assumes all charge profiles are consistent in the application. **Note:** This may take a few charge cycles before it returns a non-default value.

#### Parameters ####

None.

#### Return Value ####

Float — The estimated time in hours until battery is fully charged.

#### Example ####

```squirrel
local ttf = fuelGauge.getTimeTilFull();
server.log("Time til full: " + ttf + "h");
```

### getVoltage() ###

Returns the voltage measured between BATT and CSP pins.

#### Parameters ####

None.

#### Return Value ####

Float — The voltage in volts.

#### Example ####

```squirrel
local votage = fuelGauge.getVoltage();
server.log("Voltage: " + votage + "V");
```

### getCurrent() ###

This method measures the voltage between the CSP and CSN pins. Voltages outside the minimum and maximum register values are reported as the minimum or maximum value. The measured voltage value is divided by the sense resistance and converted to Amperes. The value of the sense resistor determines the resolution and the fullscale range of the current readings.

#### Parameters ####

None.

#### Return Value ####

Float — The current in mA.

#### Example ####

```squirrel
local current = fuelGauge.getCurrent();
server.log("Current: " + current + "mA");
```

### getAvgCurrent() ###

Returns an average of current readings in mA.

#### Parameters ####

None.

#### Return Value ####

Float — An average of current readings in mA.

#### Example ####

```squirrel
local current = fuelGauge.getAvgCurrent();
server.log("Average current: " + current + "mA");
```

### getAvgCapacity() ###

Returns the calculated available capacity of the battery based on all inputs from the ModelGauge m5 algorithm including empty compensation. This provides unfiltered results. Jumps in the reported values can be caused by abrupt changes in load current or temperature.

#### Parameters ####

None.

#### Return Value ####

Float — Unfiltered capacity results in mAh.

#### Example ####

```squirrel
local capacity = fuelGauge.getAvgCapacity();
server.log("Cell capacity: " + capacity + "mAh");
```

### getTemperature() ###

Returns the internal die temperature in °C.

#### Parameters ####

None.

#### Return Value ####

Float — The temperature in °C.

#### Example ####

```squirrel
local temp = fuelGauge.getTemperature();
server.log("Temp: " + temp + "°C");
```

### enableAlerts(alerts) ###

Use this method to enable or disable the alert pin, battery or percent change alerts.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *alerts* | table | Yes | A table with the alerts to be enabled/disabled. See below. |

##### Enable Alerts Table #####

| Slot Name | Type | Required | Description |
| --- | --- | --- | --- |
| *enAlertPin* | boolean | No | Whether to enable or disable the alert interrupt pin. |
| *enBattRemove* | boolean | No | Whether to enable or disable an alert when battery is removed. |
| *enBattInsert* | boolean | No | Whether to enable or disable an alert when battery is inserted. |
| *enChargeStatePercentChange* | boolean | No | Whether to enable or disable an alert when state of charge percentage crosses an integer percentage boundary, such as 50.0%, 51.0%, etc. |

#### Return Value ####

None.

#### Example ####

```squirrel
local enAlerts = {
    "enChargeStatePercentChange" : false,
    "enBattInsert" : true
};
fuelGauge.enableAlerts(enAlerts);
```

### getAlertStatus() ###

Returns a table with the current status of all flags related to alerts. Alerts need to be reset by calling *clearStatusAlerts()*.

#### Parameters ####

None.

#### Return Value ####

Table — with boolean alert thresholds and battery insertion or removal flags.

##### Return Table #####

| Slot Name | Type | Description |
| --- | --- | --- |
| *powerOnReset* | boolean | True when device detects a software or hardware power on reset event has occurred. |
| *battRemovalDetected* | boolean | When enabled, true when the system detects that a battery has been removed. This flag must be cleared in order to detect the next removal event. |
| *battInsertDetected* | boolean | When enabled, true when the system detects that a battery has been inserted. This flag must be cleared in order to detect the next insertion event. |
| *battAbsent* | boolean | True when the system detects that a battery is absent, false when system detects battery is present. |
| *chargeStatePercentChange* | boolean | When enabled, true whenever the state of charge percentage crosses an integer percentage boundary, such as 50.0%, 51.0%, etc. This flag must be cleared to detect next event. |

#### Example ####

```squirrel
local status = fuelGauge.getAlertStatus();
foreach (alert, state in status) {
    if (state) server.log("Alert detected: " + alert);
}
```

### clearStatusAlerts() ###

Clears all the status alerts flags, so next event can be detected.

#### Parameters ####

None.

#### Return Value ####

None.

#### Example ####

```squirrel
local status = fuelGauge.getAlertStatus();
local alertDetected = false;
foreach (alert, state in status) {
    if (state) {
        alertDetected = true;
        server.log("Alert detected: " + alert);
    }
}
if (alertDetected) fuelGauge.clearStatusAlerts();
```

### getDeviceRev() ###

Returns revision information. The initail silicon revision is `0x4010`.

#### Parameters ####

None.

#### Return Value ####

Integer - Revision information.

#### Example ####

```squirrel
local rev = fuelGauge.getDeviceRev();
server.log(format("Fuel gauge revision: 0x%04X", rev));
```

## License ##

This library is licensed under the [MIT License](./LICENSE).