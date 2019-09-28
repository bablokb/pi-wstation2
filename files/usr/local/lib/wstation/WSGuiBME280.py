#!/usr/bin/python
# -*- coding: utf-8 -*-
# ----------------------------------------------------------------------------
# Weather-Station sensor widget.
#
# This widget will display the three sensor-values of the BME280 within a HBox.
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

class WSGuiBME280(wstation.WSGuiSensors):
  """ Widget for the display of BME280 sensor values """

  # --- constructor   -------------------------------------------------------

  def __init__(self,id,settings=fbgui.Settings(),parent=None):
    """ constructor """

    super(WSGuiBME280,self).__init__(id,settings=settings,parent=parent)
    self._create_childs()

  # --- create child widgets   ----------------------------------------------

  def _create_childs(self):
    """ create widget-tree for ourself """

    self._create_standard_childs()
