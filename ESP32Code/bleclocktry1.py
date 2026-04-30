# Rui Santos & Sara Santos - Random Nerd Tutorials
# Complete project details at https://RandomNerdTutorials.com/micropython-esp32-bluetooth-low-energy-ble/

from micropython import const
import asyncio
import aioble
import bluetooth
import struct
import time
import machine
from machine import Pin, ADC
from uln2003_stepper import ULN2003Stepper

# Map Seeed ESP32 pins to Micropython expectations.  Use only Dx when assigning pins
D0 = 2
D1 = 3
D2 = 4
D3 = 5
D4 = 6
D5 = 7
D6 = 12 # Specualation, does not actually work.   Could be because D6 and D7 are 
D7 = 11 # But pin behaves strangely, suggest not to use       for UART Tx and Rx
D8 = 8
D9 = 9
D10 = 10

motor = ULN2003Stepper(
    in1=D1,
    in2=D2,
    in3=D3,
    in4=D4
)

CLOCKWISE = 1
COUNTERCLOCKWISE = -1

analog_pin = ADC(Pin(D0))

def batlevel():
#    avg = 0
#    for i in range(10):
#        # Read the analog value (e.g., 0 to 4095 for ESP32, 0 to 1023 for ESP8266)
#        avg += analog_pin.read()/4096*3.3
#    return(avg/5) # Divide by 10, multiply by two because of the voltage divider 
    return(analog_pin.read()*.00161) # /4096 steps *3.3V max *2 for voltage divider

# See the following for generating UUIDs: https://www.uuidgenerator.net/
#Service UUID
_BLE_SERVICE_UUID = bluetooth.UUID('807a35e5-60a1-4f95-8b68-9f8175d8e400')
#Charateristic UUIDs
_BLE_ADJUSTTIME_UUID = bluetooth.UUID('807a35e6-60a1-4f95-8b68-9f8175d8e400')
_BLE_ADJUSTTIMEFORWARD_UUID = bluetooth.UUID('807a35e7-60a1-4f95-8b68-9f8175d8e400')
_BLE_ADJUSTTIMEBACKWARD_UUID = bluetooth.UUID('807a35e8-60a1-4f95-8b68-9f8175d8e400')
_BLE_RESET_UUID = bluetooth.UUID('807a35e9-60a1-4f95-8b68-9f8175d8e400')
_BLE_READBATLEVEL_UUID = bluetooth.UUID('807a35ea-60a1-4f95-8b68-9f8175d8e400')

# How frequently to send advertising beacons.
_ADV_INTERVAL_MS = 250_000

# Register GATT server, the service and characteristics
# Note:  read flag means allow reads, write means allow writes,
#        notify means send updates without a requesst, capture means implement a queue to capture incoming writes
ble_service = aioble.Service(_BLE_SERVICE_UUID)

adjusttime_characteristic = aioble.Characteristic(ble_service, _BLE_ADJUSTTIME_UUID, read=False, write=True, capture=True)
adjusttimeforward_characteristic = aioble.Characteristic(ble_service, _BLE_ADJUSTTIMEFORWARD_UUID, read=False, write_no_response=True, capture=False)
adjusttimebackward_characteristic = aioble.Characteristic(ble_service, _BLE_ADJUSTTIMEBACKWARD_UUID, read=False, write_no_response=True, capture=False)
#reset_characteristic = aioble.Characteristic(ble_service, _BLE_RESET_UUID, read=False, write_no_response=True, capture=False)
reset_characteristic = aioble.Characteristic(ble_service, _BLE_RESET_UUID, read=False, write=True, capture=False)
readbatlevel_characteristic = aioble.Characteristic(ble_service, _BLE_READBATLEVEL_UUID, read=True, write=False, notify=True, capture=False)

# Register service(s)
aioble.register_services(ble_service)

# Helper to encode the data characteristic UTF-8
def _encode_data(data):
    return str(data).encode('utf-8')

# Helper to decode the LED characteristic encoding (bytes).
def _decode_data(data):
    try:
        if data is not None:
            # Decode the UTF-8 data
            number = int.from_bytes(data, 'big')
            return number
    except Exception as e:
        print("Error decoding temperature:", e)
        return None

