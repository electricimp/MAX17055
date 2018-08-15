#require "MAX17055.device.lib.nut:1.0.0"

server.log("Device running....")
server.log("---------------------");

i2c <- hardware.i2cXDC;
i2c.configure(CLOCK_SPEED_400_KHZ);

fuelGaugeReady <- false;
fuelGauge <- MAX17055(i2c);

// Fuel gauge settings for a 2000mAh battery
settings <- {
    "desCap"       : 2000, // mAh
    "senseRes"     : 0.01, // ohms
    "chrgTerm"     : 20,   // mA
    "emptyVTarget" : 3.3,  // V
    "recoveryV"    : 3.88, // V
    "chrgV"        : MAX17055_V_CHRG_4_4_OR_4_35,
    "battType"     : MAX17055_BATT_TYPE.LiCoO2
}

// Alert settings
alerts <- {
    "enAlertPin"   : false,
    "enBattRemove" : true,
    "enBattInsert" : false,
    "enChargeStatePercentChange" : true
}

// Helper functions
function checkAlertStatus() {
    local status = fuelGauge.getAlertStatus();
    local alertDetected = false;
    foreach (alert, state in status) {
        if (state) {
            alertDetected = true;
            server.log("Alert detected: " + alert);
        }
    }
    if (alertDetected) {
        fuelGauge.clearStatusAlerts();
    } else {
        server.log("No alerts detected.");
    }
}

function logFuelGaugeInfo() {
    local state = fuelGauge.getStateOfCharge();
    server.log("Remaining cell capacity: " + state.capacity + "mAh");
    server.log("Percent of battery remaining: " + state.percent + "%");
    local tte = fuelGauge.getTimeTilEmpty();
    server.log("Time til empty: " + tte + "h");
    local ttf = fuelGauge.getTimeTilFull();
    server.log("Time til full: " + ttf + "h");
    local votage = fuelGauge.getVoltage();
    server.log("Voltage: " + votage + "V");
    local current = fuelGauge.getCurrent();
    server.log("Current: " + current + "mA");
    local current = fuelGauge.getAvgCurrent();
    server.log("Average current: " + current + "mA");
    local capacity = fuelGauge.getAvgCapacity();
    server.log("Cell capacity: " + capacity + "mAh");
    local temp = fuelGauge.getTemperature();
    server.log("Temp: " + temp + "°C");
    local rev = fuelGauge.getDeviceRev();
    server.log(format("Fuel gauge revision: 0x%04X", rev));
}

function loop() {
    // Log and clear all currently latched alerts
    checkAlertStatus();
    // Log current state of fuel gauge
    logFuelGaugeInfo();
    // Kick off next check
    imp.wakeup(60, loop);
}

function initHandler(err) {
    if (err != null) {
        server.log("Fuel gauge init error: " + err);
    } else {
        server.log("Fuel gauge initialized.");
        fuelGaugeReady = true;

        // Enable/Disable alerts
        fuelGauge.enableAlerts(alerts);
        // Start loop to check alerts, and log state of battery
        loop();
    }
}

// Initialize Fuel Gauge
server.log("Initializing fuel gauge...");
fuelGauge.init(settings, initHandler);
