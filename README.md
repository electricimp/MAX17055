# MAX17055 #

The [MAX17055](https://datasheets.maximintegrated.com/en/ds/MAX17055.pdf) is a low-power fuel-gauge IC that implements the [Maxim ModelGauge m5 EZ algorithm](https://www.maximintegrated.com/en/design/partners-and-technology/design-technology/modelgauge-battery-fuel-gauge-technology.html). It measures battery voltage, current and temperature to produce fuel gauge results. Its typical power consumption is 7μA.

**To add this library to your project, add** `#require "MAX17055.device.lib.nut:1.0.2"` **to the top of your device code.**

## Class Usage ##

### Constructor: MAX17055(*i2cBus[, i2cAddress]*) ###

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *i2cBus* | imp i2c bus object | Yes | The imp i2c bus that the fuel gauge is connected to. The i2c bus **must** be preconfigured; the library will not configure the bus |
| *i2cAddress* | Integer | No | The i2c address of the fuel gauge. Default: `0x6C` |

#### Return Value ####

Nothing.

#### Example ####

```squirrel
#require "MAX17055.device.lib.nut:1.0.2"

local i2c = hardware.i2cKL;
i2c.configure(CLOCK_SPEED_400_KHZ);
fuelGauge <- MAX17055(i2c);
```

## Class Methods ##

### init(*settings[, callback]*) ###

This method initializes the fuel gauge. If a power on reset alert is detected, the *settings* parameter will be used to re-configure the fuel gauge. Initialization is an asynchronous process; the optional callback function, if provided, will be triggered when initialization is complete.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *settings* | Table | Yes | A table of configuration settings *(see below)* |
| *callback* | Function | No | A function that will be triggered when initialization is complete. It has one (required) parameter of its own which will receive an error message string if an error was encountered during initialization, otherwise `null` |

#### Settings Table Options ####

| Key | Type | Required | Description |
| --- | --- | --- | --- |
| *desCap* | Integer | Yes | The designed capacity of the battery in mAh |
| *senseRes* | Float | Yes | The size of the sense resistor in &Omega; |
| *chrgTerm* | Integer | Yes | The battery's termination charge in mA |
| *emptyVTarget* | Float | Yes | The empty target voltage in V. Resolution is 10mV |
| *recoveryV* | Float | Yes | A recovery voltage in V. Once the cell voltage rises above this point, empty voltage detection is re-enabled. Resolution is 40mV |
| *chrgV* | Integer | Yes | The charge voltage. Use the class constants *MAX17055_V_CHRG_4_2* (4.2V) or *MAX17055_V_CHRG_4_4_OR_4_35* (4.35V or 4.4V) |
| *battType* | Integer | Yes | Select the type of battery from the following class enum: *MAX17055_BATT_TYPE.LiCoO2* (most common), *MAX17055_BATT_TYPE.NCA_NCR* or *MAX17055_BATT_TYPE.LiFePO4* |

#### Return Value ####

Nothing.

#### Example ####

```squirrel
local settings = {
  "desCap"       : 2000, // mAh
  "senseRes"     : 0.01, // ohms
  "chrgTerm"     : 20,   // mA
  "emptyVTarget" : 3.3,  // V
  "recoveryV"    : 3.88, // V
  "chrgV"        : MAX17055_V_CHRG_4_2,
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

This method returns the gauge's reported remaining capacity in mAh and state-of-charge percentage output. The reported capacity is protected from making sudden jumps during load changes.

#### Return Value ####

Table &mdash; Contains the keys *percent* and *capacity*, each with values in mAh.

#### Example ####

```squirrel
local state = fuelGauge.getStateOfCharge();
server.log("Remaining cell capacity: " + state.capacity + "mAh");
server.log("Percent of battery remaining: " + state.percent + "%");
```

### getTimeTilEmpty() ###

This method returns the estimated time to empty (TTE) for the battery under present temperature and load conditions. The TTE value is determined by relating the average capacity to the average current. The corresponding average current filtering gives a delay in TTE, but provides more stable results.

**Note** The battery may require a few charge cycles to pass before this call returns a non-default value.

#### Return Value ####

Float &mdash; The estimated time in hours until the battery is empty.

#### Example ####

```squirrel
local tte = fuelGauge.getTimeTilEmpty();
server.log("Time til empty: " + tte + " hours");
```

### getTimeTilFull() ###

This method returns the estimated time to full (TTF) for the battery under present conditions. The TTF value is determined by determining the constant current and constant voltage portions of the charge cycle based on experience of prior charge cycles. Time to full is then estimated by comparing present charge current to the charge termination current. Operation of the TTF register assumes all charge profiles are consistent in the application.

**Note** The battery may require a few charge cycles to pass before this call returns a non-default value.

#### Return Value ####

Float &mdash; The estimated time in hours until the battery is fully charged.

#### Example ####

```squirrel
local ttf = fuelGauge.getTimeTilFull();
server.log("Time til full: " + ttf + " hours");
```

### getVoltage() ###

This method returns the voltage measured between BATT and CSP pins.

#### Return Value ####

Float &mdash; A voltage in V.

#### Example ####

```squirrel
local voltage = fuelGauge.getVoltage();
server.log("BATT-to-CASP voltage: " + voltage + "V");
```

### getCurrent() ###

This method measures the voltage between the CSP and CSN pins. Voltages outside the minimum and maximum register values are reported as the minimum or maximum value. The measured voltage value is then divided by the sense resistance and converted to mA. The value of the sense resistor determines the resolution and the full scale range of the current readings.

#### Return Value ####

Float &mdash; A current in mA.

#### Example ####

```squirrel
local current = fuelGauge.getCurrent();
server.log("Current: " + current + "mA");
```

### getAvgCurrent() ###

This method returns an average of current readings in mA.

#### Return Value ####

Float &mdash; A current in mA.

#### Example ####

```squirrel
local current = fuelGauge.getAvgCurrent();
server.log("Average current: " + current + "mA");
```

### getAvgCapacity() ###

This method returns the calculated available capacity of the battery based on all inputs from the ModelGauge m5 algorithm, including empty compensation. This provides unfiltered results. Jumps in the reported values can be caused by abrupt changes in load current or temperature.

#### Return Value ####

Float &mdash; A capacity result in mAh.

#### Example ####

```squirrel
local capacity = fuelGauge.getAvgCapacity();
server.log("Cell capacity: " + capacity + "mAh");
```

### getTemperature() ###

Returns the internal die temperature in degrees Celsius.

#### Return Value ####

Float &mdash; A temperature in &deg;C.

#### Example ####

```squirrel
local temp = fuelGauge.getTemperature();
server.log("Temp: " + temp + "°C");
```

### enableAlerts(*alerts*) ###

Use this method to enable or disable the alert pin, battery or percentage change alerts.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *alerts* | Table | Yes | A table with the alerts to be enabled/disabled *(see below)* |

#### Enable Alerts ####

| Key | Type | Required | Description |
| --- | --- | --- | --- |
| *enChargeStatePercentChange* | Boolean | No | Enable or disable an alert when the charge percentage crosses an integer percentage boundary, such as 50.0%, 51.0%, etc |
| *enAlertPin* | Boolean | No | Enable or disable the alert interrupt pin. NOTE: This pin is not connected on impC001 breakout board, but can be connected via Test Piont 4 (TP4) |

#### Return Value ####

Nothing.

#### Example ####

```squirrel
// Enable alert when battery is inserted, disable percent change alert
local enAlerts = {
  "enChargeStatePercentChange" : false,
  "enBattInsert" : true
};

fuelGauge.enableAlerts(enAlerts);
```

### getAlertStatus() ###

This method returns a table containing the current status of flags related to alerts. Alerts need to be reset by calling *clearStatusAlerts()*.

#### Return Value ####

Table &mdash; Contains the following keys:

| Key | Type | Description |
| --- | --- | --- |
| *powerOnReset* | Boolean | `true` when the system detects that a software or hardware power on reset event has occurred |
| *chargeStatePercentChange* | Boolean | When detection is enabled, this is `true` whenever the charge percentage crosses an integer percentage boundary, such as 50.0%, 51.0%, etc. This flag must be cleared to detect next event |
| *raw* | Integer | Raw status register value. For debugging purposes | 

#### Example ####

```squirrel
local status = fuelGauge.getAlertStatus();
foreach (alert, state in status) {
  if (state && alert !== "raw") server.log("Alert detected: " + alert);
}
```

### clearStatusAlerts() ###

This method clears all of the status alerts flags, so that the next event can be detected.

#### Return Value ####

Nothing.

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

This method returns the device revision information. The initial silicon revision is `0x4010`.

#### Return Value ####

Integer &mdash; A revision number.

#### Example ####

```squirrel
local rev = fuelGauge.getDeviceRev();
server.log(format("Fuel gauge revision: 0x%04X", rev));
```

## License ##

This library is licensed under the [MIT License](./LICENSE).
