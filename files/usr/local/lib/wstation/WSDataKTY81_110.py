#!/usr/bin/python
# -*- coding: utf-8 -*-
# ----------------------------------------------------------------------------
# This class is the data-collector for KTY81_110-sensors (via PIC+RFM12B).
# The sensor delivers values for temperature and voltage.
#
# Author: Bernhard Bablok
# License: GPL3
#
# Website: https://github.com/bablokb/pi-wstation2
#
# ----------------------------------------------------------------------------

import threading, traceback
from binascii import hexlify
import wstation

try:
  import serial
  simulate = False
except:
  self._logger.msg("DEBUG",traceback.format_exc())
  import random
  simulate = True

BAUD_RATE = 1200
PORT      = "/dev/serial0"
TIMEOUT   = 2

# ----------------------------------------------------------------------------

class WSDataKTY81_110(wstation.WSDataSensors):
  """ Class for collecting of a sensor values """

  _lock = threading.Lock()
  _instances = {}
  _simulate  = simulate

  # --- constructor   -------------------------------------------------------

  def __init__(self,group_name,group,options):
    """ constructor """

    super(WSDataKTY81_110,self).__init__(group_name,group,options)
    # get sid of current KTY81
    self._sid = int(next(param[1] for param in self._params if param[0] == 'sid'))
    WSDataKTY81_110._instances[self._sid] = self
    self._logger.msg("DEBUG","created instance for sid: %d" % self._sid)

  # --- initialize serial port   --------------------------------------------

  def _init_serial(self,con):
    """ initialize serial port """

    try:
      con.baudrate = BAUD_RATE
      con.port     = PORT
      con.timeout  = TIMEOUT
      if con.isOpen():
        con.close()
      self._logger.msg("DEBUG","opening %s with baud-rate %d and timeout %d" %
                               (PORT,BAUD_RATE,TIMEOUT))
      con.open()
      self._logger.msg("DEBUG","successfully opened %s " % PORT)
      return False
    except:
      self._logger.msg("DEBUG",traceback.format_exc())
      return True

  # --- read data from serial port   ----------------------------------------

  def _read_serial(self,con):
    """ read data from serial port """

    # send read request
    self._logger.msg("DEBUG","sending read-request to PIC")
    con.write(b"W")

    # now read data
    try:
      for i in range(4):
        data = con.read(5);
        self._logger.msg("DEBUG","received %d bytes: %r" % (len(data),hexlify(data)))
        if len(data) < 5:
          self._logger.msg("DEBUG","incomplete data")
          break
        [sid,u_low,u_high,t_val,t_sign] = data
        self._logger.msg("DEBUG","sid: %d, U:(%d %d), T:(%d %d)" % (sid,u_low,u_high,t_val,t_sign))
        u = (u_high << 8) + u_low
        t = -t_val if t_sign else t_val
        if sid in WSDataKTY81_110._instances:
          WSDataKTY81_110._instances[sid].save_values([t,u])
        else:
          self._logger.msg("DEBUG","ignoring sid: %d" % sid)
    except:
      self._logger.msg("DEBUG",traceback.format_exc())

  # --- collect data   ------------------------------------------------------

  def run(self):
    self._logger.msg("INFO","starting data-collector for %s (type: %s)" %
                     (self._label, self._type))
    if not WSDataKTY81_110._lock.acquire(False):
      self._logger.msg("INFO","%s: KTY81-110 interface already running" %
                       self._label)
      return

    if not WSDataKTY81_110._simulate:
      serial_device = serial.Serial()
      WSDataKTY81_110._simulate = self._init_serial(serial_device)
      if WSDataKTY81_110._simulate:
        self._logger.msg("INFO","simulating KTY81_110")
    while True:
      if WSDataKTY81_110._simulate:
        rand = random.triangular(0.5,1.0,1.5)
        self.save_values([round(20*rand,1),round(3.5*rand,1)])
      else:
        try:
          serial_device.write(b"W")
          self._read_serial(serial_device)
        except:
          self._logger.msg("DEBUG",traceback.format_exc())
      if self._stop_event.wait(self._update_interval):
        break
    self._logger.msg("INFO","stopping data-collector for all KTY81_110")
