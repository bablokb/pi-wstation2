# ----------------------------------------------------------------------------
# Wrapper class for configparser
#
# Author: Bernhard Bablok
# License: GPL3
#
# Website: https://github.com/bablokb/pi-wstation2
#
# ----------------------------------------------------------------------------

import configparser

import fbgui

CONFIG_FILE = '/etc/pi-wstation.conf'

class WSConf(object):
  """ wrapper class for configurations from config-file """

  # --- constructor   --------------------------------------------------------
  
  def __init__(self):
    """ initialize object and read configuration """

    self._parser = configparser.RawConfigParser(inline_comment_prefixes=(';',))
    self._parser.optionxform = lambda option: option
    self._parser.read(CONFIG_FILE)

  # --- read configuration-value   -------------------------------------------

  def _get_config(self,section,option,default):
    """ read a single configuration value """

    if self._parser.has_section(section):
      try:
        value = self._parser.get(section,option)
      except:
        value = default
    else:
      value = default
    return value
  
  # --- read theme-configuration   -------------------------------------------
  
  def _read_theme_config(self,theme_name,config):
    """ read theme configuration """

    fg_color = self._get_config(theme_name,'fg_color','BLACK')
    config.fg_color = getattr(fbgui.Color,fg_color,fbgui.Color.BLACK)

    bg_color = self._get_config(theme_name,'bg_color','SILVER')
    config.bg_color = getattr(fbgui.Color,bg_color,fbgui.Color.SILVER)

    sizes = self._get_config(theme_name,'font_sizes','12 18 24 30 32')
    [config.font_size_s, config.font_size_m,
     config.font_size_l, config.font_size_xl,
     config.font_size_xxl] = [int(size) for size in sizes.split()]

  # --- read gui-configuration   ---------------------------------------------
  
  def read_gui_config(self,config):
    """ read gui configuration """

    config.title   = self._get_config('GUI','title','no title defined')
    config.width   = int(self._get_config('GUI','width',320))
    config.height  = int(self._get_config('GUI','height',480))
    config.theme   = self._get_config('GUI','theme','segment')

    self._read_theme_config(config.theme,config)

  # --- read sensor-configuration   ------------------------------------------

  def read_sensor_config(self,sensor_info):
    """ read sensor configuration """

    # global SENSORS section
    sensor_info.update  = int(self._get_config('SENSORS','update',600))
    sensor_info.log_dir = self._get_config('SENSORS','log_dir',None)

    # read individual sensors
    groups = self._get_config('SENSORS','groups','').split()
    sensor_map  = {}
    for group in groups:
      type    = self._get_config(group,'type','undefined')
      label   = self._get_config(group,'label','unlabelled')
      update  = int(self._get_config(group,'update',sensor_info.update))
      sensors = self._get_config(group,'sensors','').split()
      units   = self._get_config(group,'units','').split()
      sensor_map[group] = {'type'   : type,
                           'label'  : label,
                           'update' : update,
                           'params' : self._parser.items(group),
                           'sensors': list(zip(sensors,units))}

    sensor_info.sensors = sensor_map

  # --- read web-configuration   ------------------------------------------

  def read_web_config(self,web_config):
    """ read sensor configuration """

    # read host and port
    web_config.host = self._get_config('WEB','host','localhost')
    web_config.port = int(self._get_config('WEB','port',8080))
