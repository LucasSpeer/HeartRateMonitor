# Auth: Lucas Speer

from bluetooth.ble import BeaconService
import time

service = BeaconService()

service.start_advertising("14010000-0000-1000-8000-00805F9B34FB",
            1, 1, 1, 200)
time.sleep(15)
service.stop_advertising()

print("Done.")
