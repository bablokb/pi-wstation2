#!/usr/bin/python
# -*- coding: utf-8 -*-
# ----------------------------------------------------------------------------
# This class is the data-collector for remote-sensors (via PIC+RFM12B).
# These sensors deliver values for temperature and voltage.
#
# This is the base class of more specific classes and deals with the
# interface to the PIC.
#
# Author: Bernhard Bablok
# License: GPL3
#
# Website: https://github.com/bablokb/pi-wstation2
#
# ----------------------------------------------------------------------------

import threading, traceback, random
from binascii import hexlify
import wstation

try:
  import serial
  simulate = False
except:
  print(traceback.format_exc())
  simulate = True

BAUD_RATE = 1200
PORT      = "/dev/serial0"
TIMEOUT   = 2

# ----------------------------------------------------------------------------

class WSDataRemote(wstation.WSDataSensors):
  """ Class for collecting of a sensor values """

  _lock = threading.Lock()
  _instances = {}
  _simulate  = simulate

  # --- constructor   -------------------------------------------------------

  def __init__(self,group_name,group,options):
    """ constructor """

    super(WSDataRemote,self).__init__(group_name,group,options)
    # get sid of current sensor
    self._sid = int(next(param[1] for param in self._params if param[0] == 'sid'))
    WSDataRemote._instances[self._sid] = self
    self._logger.msg("DEBUG","created instance for sid: %d" % self._sid)

  # --- initialize serial port   --------------------------------------------

  def _init_serial(self):
    """ initialize serial port """

    self._serial_device = serial.Serial()
    try:
      self._serial_device.baudrate = BAUD_RATE
      self._serial_device.port     = PORT
      self._serial_device.timeout  = TIMEOUT
      if self._serial_device.isOpen():
        self._serial_device.close()
      self._logger.msg("DEBUG","opening %s with baud-rate %d and timeout %d" %
                               (PORT,BAUD_RATE,TIMEOUT))
      self._serial_device.open()
      self._logger.msg("DEBUG","successfully opened %s " % PORT)
      return False
    except:
      self._logger.msg("DEBUG",traceback.format_exc())
      return True

  # --- read data from serial port   ----------------------------------------

  def query_data(self):
    """ read data from serial port """

    # send read request
    self._logger.msg("DEBUG","sending read-request to PIC")
    self._serial_device.write(b"W")

    # now read data
    try:
      for i in range(4):
        data = self._serial_device.read(5);
        self._logger.msg("DEBUG","received %d bytes: %r" % (len(data),hexlify(data)))
        if len(data) < 5:
          self._logger.msg("DEBUG","incomplete data")
          break
        sid = data[0]
        if sid in WSDataRemote._instances:
          [t,u] = WSDataRemote._instances[sid].convert_data(data[1:])
          WSDataRemote._instances[sid].save_values([t,u])
        else:
          self._logger.msg("DEBUG","ignoring sid: %d" % sid)
    except:
      self._logger.msg("DEBUG",traceback.format_exc())

  # --- collect data   ------------------------------------------------------

  def run(self):
    self._logger.msg("INFO","starting data-collector for %s (type: %s)" %
                     (self._label, self._type))
    if not WSDataRemote._lock.acquire(False):
      self._logger.msg("INFO","%s: WSDataRemote collector already running" %
                       self._label)
      return

    if not WSDataRemote._simulate:
      WSDataRemote._simulate = self._init_serial()
      if WSDataRemote._simulate:
        self._logger.msg("INFO","simulating remote sensor")
    while True:
      if WSDataRemote._simulate:
        rand = random.triangular(0.5,1.0,1.5)
        self.save_values([round(20*rand,1),int(3500*rand)])
      else:
        try:
          self.query_data()
        except:
          self._logger.msg("DEBUG",traceback.format_exc())
      if self._stop_event.wait(self._update_interval):
        break
    self._logger.msg("INFO","stopping data-collector for all Remote")
