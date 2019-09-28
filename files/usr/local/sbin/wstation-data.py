#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ----------------------------------------------------------------------------
# Data-collector for weather-station.
#
# Author: Bernhard Bablok
# License: GPL3
#
# Website: https://github.com/bablokb/pi-wstation2
#
# ----------------------------------------------------------------------------

import sys, os, locale, threading, signal
from argparse import ArgumentParser
import fbgui

sys.path.append(os.path.join(os.path.dirname(sys.argv[0]),"../lib"))

import wstation

# --- helper-class for options   --------------------------------------------

class Options(object):
  pass

# --- cmdline-parser   ------------------------------------------------------

def get_parser():
  """ configure cmdline-parser """

  parser = ArgumentParser(add_help=False,
    description='Pi Weatherstation Data-Collector')

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

# --- start all threads   --------------------------------------------------

def start_threads(options):
  """ Start all threads """

  options.web.data_server = wstation.WSDataServer(options)
  options.web.thread = threading.Thread(target=options.web.data_server.run)
  options.web.thread.start()

  options.threads = {}
  sensors = options.sensor_info.sensors
  for group in sensors.keys():
    stype  = sensors[group]['type']
    slabel = sensors[group]['label']
    # create start thread for stype
    options.logger.msg("INFO","creating data-collector for %s (type: %s)" %
                       (slabel,stype))
    options.threads[group] = wstation.__dict__["WSData"+stype](group,
                                                      sensors[group],options)
    options.threads[group].start()

# --------------------------------------------------------------------------

def signal_handler(_signo, _stack_frame):
  """ Signal-handler to cleanup threads """

  global options

  # send event to all threads
  options.logger.msg("INFO","signal %r received, stopping threads" % _signo)
  options.stop_event.set()
  options.web.data_server.shutdown()

  # wait for threads to terminate
  map(threading.Thread.join, options.threads.values())
  sys.exit(0)

# ----------------------------------------------------------------------------

if __name__ == '__main__':

  # set local to default from environment
  locale.setlocale(locale.LC_ALL, '')

  # parse commandline-arguments
  opt_parser     = get_parser()
  options        = opt_parser.parse_args(namespace=Options)

  # create logger
  options.logger = fbgui.Msg(options.level,options.syslog)

  # read configuration-file
  conf                = wstation.WSConf()
  options.sensor_info = Options()
  conf.read_sensor_config(options.sensor_info)
  options.web         = Options()
  conf.read_web_config(options.web)

  options.stop_event  = threading.Event()

  # setup signal handlers
  signal.signal(signal.SIGTERM, signal_handler)
  signal.signal(signal.SIGINT, signal_handler)

  # create and start threads
  threads = start_threads(options)

  signal.pause() # main loop
