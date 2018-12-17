#!/bin/env python3

import argparse
import evdev
import pygame
import select

parser = argparse.ArgumentParser(description='h4x0r sound effects')

parser.add_argument(
    'device', type=str, nargs='*',
    help="list of /dev/input/event devices to listen"
)

args = parser.parse_args()
devices = [input for input in [
    evdev.InputDevice(device) for device in (
        args.device if args.device else evdev.list_devices()
    )] if evdev.events.EV_KEY in input.capabilities()
]

if not devices:
    raise ValueError("No key event devices detected - Check device or permissions")

pygame.mixer.pre_init(44100, -16, 1, 512)
pygame.init()

confirm = pygame.mixer.Sound("confirm.wav")
escape = pygame.mixer.Sound("escape.wav")

keypress = {
    evdev.ecodes.KEY_ENTER: confirm,
    evdev.ecodes.KEY_KPENTER: confirm,
    evdev.ecodes.KEY_ESC: escape,
}

keyrelease = {}

keyonce = {
    evdev.ecodes.KEY_CAPSLOCK,
    evdev.ecodes.KEY_LEFTSHIFT,
    evdev.ecodes.KEY_LEFTCTRL,
    evdev.ecodes.KEY_LEFTALT,
    evdev.ecodes.KEY_RIGHTMETA,
    evdev.ecodes.KEY_RIGHTSHIFT,
    evdev.ecodes.KEY_RIGHTCTRL,
    evdev.ecodes.KEY_RIGHTALT,
    evdev.ecodes.KEY_BACKSPACE,
    evdev.ecodes.KEY_DELETE,
    evdev.ecodes.KEY_UP,
    evdev.ecodes.KEY_DOWN,
    evdev.ecodes.KEY_LEFT,
    evdev.ecodes.KEY_RIGHT,
    evdev.ecodes.KEY_NUMLOCK,
    evdev.ecodes.KEY_SCROLLLOCK,
    evdev.ecodes.KEY_HOME,
    evdev.ecodes.KEY_END,
    evdev.ecodes.KEY_PAGEUP,
    evdev.ecodes.KEY_PAGEDOWN,
    evdev.ecodes.KEY_VOLUMEUP,
    evdev.ecodes.KEY_VOLUMEDOWN,
} | keypress.keys() | keyrelease.keys()

typing = pygame.mixer.Sound("typing.wav")

while True:
    r, w, x = select.select(devices, [], [])
    for device in r:
        for event in device.read():
            if event.type == evdev.ecodes.EV_KEY:
                key = evdev.categorize(event)
                if key.keystate == evdev.events.KeyEvent.key_down:
                    if key.scancode in keypress:
                        keypress[key.scancode].play()
                    elif key.scancode not in keyrelease:
                        typing.play()
                elif key.keystate == evdev.events.KeyEvent.key_hold:
                    if key.scancode not in keyonce:
                        typing.play()
                elif key.keystate == evdev.events.KeyEvent.key_up:
                    if key.scancode in keyrelease:
                        keyrelease[key.scancode].play()


