#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ----------------------------------------------------------------------------
# Testprogramm: Simulation des PIC (Gegenstück zu ws-query-pic.py)
#
# Parameter:
#   Serielles Interface (z.B. /dev/serial0)
#
# Author: Bernhard Bablok
# License: GPL3
#
# Website: https://github.com/bablokb/pi-wstation2
#
# ----------------------------------------------------------------------------

import sys, os, serial
import threading
from time import sleep

BAUD_RATE = 1200

# ----------------------------------------------------------------------------

if __name__ == '__main__':
  assert len(sys.argv) > 1

  port     = sys.argv[1]

  print("port:     %s" % port)

  serial_port          = serial.Serial()
  serial_port.baudrate = BAUD_RATE
  serial_port.port     = port
  serial_port.timeout  = 0

  if serial_port.isOpen():
    serial_port.close()
  serial_port.open()

  while True:
    try:
      data = serial_port.read(1);
      if len(data) > 0:
        print("data: %r" % data)
        if data == "W":
          serial_port.write(b"ABCD")
    except KeyboardInterrupt:
      break
    except:
      break

  serial_port.close()
