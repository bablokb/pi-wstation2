#!/usr/bin/python
# -*- coding: utf-8 -*-
# ----------------------------------------------------------------------------
# This class is the data-collector for LM75-sensors (via PIC+RFM12B).
# The sensor delivers values for temperature and voltage.
#
# Author: Bernhard Bablok
# License: GPL3
#
# Website: https://github.com/bablokb/pi-wstation2
#
# ----------------------------------------------------------------------------

import wstation

def twos_comp(val, bits):
  """compute the 2's complement of int value val"""
  if (val & (1 << (bits - 1))):      # if sign bit is set e.g., 8bit: 128-255
    val = val - (1 << bits)          # compute negative value
  return val                         # return positive value as is
  
# ----------------------------------------------------------------------------

class WSDataLM75(wstation.WSDataRemote):
  """ Class for collecting of a sensor values """

  # --- constructor   -------------------------------------------------------

  def __init__(self,group_name,group,options):
    """ constructor """

    super(WSDataLM75,self).__init__(group_name,group,options)

  # --- convert data   ------------------------------------------------------

  def convert_data(self,data):
    """ convert data to temperature and voltage """

    [u_high,u_low,t_high,t_low] = data
    self._logger.msg("DEBUG","sid: %d, U:(%d %d), T:(%d %d)" %
                                         (self._sid,u_low,u_high,t_low,t_high))

    #U is a raw ADC-value with 10-bit resolution
    u = (u_high << 8) + u_low
    u = int((2*u*2500)/1024)

    fraction = 0.5*(t_low >> 7)        # bit7==1: 0.5, else 0.0
    t = twos_comp(t_high,8) + fraction
    return [t,u]

