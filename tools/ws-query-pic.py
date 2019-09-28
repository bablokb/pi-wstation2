#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ----------------------------------------------------------------------------
# Testprogramm Abfrage PIC.
#
# Parameter:
#   Serielles Interface (z.B. /dev/serial0)
#   Intervall in Sekunden (default: 5)
#   Anzahl (default: 0, d.h. unbeschränkt)
#   Dez-Mode (default: nein, d.h. hexadezimal)
#
# Author: Bernhard Bablok
# License: GPL3
#
# Website: https://github.com/bablokb/pi-wstation2
#
# ----------------------------------------------------------------------------

import sys, os, serial, traceback
import threading
from time import sleep

BAUD_RATE = 1200
PACKET_SIZE = 5

stop = False

# ----------------------------------------------------------------------------

def read_data():
  while True:
    if stop:
      break
    try:
      data = serial_port.read(PACKET_SIZE);
      if len(data) == PACKET_SIZE:
        print("data: ", end="")
        for b in data:
          print(mode % b,end="")
        print("",flush=True)
      else:
        print("incomplete data (%d bytes)" % len(data))
    except:
      pass
      #print(traceback.format_exc())

# ----------------------------------------------------------------------------

if __name__ == '__main__':
  assert len(sys.argv) > 1

  port     = sys.argv[1]
  interval = 5        if len(sys.argv) < 3 else int(sys.argv[2])
  count    = -1       if len(sys.argv) < 4 else int(sys.argv[3])
  mode     = "%#04x " if len(sys.argv) < 5 else "%03d "

  print("port:     %s" % port)
  print("interval: %d" % interval)
  print("count:    %d" % count)

  serial_port          = serial.Serial()
  serial_port.baudrate = BAUD_RATE
  serial_port.port     = port
  serial_port.timeout  = 2*interval

  if serial_port.isOpen():
    serial_port.close()
  serial_port.open()

  reader = threading.Thread(target=read_data, args=())
  reader.start()

  while True:
    if count > -1: print("count: %d" % count)
    try:
      serial_port.write(b"W")
    except KeyboardInterrupt:
      break
    count -= 1
    if count == -1:
      break
    sleep(interval)

  stop = True
  serial_port.close()
