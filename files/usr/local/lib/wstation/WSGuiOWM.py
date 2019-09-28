#!/usr/bin/python
# -*- coding: utf-8 -*-
# ----------------------------------------------------------------------------
# Weather-Station sensor widget.
#
# This widget will display the current weather provided by
# OpenWeatherMap.org within a HBox.
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

class WSGuiOWM(wstation.WSGuiSensors):
  """ Widget for the display of OWM sensor values """

  # --- constructor   -------------------------------------------------------

  def __init__(self,id,settings=fbgui.Settings(),parent=None):
    """ constructor """

    super(WSGuiOWM,self).__init__(id,settings=settings,parent=parent)
    self._create_childs()

  # --- create child widgets   ----------------------------------------------

  def _create_childs(self):
    """ create widget-tree for ourself """

    self._create_label()
    hbox = self._create_group_box()
    sensor,unit = self._group['sensors'][0]
    self._create_sensor_box(hbox,sensor,unit)
