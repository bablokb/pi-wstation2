#!/usr/bin/python
# -*- coding: utf-8 -*-
# ----------------------------------------------------------------------------
# This class is the data-collector for BME280-sensors with temperature
# and humidity.
#
# Author: Bernhard Bablok
# License: GPL3
#
# Website: https://github.com/bablokb/pi-wstation2
#
# ----------------------------------------------------------------------------

try:
  import smbus2
  import bme280
  simulate = False
except:
  import random
  simulate = True

import wstation

# ----------------------------------------------------------------------------

class WSDataBME280(wstation.WSDataSensors):
  """ Class for collecting sensor values for the BME280 """

  # --- constructor   -------------------------------------------------------

  def __init__(self,group_name,group,options):
    """ constructor """

    super(WSDataBME280,self).__init__(group_name,group,options)

    # get altitude correction factor
    try:
      alt = int(next(param[1] for param in self._params if param[0] == 'altitude'))
      self._alt_fac = pow(1.0-alt/44330.0, 5.255)
    except:
      self._alt_fac = 1.0

    # configure device
    if not simulate:
      port          = 1
      self._address = 0x76   # or 0x77
      self._bus     = smbus2.SMBus(port)
      bme280.load_calibration_params(self._bus,address=self._address)

  # --- collect data   ------------------------------------------------------

  def run(self):
    self._logger.msg("INFO","starting data-collector for %s (type: %s)" %
                     (self._label, self._type))
    while True:
      if self._stop_event.wait(self._update_interval):
        break
      if simulate:
        rand = random.triangular(0.5,1.0,1.5)
        self.save_values([round(20*rand,1),int(970*rand),int(55*rand)])
      else:
        data = bme280.sample(self._bus, address=self._address)
        # correct for altitude
        data.pressure = data.pressure/self._alt_fac
        self.save_values([round(data.temperature,1),
                          int(data.pressure), int(data.humidity)])
    self._logger.msg("INFO","stopping data-collector for %s (type: %s)" %
                     (self._label, self._type))
