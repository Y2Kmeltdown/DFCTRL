#!/usr/bin/env python3
import RPi.GPIO as GPIO
BUTTON_GPIO = 16
if __name__ == '__main__':
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(BUTTON_GPIO, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
    while True:
        GPIO.wait_for_edge(BUTTON_GPIO, GPIO.RISING)
        print("Calculation Done")