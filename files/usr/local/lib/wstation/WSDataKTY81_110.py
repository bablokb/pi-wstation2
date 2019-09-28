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

import wstation

# ----------------------------------------------------------------------------

class WSDataKTY81_110(wstation.WSDataRemote):
  """ Class for collecting of a sensor values """

  # --- constructor   -------------------------------------------------------

  def __init__(self,group_name,group,options):
    """ constructor """

    super(WSDataKTY81_110,self).__init__(group_name,group,options)

  # --- convert data   ------------------------------------------------------

  def convert_data(self,data):
    """ convert data to temperature and voltage """

    [u_low,u_high,t_val,t_sign] = data
    self._logger.msg("DEBUG","sid: %d, U:(%d %d), T:(%d %d)" %
                                         (self._sid,u_low,u_high,t_val,t_sign))
    u = (u_high << 8) + u_low
    t = -t_val if t_sign else t_val
    return [t,u]
