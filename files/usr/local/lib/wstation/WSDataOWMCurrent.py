#!/usr/bin/python
# -*- coding: utf-8 -*-
# ----------------------------------------------------------------------------
# This class is the data-collector for the current weather
# using OpenWeatherMap API.
#
# Parameters:
#  key: API-key
#  location: location
#
# Collected data:
#   current: temperature, pressure, humidity, wind, degrees, status
#
# Author: Bernhard Bablok
# License: GPL3
#
# Website: https://github.com/bablokb/pi-wstation2
#
# ----------------------------------------------------------------------------

import random, pyowm
import wstation

# ----------------------------------------------------------------------------

class WSDataOWMCurrent(wstation.WSDataOWM):
  """ Class for collecting current weather information from OWM """

  # --- constructor   -------------------------------------------------------

  def __init__(self,group_name,group,options):
    """ constructor """

    super(WSDataOWMCurrent,self).__init__(group_name,group,options)

  # --- collect data   ------------------------------------------------------

  def run(self):
    self._logger.msg("INFO","starting data-collector for %s (type: %s)" %
                     (self._label, self._type))

    self._check_online_status()
    while True:
      if self._stop_event.wait(self._update_interval):
        break

      # current weather
      if self._online:
        observation = self._owm.weather_at_place(self._loc)
        w = observation.get_weather()
        self.save_values(self._get_owm_data(w))
      else:
        # simulate data [temp,pres,hum,wind,deg,status]
        rand = random.triangular(0.5,1.0,1.5)
        self.save_values([round(20*rand,1),
                          int(970*rand),
                          int(55*rand),
                          round(5*rand,1),
                          int(180*rand),
                          int(800*rand)])

    self._logger.msg("INFO","stopping data-collector for %s (type: %s)" %
                     (self._label, self._type))