def decode_unknown(data):
    """
    Try to decode an unknown data object into a number or text string.
    Handles bytes, bytearray, str, and numeric types.
    Returns the decoded value (int, float, or str).
    """
    # --- Handle None ---
    if data is None:
        return None

    # --- If already a number ---
    if isinstance(data, (int, float)):
        return data

    # --- If it's bytes or bytearray ---
    if isinstance(data, (bytes, bytearray)):
        # Try text decoding
        try:
            text = data.decode('utf-8')
            # Try to interpret text as a number
            try:
                if '.' in text:
                    return float(text)
                else:
                    return int(text)
            except ValueError:
                return text.strip()  # just return as text
        except UnicodeDecodeError:
            # As fallback, try hex or repr
            return data.hex()

    # --- If it's already a string ---
    if isinstance(data, str):
        # Try number first
        try:
            if '.' in data:
                return float(data)
            else:
                return int(data)
        except ValueError:
            return data.strip()

    # --- Fallback: convert to string ---
    return str(data)

# Get sensor readings
def get_random_value():
    return randint(0,100)

# Get new value and update characteristic
async def batlevel_task():
    print("Starting batlevel task")
    while True:
        value = batlevel()
        # Pack float as 4 bytes (little-endian)
        raw_bytes = struct.pack('<f', value)
        readbatlevel_characteristic.write(raw_bytes, send_update=True)
        await asyncio.sleep_ms(1000)
        
# Serially wait for connections. Don't advertise while a central is connected.
async def peripheral_task():
    print("Starting peripheral task")
    while True:
        try:
            async with await aioble.advertise(
                _ADV_INTERVAL_MS,
                name="ESP32",
                services=[_BLE_SERVICE_UUID],
                ) as connection:
                    print("Connection from", connection.device)
                    await connection.disconnected()             
        except asyncio.CancelledError:
            # Catch the CancelledError
            print("Peripheral task cancelled")
        except Exception as e:
            print("Error in peripheral_task:", e)
        finally:
            # Ensure the loop continues to the next iteration
            await asyncio.sleep_ms(100)

async def adjusttime_task():
    print("Starting adjusttime task")
    while True:
        try:
            connection, data = await adjusttime_characteristic.written()
#            print(data)
#            print(type)
            data = decode_unknown(data)
#            print('Connection: ', connection)
#            print('Data: ', data)
            if isinstance(data,int) :
                motor.move(steps=data)
                motor.release()
        except asyncio.CancelledError:
            # Catch the CancelledError
            print("Peripheral task cancelled")
        except Exception as e:
            print("Error in peripheral_task:", e)
        finally:
            # Ensure the loop continues to the next iteration
            await asyncio.sleep_ms(100)
          
            
async def adjusttimeforward_task():
    print("Starting adjusttimeforward task")
    while True:
        try:
            connection = await adjusttimeforward_characteristic.written()
            motor.move(steps=20,direction=CLOCKWISE)
            motor.release()
        except asyncio.CancelledError:
            # Catch the CancelledError
            print("Peripheral task cancelled")
        except Exception as e:
            print("Error in peripheral_task:", e)
        finally:
            # Ensure the loop continues to the next iteration
            await asyncio.sleep_ms(100)
            
async def adjusttimebackward_task():
    print("Starting adjusttimebackward task")
    while True:
        try:
            connection = await adjusttimebackward_characteristic.written()
            motor.move(steps=20,direction=COUNTERCLOCKWISE)
            motor.release()
        except asyncio.CancelledError:
            # Catch the CancelledError
            print("Peripheral task cancelled")
        except Exception as e:
            print("Error in peripheral_task:", e)
        finally:
            # Ensure the loop continues to the next iteration
            await asyncio.sleep_ms(100)
            
async def reset_task():
    print("Starting reset task")
    while True:
        try:
            connection = await reset_characteristic.written()
            motor.release()
            print("About to reset")
            time.sleep(10)
            machine.deepsleep(10000)
        except asyncio.CancelledError:
            # Catch the CancelledError
            print("Peripheral task cancelled")
        except Exception as e:
            print("Error in peripheral_task:", e)
        finally:
            # Ensure the loop continues to the next iteration
            await asyncio.sleep_ms(100)
            
# Run tasks
async def main():
    t1 = asyncio.create_task(batlevel_task())
    t2 = asyncio.create_task(peripheral_task())
    t3 = asyncio.create_task(adjusttime_task())
    t4 = asyncio.create_task(adjusttimeforward_task())
    t5 = asyncio.create_task(adjusttimebackward_task())
    t6 = asyncio.create_task(reset_task())
    
    await asyncio.gather(t2)
    
asyncio.run(main())