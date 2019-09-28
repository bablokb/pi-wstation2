#!/usr/bin/python
# -*- coding: utf-8 -*-
# ----------------------------------------------------------------------------
# Weather-Station date-time widget
#
# Author: Bernhard Bablok
# License: GPL3
#
# Website: https://github.com/bablokb/pi-wstation2
#
# ----------------------------------------------------------------------------

import threading, datetime

import fbgui

# ----------------------------------------------------------------------------

class WSGuiDateTime(fbgui.HBox):
  """ Widget for the display of date and time """

  # --- constructor   -------------------------------------------------------

  def __init__(self,id,settings=fbgui.Settings(),parent=None):
    """ constructor """

    settings.padding = 2
    super(WSGuiDateTime,self).__init__(id,settings=settings,parent=parent)
    self.theme.font_name = 'DSEG7Modern-Regular.ttf'
    self.theme.font_size = fbgui.App.theme.font_size_l

    self._stop_event = settings.stop_event
    self._with_secs  = getattr(settings,"secs",True)
 
    self._create_childs()

  # --- create child widgets   ----------------------------------------------

  def _create_childs(self):
    """ create widget-tree for self widget """
    
    self._weekday = fbgui.Label("dt_weekday","",
                                settings=fbgui.Settings({
                                  'font_name' : 'DSEG14Modern-Regular.ttf'
                                  }),
                                parent=self)
    fbgui.HGap("dt_gap1", settings=fbgui.Settings({
      'size': 10
      }), parent=self)
    self._day     = fbgui.Label("dt_day","",parent=self)
    self._month   = fbgui.Label("dt_month","",parent=self)
    self._year    = fbgui.Label("dt_year","",parent=self)
    fbgui.HGap("dt_gap2", settings=fbgui.Settings({
      'size': 10
      }), parent=self)
    self._time    = fbgui.Label("dt_time","",parent=self)
    if self._with_secs:
      self._secs    = fbgui.Label("dt_secs","",
                                settings=fbgui.Settings({
                                  'font_size': fbgui.App.theme.font_size_m
                                  }),
                                parent=self)

    self._set_time(refresh=False)

  # --- set datetime   ----------------------------------------------------

  def _set_time(self,refresh=True):
    """ set datetime """

    now = datetime.datetime.now()
    [wday,day,month,year,time,secs] = now.strftime("%a %d. %m. %y %H:%M %S").split()
    self._weekday.set_text(wday,refresh=refresh)
    self._day.set_text(day,refresh=refresh)
    self._month.set_text(month,refresh=refresh)
    self._year.set_text(year,refresh=refresh)
    self._time.set_text(time,refresh=refresh)
    if self._with_secs:
      self._secs.set_text(" %s" % secs,refresh=refresh)

  # --- auto-update thread   -----------------------------------------------

  def _update_time(self):
    """ auto-update thread """

    delay = 0.01
    while True:
      if self._stop_event.wait(delay):
        # external break request
        break
      self._set_time(refresh=True)
      if self._with_secs:
        delay = (1000000 - datetime.datetime.now().microsecond)/1000000.0
      else:
        delay = 60 - datetime.datetime.now().second

  # --- start update thread   -----------------------------------------------

  def start(self):
    """ start update thread """

    t = threading.Thread(target=self._update_time)
    t.start()
