#!/usr/bin/python
# -*- coding: utf-8 -*-
# ----------------------------------------------------------------------------
# Weather-Station sensor widget.
#
# This widget will display the sensor-value of the LM75 within a HBox.
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

class WSGuiLM75(wstation.WSGuiSensors):
  """ Widget for the display of LM75 sensor values """

  # --- constructor   -------------------------------------------------------

  def __init__(self,id,settings=fbgui.Settings(),parent=None):
    """ constructor """

    super(WSGuiLM75,self).__init__(id,settings=settings,parent=parent)
    self._create_childs()

  # --- create child widgets   ----------------------------------------------

  def _create_childs(self):
    """ create widget-tree for ourself """

    self._create_standard_childs()
