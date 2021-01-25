#!/usr/bin/env python3

"""
m4benchmarks.py

Generate Dilithium benchmarks on Cortex M4.

Authors:
  - Denisa O. C. Greconici <D.Greconici@cs.ru.nl>
  - Matthias J. Kannwischer <matthias@kannwischer.eu>
  - Daan Sprenkels <daan@dsprenkels.com>

Usage: ./m4benchmarks.py

This script has no command line interface.  All the settings are hard-coded
in the source.  Look at the bottom of this file, where you can modify the code
to run the desired benchmarks, and the desired amount of iterations.
"""

import datetime
import subprocess
import sys

import serial
import numpy as np

QUIET = False

def toMacro(name, value, k=None):
  if value > 100000:
    value = f"{round(value/1000):,}\\mathrm{{k}}"
  else:
    value = f"{value:,}"
  value = value.replace(",", "\\,")
  return f"\\newcommand{{\\{name}}}{{{value}}}\n"

def run_bench(scheme, mode, iterations, benchmark, strategy):
    make = "make --silent" if QUIET else "make"
    subprocess.check_call(f"{make} -Cm4 clean", shell=True)
    binary = f"bin/{scheme}_{benchmark}.bin"
    make = f"{make} -Cm4 TARGET_NAME={scheme} DILITHIUM_MODE={mode} SIGN_STACKSTRATEGY={strategy} CRYPTO_ITERATIONS={iterations} PLATFORM=4 {binary}"
    subprocess.check_call(make, shell=True)

    try:
        subprocess.check_call(f"st-flash write m4/{binary} 0x8000000", shell=True)
        subprocess.check_call(f"st-flash reset", shell=True)
    except:
        print("flashing failed --> retry")
        return run_bench(scheme, mode, iterations, benchmark, strategy)

    # get serial output and wait for '#'
    with serial.Serial("/dev/ttyUSB0", 115200, timeout=10) as dev:
        logs = []
        iteration = 0
        log = b""
        while iteration < iterations:
            device_output = dev.read()
            if device_output == b'':
                print("timeout --> retry")
                return run_bench(scheme, mode, iterations, benchmark, strategy)
            if not QUIET:
                sys.stdout.buffer.write(device_output)
                sys.stdout.flush()
            log += device_output
            if device_output == b'#':
                logs.append(log)
                log = b""
                iteration += 1
                print(f"{scheme} strat {strategy} (iteration {iteration}/{iterations})", end="\r", file=sys.stderr, flush=True)
    return logs


def parseLogSpeed(log):
    log = log.decode(errors="ignore")
    if "error" in log.lower():
        raise Exception("error in scheme. this is very bad.")
    lines = str(log).splitlines()

    return {
        "keygen":  int(lines[1+lines.index("keypair cycles:")]),
        "sign":  int(lines[1+lines.index("sign cycles:")]),
        "open":  int(lines[1+lines.index("verify cycles:")]),
        "ntt":  int(lines[1+lines.index("ntt cycles:")]),
        "invntt":  int(lines[1+lines.index("invntt cycles:")]),
        "pointwise":  int(lines[1+lines.index("pointwise cycles:")]),
    }

def parseLogStack(log):
    log = log.decode(errors="ignore")
    if "signature valid!" not in log.lower():
        raise Exception("error in scheme. this is very bad.")
    lines = str(log).splitlines()

    return {
        "keygenstack":  int(lines[1+lines.index("keypair stack usage:")]),
        "signstack":  int(lines[1+lines.index("sign stack usage:")]),
        "openstack":  int(lines[1+lines.index("verify stack usage:")]),
    }

def average(results):
    avgs = dict()
    for key in results[0].keys():
        avgs[key] = int(np.array([results[i][key] for i in range(len(results))]).mean())
    return avgs


def bench(scheme, mode, texName, iterations, benchmark="speed", compiler="gcc", strategy=2):
    assert compiler in ["gcc", "clang"], f"compiler should be 'gcc' or 'clang' ('{compiler}')"
    logs    = run_bench(scheme, mode, iterations, benchmark, strategy)
    results = []
    for log in logs:
        try:
            if benchmark == "speed":
                result = parseLogSpeed(log)
            elif benchmark == "stack":
                result = parseLogStack(log)
            else:
                raise ValueError(f"invalid benchmark value '{benchmark}'")
        except:
            print("parsing log failed -> retry")
            return bench(scheme, mode, texName, iterations, benchmark, compiler)
        results.append(result)

    avgResults = average(results)
    print(f"% M4 {benchmark} results for {scheme} using {compiler}\n", file=outfile)
    if benchmark == "speed":
        print(toMacro(f"{texName}iterations", iterations), end='', file=outfile)

    for key, value in avgResults.items():
        macro = toMacro(f"{texName}{key}", value)
        print(macro.strip())
        print(macro, end='', file=outfile)
    print('', file=outfile, flush=True)


with open(f"m4benchmarks.tex", "a") as outfile:
    iterations = 10000

    now = datetime.datetime.now(datetime.timezone.utc)
    print(f"% Benchmarking measurements written on {now}\n", file=outfile)

    for strat in [1, 2, 3]:
        bench("dilithium2", 2, f"mfourdilithiumIIstrat{strat}", iterations, "speed", "gcc", strat)
        bench("dilithium2", 2, f"mfourdilithiumIIstrat{strat}", 1, "stack", "gcc", strat)
        bench("dilithium3", 3, f"mfourdilithiumIIIstrat{strat}", iterations, "speed", "gcc", strat)
        bench("dilithium3", 3, f"mfourdilithiumIIIstrat{strat}", 1, "stack", "gcc", strat)
        bench("dilithium4", 4, f"mfourdilithiumIVstrat{strat}", iterations, "speed", "gcc", strat)
        bench("dilithium4", 4, f"mfourdilithiumIVstrat{strat}", 1, "stack", "gcc", strat)
