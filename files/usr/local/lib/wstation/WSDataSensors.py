#!/usr/bin/python
# -*- coding: utf-8 -*-
# ----------------------------------------------------------------------------
# Base class of Weather-Station sensor data collectors.
#
# This class provides common methods for specific sensor implementations.
#
# Author: Bernhard Bablok
# License: GPL3
#
# Website: https://github.com/bablokb/pi-wstation2
#
# ----------------------------------------------------------------------------

import threading

# ----------------------------------------------------------------------------

class WSDataSensors(threading.Thread):
  """ Class for collecting of a sensor values """

  # --- constructor   -------------------------------------------------------

  def __init__(self,group_name,group,options):
    """ constructor """

    super(WSDataSensors,self).__init__()

    self._options         = options
    self._logger          = options.logger
    self._stop_event      = options.stop_event
    self._group_name      = group_name
    self._update_interval = group['update']
    self._type            = group['type']
    self._label           = group['label']
    self._sensors         = group['sensors']
    self._params          = group['params']

    # initialize values
    self._values = {}
    for sensor,_ in self._sensors:
      self._values[sensor]            = {}
      self._values[sensor]['current'] = 0
      self._values[sensor]['min']     = 100000
      self._values[sensor]['max']     = -100000
      
  # --- save data   ---------------------------------------------------------

  def save_values(self,values):
    """ save data and update aggregates """

    index = 0
    for sensor,unit in self._sensors:
      val = values[index]
      self._logger.msg("INFO","%s: %s: %r %s" % (self._label,sensor,val,unit))
      self._values[sensor]['current'] = val
      if not isinstance(val,str):
        self._values[sensor]['min']     = min(val,self._values[sensor]['min'])
        self._values[sensor]['max']     = max(val,self._values[sensor]['max'])
      index += 1

  # --- return data   --------------------------------------------------------

  def get_values(self,metrics):
    """ return data """

    group_data = {}
    for sensor,_ in self._sensors:
      sensor_data = {}
      for metric in metrics:
        sensor_data[metric] = self._values[sensor][metric]
      group_data[sensor] = sensor_data
    return group_data
