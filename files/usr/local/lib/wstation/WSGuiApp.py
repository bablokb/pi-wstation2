#!/usr/bin/python
# -*- coding: utf-8 -*-
# ----------------------------------------------------------------------------
# Weather-Station main application class.
#
# Author: Bernhard Bablok
# License: GPL3
#
# Website: https://github.com/bablokb/pi-wstation2
#
# ----------------------------------------------------------------------------

import sys, os, threading, simplejson, traceback
import http.client as httplib

import fbgui
import wstation

# ----------------------------------------------------------------------------

class WSGuiApp(fbgui.App):
  """ subclass of App for this application """

  # -------------------------------------------------------------------------

  def __init__(self,settings=fbgui.Settings()):
    """ constructor """

    super(WSGuiApp,self).__init__(settings=settings)
    self._stop_event      = getattr(settings,'stop_event',threading.Event())
    self._sensors         = settings.sensor_info.sensors
    self._update_interval = settings.sensor_info.update

    self._create_gui()
    self._main_panel.pack()
    self.set_widget(self._main_panel)

    # prebuild query-string for data-provider
    self._query_string=(
      "/query?groups=%s&metrics=current" % ','.join(self._sensors.keys()))
    fbgui.App.logger.msg("DEBUG","query-string: %s" % self._query_string)

    # create reusable request-object
    try:
      self._request = httplib.HTTPConnection(
                              settings.web.host,settings.web.port,timeout=10)
      fbgui.App.logger.msg("DEBUG","created request-object")
    except:
      fbgui.App.logger.msg("ERROR","could not create request-object")
      fbgui.App.logger.msg("ERROR",traceback.format_exc())
      self._request = None

  # -------------------------------------------------------------------------

  def _create_gui(self):
    """ create widget-tree """
    
    self._main_panel = fbgui.VBox("main",
                      settings=fbgui.Settings({'margins': 2,
                                               'padding': 5}),
                      toplevel=True)
    # add datetime
    self._dt = wstation.WSGuiDateTime("dt_hbox",
                      settings=fbgui.Settings({
                               'secs' : False,
                               'align': fbgui.CENTER,
                               'stop_event': self._stop_event}),
                      parent=self._main_panel)
    fbgui.Line("main_line_dt",
               settings=fbgui.Settings({
                 'align': fbgui.CENTER,
                 'width': 0.9}),
               parent=self._main_panel)

    # add sensor-displays
    self._sensor_widgets = {}
    for group in self._sensors.keys():
      stype  = self._sensors[group]['type']
      slabel = self._sensors[group]['label']
      # create GUI-object for stype
      fbgui.App.logger.msg("DEBUG","creating widget for %s (type: %s)" %
                       (slabel,stype))

      self._sensor_widgets[group] = (
        wstation.__dict__["WSGui"+stype](
          "widget_"+group,
          settings=fbgui.Settings({
            'align': fbgui.LEFT,
            'name': group,
            'group': self._sensors[group]
            }),
          parent=self._main_panel))
      # add a divider
      fbgui.Line("main_line_"+group,
                 settings=fbgui.Settings({
                   'align': fbgui.CENTER,
                   'width': 0.9}),
                 parent=self._main_panel)

  # -----------------------------------------------------------------------

  def _query_data(self):
    """ query data from data-provider """

    fbgui.App.logger.msg("DEBUG","starting query-thread")
    if not self._request:
      fbgui.App.logger.msg("ERROR","cannot update values, no request-object")
      return
    while True:
      try:
        self._request.request("GET", self._query_string)
      except:
        fbgui.App.logger.msg("WARN","no connection to data-server")
        fbgui.App.logger.msg("DEBUG",traceback.format_exc())
        self._request.close()
      try:
        response = self._request.getresponse()
        if response.status == httplib.OK:
          response_data = response.read()
          fbgui.App.logger.msg("DEBUG","response: %s" % response_data)
          values = simplejson.loads(response_data)
          self._update_sensors(values)
      except:
        fbgui.App.logger.msg("DEBUG",traceback.format_exc())
      if self._stop_event.wait(self._update_interval):
        break

  # -----------------------------------------------------------------------

  def _update_sensors(self,values,refresh=True):
    """ update sensors. The arg values is a map name->(value-map,...) """

    for name in values.keys():
      self._sensor_widgets[name].update(values[name],refresh=refresh)

  # -----------------------------------------------------------------------

  def on_quit(self,rc):
    """ override base-class quit-method """

    super(WSGuiApp,self).on_quit(rc)
    self._stop_event.set()
    sys.exit(0)

  # -----------------------------------------------------------------------

  def on_start(self):
    """ start helper-threads """

    self._dt.start()
    threading.Thread(target=self._query_data).start()

    # for static layout-tests
    values = {
      "indoor": {
        "temperature": {"current": 21.8},
        "pressure": {"current": 1058},
        "humidity": {"current": 60}},
      "outdoor": {
        "temperature": {"current": 0}},
      "internet": {
        "temperature": {"current": 17.0},
        "pressure": {"current": 824},
        "humidity": {"current": 46},
        "wind": {"current": 4.3},
        "dir": {"current": 306},
        "status": {"current": 680}}}
    #self._update_sensors(values)
