#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ----------------------------------------------------------------------------
# Display weather-data on a framebuffer display using pygame-fbgui.
#
# Author: Bernhard Bablok
# License: GPL3
#
# Website: https://github.com/bablokb/pi-wstation2
#
# ----------------------------------------------------------------------------

import sys, os, locale, threading
from argparse import ArgumentParser

sys.path.append(os.path.join(os.path.dirname(sys.argv[0]),"../lib"))
import fbgui
import wstation

# --- helper-class for options   --------------------------------------------

class Options(object):
  pass

# --- cmdline-parser   ------------------------------------------------------

def get_parser():
  """ configure cmdline-parser """

  parser = ArgumentParser(add_help=False,
    description='Pi Weatherstation GUI')

  parser.add_argument('-l', '--level', dest='level', default='INFO',
                      metavar='debug-level',
                      choices=['NONE','ERROR','WARN','INFO','DEBUG','TRACE'],
    help='debug level: one of NONE, ERROR, WARN, INFO, DEBUG, TRACE')
  parser.add_argument('-y', '--syslog', action='store_true',
    dest='syslog',
    help='log to syslog')

  parser.add_argument('-h', '--help', action='help',
    help='print this help')

  return parser

# ----------------------------------------------------------------------------

if __name__ == '__main__':

  # set local to default from environment
  locale.setlocale(locale.LC_ALL, '')

  # parse commandline-arguments
  opt_parser     = get_parser()
  options        = opt_parser.parse_args(namespace=Options)

  # read configuration-file
  conf   = wstation.WSConf()


  settings             = fbgui.Settings()
  gui_config           = fbgui.Settings()
  settings.sensor_info = fbgui.Settings()
  settings.web         = fbgui.Settings()
  settings.stop_event  = threading.Event()
  settings.msg_level   = options.level

  conf.read_gui_config(gui_config)
  conf.read_sensor_config(settings.sensor_info)
  conf.read_web_config(settings.web)
  settings.copy(gui_config)

  settings.font_path = os.path.join(os.path.dirname(sys.argv[0]),"../share/fonts")

  wstation = wstation.WSGuiApp(settings)
  wstation.run()
