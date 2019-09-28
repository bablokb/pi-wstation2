#!/usr/bin/python
# -*- coding: utf-8 -*-
# ----------------------------------------------------------------------------
# Base class of Weather-Station sensor widgets.
#
# This class provides common methods for specific sensor implementations.
#
# Author: Bernhard Bablok
# License: GPL3
#
# Website: https://github.com/bablokb/pi-wstation2
#
# ----------------------------------------------------------------------------

import fbgui

# ----------------------------------------------------------------------------

class WSGuiSensors(fbgui.VBox):
  """ Base class for sensor widgets """

  # --- constructor   -------------------------------------------------------

  def __init__(self,id,settings=fbgui.Settings(),parent=None):
    """ constructor """

    settings.padding = 4
    settings.width   = 1.0
    super(WSGuiSensors,self).__init__(id,settings=settings,parent=parent)

    self._name   = getattr(settings,"name","unknown")
    self._group  = getattr(settings,"group",{})

    self._type            = self._group['type']
    self._label           = self._group['label']
    self._sensors         = self._group['sensors']
    self._params          = self._group['params']
    self._sensor_values   = {}

    self.theme.font_size  = fbgui.App.theme.font_size_l

  # --- create label of VBox   ----------------------------------------------

  def _create_label(self):
    """ create label for widget """

    # label within outer-vbox
    self._widget_label = fbgui.Label(self._name+"_label",self._label,
                              settings=fbgui.Settings({
                                'font_name' : 'FreeSans',
                                'font_size' : fbgui.App.theme.font_size_s,
                                }),
                                parent=self)

  # --- create group box   --------------------------------------------------

  def _create_group_box(self):
    """ create sensor display-box """

    return fbgui.HBox(self._name+"_hbox",
                      settings=fbgui.Settings({
                        'width': 1.0,
                        'align': fbgui.CENTER,
                        'margins': (25,25,0,0)
                        }), parent=self)

  # --- create sensor (unit+value) box   ------------------------------------

  def _create_sensor_box(self,parent,sensor,unit):
    """ create sensor display-box """

    sensor_hbox = fbgui.HBox(self._name+"_"+sensor+"_box",
                             settings=fbgui.Settings({
                               'padding': 2
                               }), parent=parent)
      
    self._sensor_values[sensor] = (
      fbgui.Label(self._name+"_"+sensor+"_value","",
                  settings=fbgui.Settings({
                    'font_name' : 'DSEG7Modern-Regular.ttf',
                    }),
                  parent=sensor_hbox))

    if unit != 'None':                                # yes: 'None' not None
      fbgui.Label(self._name+"_"+sensor+"_unit",unit,
                settings=fbgui.Settings({
                  'align': fbgui.TOP,
                  'font_name' : 'FreeSans',
                  }),
                parent=sensor_hbox)
    return sensor_hbox

  # --- create standard child widgets   -------------------------------------

  def _create_standard_childs(self):
    """ create standard widget-tree for ourself """

    self._create_label()
    hbox = self._create_group_box()

    index     = 0
    max_index = len(self._group.keys())-1
    for sensor,unit in self._group['sensors']:
      index += 1
      # each sensor is in a value+unit hbox
      self._create_sensor_box(hbox,sensor,unit)
      if index < max_index:
        gap = fbgui.HGap(self._name+"_"+sensor+"_gap",
                         settings=fbgui.Settings({'size': 10,
                                                  'weight': 1}),parent=hbox)

  # --- update values   ---------------------------------------------------

  def update(self,values,refresh=True):
    """ update values. Argument values is a map
             name->{type1: value1,
                    type2: value2, ... }
        with typeX one of current,min,max   """

    for sensor in values.keys():
      if sensor in self._sensor_values:
        self._sensor_values[sensor].set_text(
          str(values[sensor]['current']),refresh=refresh)
