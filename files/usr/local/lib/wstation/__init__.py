#!/usr/bin/python
# -*- coding: utf-8 -*-
# ----------------------------------------------------------------------------
# Weather-Station application module. The file just imports all classes
# into the wstation namespace
#
# Author: Bernhard Bablok
# License: GPL3
#
# Website: https://github.com/bablokb/pi-wstation2
#
# ----------------------------------------------------------------------------

from . WSConf           import WSConf           as WSConf
from . WSDataServer     import WSDataServer     as WSDataServer
from . WSDataSensors    import WSDataSensors    as WSDataSensors
from . WSDataBME280     import WSDataBME280     as WSDataBME280
from . WSDataRemote     import WSDataRemote     as WSDataRemote
from . WSDataKTY81_110  import WSDataKTY81_110  as WSDataKTY81_110
from . WSDataLM75       import WSDataLM75       as WSDataLM75
from . WSDataOWM        import WSDataOWM        as WSDataOWM
from . WSDataOWMCurrent import WSDataOWMCurrent as WSDataOWMCurrent

from . WSGuiApp        import WSGuiApp        as WSGuiApp
from . WSGuiDateTime   import WSGuiDateTime   as WSGuiDateTime
from . WSGuiSensors    import WSGuiSensors    as WSGuiSensors
from . WSGuiBME280     import WSGuiBME280     as WSGuiBME280
from . WSGuiKTY81_110  import WSGuiKTY81_110  as WSGuiKTY81_110
from . WSGuiOWM        import WSGuiOWM        as WSGuiOWM
from . WSGuiOWMCurrent import WSGuiOWMCurrent as WSGuiOWMCurrent
