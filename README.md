# dilithium-cortexm

Authors:
  - Denisa O. C. Greconici `<D.Greconici@cs.ru.nl>`
  - [Matthias J. Kannwischer](https://kannwischer.eu/) `<matthias@kannwischer.eu>`
  - [Daan Sprenkels](https://dsprenkels.com/) `<daan@dsprenkels.com>`


This repository contains the supplementary code for our efforts to write an
optimized implementation of [Dilithium](https://pq-crystals.org/dilithium/)
for the ARM Cortex M4 and Cortex M3 architectures.
We are targeting the STM32F407 Discovery and the Arduino Due development boards,
which respectively hold an STMicroelectronics STM32F407 and Atmel SAM3X8E
microcontroller.

The corresponding paper is available at https://eprint.iacr.org/2020/1278.

## Table of contents

1. [Repository structure](#repository-structure)
2. [Getting started](#getting-started)
3. [STM32F4 Discovery setup](#stm32f4-discovery-setup)
4. [Arduino Due setup](#arduino-due-setup)
5. [Building and running `dilithium/`](#building-and-running--dilithium--)
6. [Building `kyber/` and `newhope/`](#building--kyber---and--newhope--)
7. [Troubleshooting (Cortex-M3)](#troubleshooting--cortex-m3-)
8. [Troubleshooting (Cortex-M4)](#troubleshooting--cortex-m4-)

## Repository structure

- `dilithium` holds our optimized implementation of the Dilithium signature
  scheme for the Cortex-M4 and Cortex-M3.
- `kyber` holds the optimized NTTs for Kyber.
- `newhope` holds the optimized NTTs for NewHope.
- `libopencm3` contains a version of the `libopencm3` library, which is used
  for abstracting the hardware from the STM32F407 board.
- `vendor` contains some (boilerplate) build tools, primarily the tooling
  for building binaries to the Arduino Due, without needing the Arduino IDE.

In each code directory, the `m3` will contain the code that is specific to
the Cortex-M3. If applicable, the `m4` directory contains the code specific
for the Cortex-M4.
Typically, these are the directories that contain the handwritten assembly
code. Furthermore, `common/` holds some vendored building blocks (mainly
SHAKE256).

## Getting started

We have tried to make this README file as clear as possible. However as always
the case with embedded programming, problems may arise that we have not
foreseen. Of course, it will not possible to exactly match your setup as well.

### Cloning the repository
To clone the repository you should use the `--recursive` option:
``` 
git clone --recursive https://github.com/dilithium-cortexm/dilithium-cortexm.git 
```


### Required software

First, install the following software:
  - [GCC for bare-metal ARM](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads) (`arm-none-eabi-gcc`)
  - [`pyserial`](https://github.com/pyserial/pyserial)
  - [`stlink`](https://github.com/texane/stlink) version `>=1.6.0` (we have had some issues with other versions during development, including `1.6.1`) (only for M4)
  - The [Arduino IDE](https://www.arduino.cc/en/main/software) (only for M3)
  - [`bossa`](https://www.shumatech.com/web/products/bossa) `>=1.9.0`. Some older versions, particularly those in the Ubuntu repositories do not work (only for M3)

```sh
# On Arch Linux, use:
yay -S arm-none-eabi-gcc arduino arduino-cli bossa python-pyserial stlink
```

### User-access to serial devices

Depending on your operating system, your user may or may not be able to
directly access the serial devices in `/dev`.  If you know that you are not
affected by this, you can skip this step.

#### Fix via udev

One way to fix this is to whitelist the device in udev, i.e., add a rule to
your udev configuration that allows user access to the USB device.

```sh
# Whitelist the Arduino SA device for user access in udev.
echo 'ATTRS{idVendor}=="2341", ATTRS{idProduct}=="003d", TAG+="uaccess" # Arduino Due' | sudo tee /etc/udev/rules.d/10-arduino-due.rules >/dev/null

# Reload udev rules.
sudo udevadm control --reload-rules && sudo udevadm trigger
```

You can use `lsusb` to find out what the vendor and product ID is of a USB
device. For example, `lsusb` reports, for the ST-LINK/V2 device:

```
Bus 003 Device 021: ID 0483:3748 STMicroelectronics ST-LINK/V2
```

Here, `0483` is the vendor ID, and `3748` is the product ID. Then you will
construct a udev rule like this:

```
# STM32F3DISCOVERY rev A/B - ST-LINK/V2
ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3748", TAG+="uaccess"
```

#### Fix via dialout group

There is another way to fix this, should the regular udev method does not
work for you, you can allow blanket access to the usb devices for your user.
To enable this, add your user to the `dialout` group. Logout and login again
after applying this change. Beware that on some systems, this group may exist
under a different name.

## STM32F4 Discovery setup

The STM32F407 device is connected with USB to the host computer. For serial
communication we use a separate serial device. To connect the serial,
communication device, connect its `rx` and `tx` pins to the `PA2` and `PA3`
pins of the STM32F407 discovery board. `GND` should be connected through
the USB cable, but you might also need to connect the serial-device `GND`
to the `GND` of the STM32F407 board.

To interact with the hardware, we use the `libopencm3` library, which
provides full support for the STM32F407.

### Flashing the code

STM32F407 binaries are flashed using the `st-flash` command, which is part
of the `stlink` package. To flash a binary, use:

```sh
# Flash a dilithium test binary
st-flash write m4/bin/dilithium3_test.bin 0x8000000
```

### Serial console

The PySerial package provides the `miniterm` tool, which is used to start
a serial monitor to some device.

To start up the console for the STM32F407, use:

```sh
# Start a serial console to the /dev/ttyUSB0 device with a baud rate of 115200.
miniterm /dev/ttyUSB0 115200

# Use Ctrl+] to exit the console
```

## Arduino Due setup

The Arduino Due is connected with USB to the host computer. The USB driver has
serial communication built-in, so it is not necessary to attach a separate
serial-communication device. Beware though that the Arduino has two micro-USB
sockets. For programming, use the one closest to the power jack.

For interaction with the hardware, we have tried to use the Arduino library
wherever we can. However it turns out that the Arduino library is not very
complete at all. Therefore, we sometimes fall back to using `libsam` (which
exposes some of the ATSAM3X8E's peripherals) or programming in bare-metal.

### Flashing the code

For flashing code to an Arduino Due, we use the Bossa tool.

### Serial console

The PySerial package provides the `miniterm` tool, which is used to start
a serial monitor to some device.

To start up the console for the STM32F407, use:

```sh
# Start a serial console to the /dev/ttyUSB0 device with a baud rate of 115200.
miniterm /dev/ttyUSB0 115200

# Use Ctrl+] to exit the console
```

## Building and running `dilithium/`

First, `cd` into the `dilithium/` directory. In this directory, `m3/` contains
the files specific to the Cortex-M3 and `m4/` contains the files specific to
the Cortex-M4. `dilithium/` contains the platform-independent implementation
of dilithium, and `common/` holds some vendored building blocks (mainly SHAKE256).

To build and test the software for the Cortex-M4, run:

```sh
# Build the software, this will put a binary file at `m4/bin/dilithium3_test.bin`.
make -C m4

# In a separate terminal, start up miniterm.
miniterm /dev/ttyUSB0 115200

# Flash the firmware to the device
st-flash write m4/bin/dilithium3_test.bin 0x8000000

# Trigger a reset
st-flash reset

# Now the testing will start, and the test results should be printed to the serial console.
```

To build and test the software for the Cortex-M3, run:

```sh
# Build the software, this will put a binary file at `m3/build-arduino_due_x/m3_.bin`.
make -C m3


# Flash the firmware to the Arduino
bossac -a
bossac --erase --write --verify --boot=1 --port=/dev/ttyACM0 m3/build-arduino_due_x/m3_.bin

# In a separate terminal, start up miniterm (Arduinos use a baud rate of 9600).
miniterm /dev/ttyACM0 9600

# You may need to manually reset the device to start the program.
# The test results should be printed to the serial console.
```

At this point, feel free to take a look at the `m3/Makefile` and `m4/Makefile`.
There you will find all the customizations that are available for our
implementations. For example, `DILITHIUM_MODE` describes which parameter set
of Dilithium should be used; and `SIGN_STACKSTRATEGY` specifies which of the
stack-space scenarios should be compiled.
Also there are binaries available for testing, benchmarking, profiling, and
generating testvectors.


## Building `kyber/` and `newhope/`

Building the `kyber/` and `newhope/` code for the Cortex-M3 is similar to building Dilithium
for that platform, except all the code is already in the top-level directory, i.e., you
`cd` to that directory and do `make` immediately without `-C m3`.

The other settings remain the same.
To switch to the different parameter set, change the `CRYPTO_PATH` in `kyber/Makefile` or
`newhope/Makefile`. Available parameter sets are

- `kyber/kyber512/`
- `kyber/kyber768/`
- `kyber/kyber1024/`
- `newhope/newhope1024cca/`
- `newhope/newhope1024cpa/`

## Troubleshooting (Cortex-M3)

### `No device found on /dev/ttyACM0`

This error occurs when executing `make raw_upload`.  It is caused by `bossac`
not being able to reach the Arduino Due through the `/dev/ttyACM0` serial
port.

```sh
# Check if you can access it at all.
touch /dev/ttyACM0
```

#### `touch: cannot access '/dev/ttyACM0': No such file or directory`

Check your connections, and check if the serial port is exposed on a different
device.  If the serial port is exposed on a different device, use the
`ISP_PORT` setting to override it.

#### `touch: cannot touch '/dev/ttyACM0': Permission denied`

Make sure your user has the correct permissions for writing to the serial
port.  Refer to the udev configuration listed in the intro.

#### No error (option 1)

```sh
# Check if the device is in use by some other process:
sudo lsof | grep /dev/ttyACM0
```

If another process is currently using the device, make sure to kill it.  In
particular, I have bad experiences with the `modem-manager` service on
Debian-based systems in the past.

#### No error (option 2)

The Arduino Due may be in an uninterruptable state.  Reset it using the RESET
button on the board.

### `Device unsupported`

The Arduino Due is probably in an uninterruptable state.  Reset it using the RESET
button on the board.

If this does not unstuck the device, erase the chip by holding the ERASE
button for 5 seconds and/or waiting for 5 seconds more or replug the device.

## Troubleshooting (Cortex-M4)

### `[!] send_recv send request failed: LIBUSB_ERROR_TIMEOUT`

The STM32F407 is unresponsive. This happens (for example), when a flashing
operation is interrupted. Replug the device to unstuck it.

### `miniterm` comand not found

`miniterm` may not be installed in your `$PATH`. Perhaps, on your installation
it is called `miniterm.py`. Otherwise, put this tool in your path;
or alternatively call it using `python -m serial.tools.miniterm`.
