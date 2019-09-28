#!/usr/bin/python
# -*- coding: utf-8 -*-
# ----------------------------------------------------------------------------
# This class is the data-collector for OpenWeatherMap API.
#
# Parameters:
#  key: API-key
#  location: location
#  owminfo: current|day|future
#
# Collected data:
#   current: temperature, pressure, humidity, wind, degrees, status
#   day:     temp_min, temp_max
#   future:  (temp_min, temp_max, status),(...),(...) (tomorrow,+2,+3)
#
# Author: Bernhard Bablok
# License: GPL3
#
# Website: https://github.com/bablokb/pi-wstation2
#
# ----------------------------------------------------------------------------

import pyowm, socket
import wstation

# ----------------------------------------------------------------------------

class WSDataOWM(wstation.WSDataSensors):
  """ Class for collecting sensor values for the OWM """

  # --- constructor   -------------------------------------------------------

  def __init__(self,group_name,group,options):
    """ constructor """

    super(WSDataOWM,self).__init__(group_name,group,options)

    # configure owm (self._params is list of (name,value)-pairs)
    key = next(param[1] for param in self._params if param[0] == 'key')
    self._loc = next(
      param[1] for param in self._params if param[0] == 'location')

    self._logger.msg("DEBUG","key: %s, location: %s" % (key,self._loc))

    self._owm    = pyowm.OWM(key)
    self._online = False

  # --- check online-status   -----------------------------------------------

  def _check_online_status(self):
    """ check online status """

    self._logger.msg("DEBUG","OWM: checking online-status ...")
    try:
      socket.setdefaulttimeout(2)
      socket.socket(socket.AF_INET,
                    socket.SOCK_STREAM).connect(("9.9.9.9",53))
      self._logger.msg("DEBUG","OWM: internet connection available ...")
      self._online = self._owm.is_API_online()
    except:
      self._online = False
    self._logger.msg("DEBUG","OWM: online-status: %r" % self._online)

  # --- get data of a given weather-object   --------------------------------

  def _get_owm_data(self,wo):
    """ return data of a given weather-object """

    wind = wo.get_wind()      # {'speed': 4.6, 'deg': 330}
    if 'deg' not in wind:
      wind['deg'] = 0
    hum  = wo.get_humidity()  # 87
    #                           {'temp_max': 10.5, 'temp': 9.7, 'temp_min': 9.0}
    temp = wo.get_temperature('celsius')
    pres = wo.get_pressure()
    status = "%d" % wo.get_weather_code()

    return [temp['temp'],pres['press'],hum,wind['speed'],str(wind['deg']),status]

  # --- collect data   ------------------------------------------------------

  def run(self):
    self._logger.msg("INFO","starting data-collector for %s (type: %s)" %
                     (self._label, self._type))

    self._check_online_status()
    while True:
      if self._stop_event.wait(self._update_interval):
        break

      # current weather
      observation = self._owm.weather_at_place(self._loc)
      w = observation.get_weather()
      self._get_owm_data(w)

      # forecast
      fc = self._owm.three_hours_forecast(self._loc).get_forecast()
      for w in fc:
        self._get_owm_data(w)

      #self.save_values([ddd,aaa,xxx])

    self._logger.msg("INFO","stopping data-collector for %s (type: %s)" %
                     (self._label, self._type))
