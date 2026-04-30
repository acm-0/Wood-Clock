from machine import Pin
import time


class ULN2003Stepper:
    # Half-step sequence for 28BYJ-48
    HALF_STEP_SEQ = (
        (1, 0, 0, 0),
        (1, 1, 0, 0),
        (0, 1, 0, 0),
        (0, 1, 1, 0),
        (0, 0, 1, 0),
        (0, 0, 1, 1),
        (0, 0, 0, 1),
        (1, 0, 0, 1),
    )

    STEPS_PER_REV = 4096  # half-step mode

    def __init__(self, in1, in2, in3, in4):
        self.pins = [
            Pin(in1, Pin.OUT),
            Pin(in2, Pin.OUT),
            Pin(in3, Pin.OUT),
            Pin(in4, Pin.OUT),
        ]
        self.step_index = 0
        self.release()

    def _step(self):
        pattern = self.HALF_STEP_SEQ[self.step_index]
        for pin, val in zip(self.pins, pattern):
            pin.value(val)

    def move(self, steps, delay_ms=2, direction=1):
        """
        steps: number of half-steps
        delay_ms: speed control (lower = faster)
        direction: 1 = CW, -1 = CCW
        """
        for _ in range(steps):
            self._step()
            self.step_index = (self.step_index + direction) % len(self.HALF_STEP_SEQ)
            time.sleep_ms(delay_ms)

    def rotate(self, revolutions=1, delay_ms=2, direction=1):
        steps = int(revolutions * self.STEPS_PER_REV)
        self.move(steps, delay_ms, direction)

    def rotate_degrees(self, degrees, delay_ms=2, direction=1):
        steps = int((degrees / 360) * self.STEPS_PER_REV)
        self.move(steps, delay_ms, direction)

    def release(self):
        for pin in self.pins:
            pin.value(0)
            

