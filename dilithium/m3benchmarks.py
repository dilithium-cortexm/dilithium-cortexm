#!/usr/bin/env python3

"""
m4benchmarks.py

Generate Dilithium benchmarks on Cortex M3.

Authors:
  - Denisa O. C. Greconici <D.Greconici@cs.ru.nl>
  - Matthias J. Kannwischer <matthias@kannwischer.eu>
  - Daan Sprenkels <daan@dsprenkels.com>

Usage: ./m3benchmarks.py

This script has no command line interface.  All the settings are hard-coded
in the source.  Look at the bottom of this file, where you can modify the code
to run the desired benchmarks, and the desired amount of iterations.
"""

import datetime
import os
import subprocess
import sys

import numpy as np
import serial

QUIET = True

def average(results):
    avgs = dict()
    for key in results[0].keys():
        avgs[key] = int(np.array([results[i][key] for i in range(len(results))]).mean())
    return avgs

def toMacro(name, value, k=None):
  if value > 100000:
    value = f"{round(value/1000):,}"
    unit = 'kcc'
  else:
    value = f"{value:,}"
    unit = 'cc'
  value = value.replace(",", "\\,")
  return f"\\newcommand{{\\{name}}}{{{value}}} % [{unit}]\n"


def test(scheme, mode, texName, iterations, compiler, sign_stackstrategy):
    make = "make --silent" if QUIET else "make"
    if compiler == "gcc":
        pass
    elif compiler == "clang":
        make = f"{make} USE_CLANG=1"
    else:
        raise ValueError("compiler should be 'gcc' or 'clang'")
    subprocess.check_call(f"{make} -Cm3 clean tidy", shell=True)
    binary      = f"{scheme}_benchmark"
    binary_path = f"m3/build-arduino_due_x/{binary}.bin"
    command = f"{make} -Cm3 DILITHIUM_MODE={mode} PLATFORM=3 CRYPTO_ITERATIONS={iterations} TARGET={binary} LOCAL_INO_SRCS=benchmark.ino SIGN_STACKSTRATEGY={sign_stackstrategy} EXTRA_SRCS='benchmark.c stack.c'"
    subprocess.check_call(command, shell=True)
    # flash binary to the board
    subprocess.check_call("/usr/bin/bossac -a", shell=True)
    subprocess.check_call(f"/usr/bin/bossac --erase --write --verify --boot=1 --port=/dev/ttyACM0 {binary_path}",shell=True)

    # get serial output and wait for '#'
    with serial.Serial("/dev/ttyACM0", 9600, timeout=60) as dev:
        logs = []
        iteration = 0
        log = b""
        while iteration < iterations:
            device_output = dev.read()
            if device_output == b'':
                print("timeout --> retry")
                return test(scheme, mode, texName, iterations, compiler, sign_stackstrategy)
            if not QUIET:
                sys.stdout.buffer.write(device_output)
                sys.stdout.flush()
            log += device_output
            if device_output == b'#':
                logs.append(log)
                log = b""
                iteration += 1
                print(f"{scheme} strat {sign_stackstrategy} (iteration {iteration}/{iterations})", end="\r", file=sys.stderr, flush=True)


    results = []
    # check that all went well
    for log in logs:
        log = log.decode(errors="ignore")
        assert scheme in log.lower(), f"scheme {scheme} not in {log}"
        lines = log.splitlines()

        d = {
            "ntt":  int(lines[1+lines.index("NTT measurement:")]),
            "invntt":  int(lines[1+lines.index("INVNTT measurement:")]),
            "pointwise":  int(lines[1+lines.index("pointwise measurement:")]),
            "nttleaktime":  int(lines[1+lines.index("NTT_leaktime measurement:")]),
            "invnttleaktime":  int(lines[1+lines.index("INVNTT_leaktime measurement:")]),
            "pointwiseleaktime":  int(lines[1+lines.index("pointwise_leaktime measurement:")]),
            "keygen":  int(lines[1+lines.index("KeyGen measurement:")]),
            "sign":  int(lines[1+lines.index("Sign measurement:")]),
            "open":  int(lines[1+lines.index("Open measurement:")]),
            "keygenstack":  int(lines[1+lines.index("KeyGen stack measurement:")]),
            "signstack":  int(lines[1+lines.index("Sign stack measurement:")]),
            "openstack":  int(lines[1+lines.index("Open stack measurement:")]),
        }
        results.append(d)

    avgResults = average(results)
    print(f"% M3 results for {scheme} using {compiler} ({iterations} iterations)", file=outfile)
    for key, value in avgResults.items():
        macro = toMacro(f"{texName}{key}", value)
        print(macro.strip())
        print(macro, end='', file=outfile)
    print('', file=outfile, flush=True)

with open(f"m3benchmarks.tex", "a") as outfile:
    iterations = 10000

    now = datetime.datetime.now(datetime.timezone.utc)
    print(f"% Benchmarking measurements written on {now}\n", file=outfile)

    test("dilithium2", 2, "dilithiumIIgccStrat1", iterations, 'gcc', 1)
    test("dilithium3", 3, "dilithiumIIIgccStrat1", iterations, 'gcc', 1)
    test("dilithium4", 4, "dilithiumIVgccStrat1", iterations, 'gcc', 1)

    test("dilithium2", 2, "dilithiumIIgccStrat2", iterations, 'gcc', 2)
    test("dilithium3", 3, "dilithiumIIIgccStrat2", iterations, 'gcc', 2)
    test("dilithium4", 4, "dilithiumIVgccStrat2", iterations, 'gcc', 2)

    test("dilithium2", 2, "dilithiumIIgccStrat3", iterations, 'gcc', 3)
    test("dilithium3", 3, "dilithiumIIIgccStrat3", iterations, 'gcc', 3)
    test("dilithium4", 4, "dilithiumIVgccStrat3", iterations, 'gcc', 3)

print("ALL GOOD.")