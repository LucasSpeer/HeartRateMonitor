This is a Flutter app that connects to a BLE heart rate monitor and has the following features:

	Real-time heart rate
	History graph
	Max heart rate with alert popup and vibration
	
It uses the standard Bluetooth Heart Rate service (0x180D)

The python is taken from https://github.com/Jumperr-labs/python-gatt-server and modified to send a ramp heart rate instead of random values. To activate the heart rate emulator run:

	sudo python ./python/hr_server_ramp.py
