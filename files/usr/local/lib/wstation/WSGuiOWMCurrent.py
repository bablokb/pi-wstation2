#!/usr/bin/python
# -*- coding: utf-8 -*-
# ----------------------------------------------------------------------------
# Weather-Station sensor widget.
#
# This widget will display the current weather provided by
# OpenWeatherMap.org within a HBox.
#
## Collected data:
#   current: temperature, pressure, humidity, wind, degrees, status
#
# Author: Bernhard Bablok
# License: GPL3
#
# Website: https://github.com/bablokb/pi-wstation2
#
# ----------------------------------------------------------------------------

import fbgui
import wstation

# ----------------------------------------------------------------------------

class WSGuiOWMCurrent(wstation.WSGuiSensors):
  """ Widget for the display of OWM sensor values """

  # --- constructor   -------------------------------------------------------

  def __init__(self,id,settings=fbgui.Settings(),parent=None):
    """ constructor """

    super(WSGuiOWMCurrent,self).__init__(id,settings=settings,parent=parent)
    self._create_childs()

  # --- map direction   -----------------------------------------------------

  def _map_direction(self,degrees):
    """ map wind-direction """

    direction = ['N','NE','E','SE','S','SW','W','NW','N']
    return direction[int((int(degrees)+22.5)/45)]

  # --- map OWM-status-code to weather-font   -------------------------------

  def _map_code(self,code):
    """ map OWM-status-code to weather-font character """

    code = str(code)
    # first try specific codes
    map1 = {
      '201': '6',  # THUNDER RAIN
      '202': '7',  # THUNDER HARD RAIN
      '502': '4',  # HARD RAIN
      '503': '4',  # HARD RAIN
      '504': '4',  # HARD RAIN
      '522': '4',  # HARD RAIN
      '800': '1',  # SUN
      '801': '9',  # SUN AND CLOUD
      '802': '9',  # SUN AND CLOUD
      '803': '9',  # SUN AND CLOUD
      '804': '2'  # CLOUD
      }
    if code in map1:
      return map1[code]

    # try generic codes
    map2 = {
      '2': '8',  # THUNDER
      '3': '3',  # RAIN
      '5': '3',  # RAIN
      '6': '5'   # SNOW
      }
    if code[0] in map2:
      return map2[code[0]] 

    # catch all for unknown codes
    return '0'

  # --- add status-label   --------------------------------------------------

  def _add_status_label(self,parent,status):
    """ map OWM status number to DSEG-weather font-character """

    # TODO: map status to font-character

    return fbgui.Label(self._name+"_status_value","1",
                       settings=fbgui.Settings({
                         'font_name' : 'DSEGWeather.ttf',
                         'font_size' : 2*fbgui.App.theme.font_size_xxl,
                         'align':     fbgui.CENTER
                         }),
                       parent=parent)

  # --- update widget   -----------------------------------------------------

  def update(self,values,refresh=True):
    """ update values. Argument values is a map
             name->{type1: value1,
                    type2: value2, ... }
        with typeX one of current,min,max   """

    # update standard sensor value/unit-boxes
    super(WSGuiOWMCurrent,self).update(values,refresh=refresh)

    # update status
    val = self._map_code(values['status']['current'])
    self._status_label.set_text(val,refresh=refresh)

    # update direction
    deg = self._map_direction(values['dir']['current'])
    self._deg_label.set_text(deg,refresh=refresh)
    #self.post_layout()

  # --- create child widgets   ----------------------------------------------

  def _create_childs(self):
    """ create widget-tree for ourself """

    self._create_label()
    hbox = self._create_group_box()
    hbox.w=0
    hbox.padding=(10,10)

    # inner vbox for temperature and pressure
    vbox1 = fbgui.VBox(self._name+"_vbox1",
                      settings=fbgui.Settings({
                         'align': (fbgui.LEFT,fbgui.CENTER),
                         'font_size' : fbgui.App.theme.font_size_m,
                         'margins': 0,
                         'padding': 10
                         }), parent=hbox)

    # temperature
    temp,temp_unit = self._group['sensors'][0]
    box = self._create_sensor_box(vbox1,temp,temp_unit)

    # pressure
    press,press_unit = self._group['sensors'][1]
    box = self._create_sensor_box(vbox1,press,press_unit)

    # status
    status,_ = self._group['sensors'][5]
    self._status_label = self._add_status_label(hbox,status)

    # inner vbox for humidity and wind
    vbox2 = fbgui.VBox(self._name+"_vbox2",
                      settings=fbgui.Settings({
                         'align': (fbgui.LEFT,fbgui.CENTER),
                         'font_size' : fbgui.App.theme.font_size_m,
                         'margins': 0,
                         'padding': 10
                        }), parent=hbox)

    # humidity
    hum,hum_unit = self._group['sensors'][2]
    self._create_sensor_box(vbox2,hum,hum_unit)

    # wind
    wind,wind_unit = self._group['sensors'][3]
    self._create_sensor_box(vbox2,wind,wind_unit)

    # degrees
    deg, deg_unit  = self._group['sensors'][4]
    self._deg_label = fbgui.Label(self._name+"_degrees","",
                settings=fbgui.Settings({
                  'font_name' : 'FreeSans',
                  }),
                parent=vbox2)
