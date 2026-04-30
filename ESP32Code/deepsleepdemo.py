import time
from machine import Pin, ADC,
import machine
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

analog_pin = ADC(Pin(D0))

def batlevel():
#    avg = 0
#    for i in range(10):
#        # Read the analog value (e.g., 0 to 4095 for ESP32, 0 to 1023 for ESP8266)
#        avg += analog_pin.read()/4096*3.3
#    return(avg/5) # Divide by 10, multiply by two because of the voltage divider 
    return(analog_pin.read()*.00161) # /4096 steps *3.3V max *2 for voltage divider

if batlevel() < 3.0:
#    print("Enabling deep sleep")
    # Main logic
    motor.move(28)
    motor.release()
#    print('Going to sleep for 10 seconds')
    machine.deepsleep(20850) # Enter deep sleep
else:
    import bleclocktry1



