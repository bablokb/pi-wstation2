#!/usr/bin/python
# -*- coding: utf-8 -*-
# ----------------------------------------------------------------------------
# Simplistic web-server server data-queries.
#
# http://host:port/query?groups=a,b&metrics=min,max,current
#
# returns: {'a': {'s1': {'min': val, 'max': val, 'current': val},
#                 's2': {'min': val, 'max': val, 'current': val}
#                 },
#           'b': {'x1': {'min': val, 'max': val, 'current': val},
#                 'x2': {'min': val, 'max': val, 'current': val}
#                 }
#          }
#
# Author: Bernhard Bablok
# License: GPL3
#
# Website: https://github.com/bablokb/pi-wstation2
#
# ----------------------------------------------------------------------------

from http.server import BaseHTTPRequestHandler, HTTPServer
import http.client as httplib
import urllib, simplejson

class WSDataRequestHandler(BaseHTTPRequestHandler):
  """ simplistic web-server for data-queries """

  # --- query content of the response   --------------------------------------

  def _get_content(self,groups,metrics):
    """ return response-content """

    # collect values for each group
    content = {}
    for group in groups:
      self.server._options.logger.msg("DEBUG",
                                      "_get_content(): processing %s" % group)
      if group in self.server._options.sensor_info.sensors:
        thread = self.server._options.threads[group]
        content[group] = thread.get_values(metrics)
        self.server._options.logger.msg("DEBUG","result for %s: %s" %
                                        (group,content[group]))
      else:
        self.server._options.logger.msg("ERROR","invalid group: %s" % group)

    # dump content-object to json and return it
    json_content = simplejson.dumps(content)
    self.server._options.logger.msg("DEBUG","_get_content(): %s" % json_content)
    return (httplib.OK,json_content.encode('utf-8'))

  # --- set header of response   ---------------------------------------------

  def _set_headers(self,code,length):
    self.send_response(code)
    self.send_header('Content-length', length)
    self.send_header('Content-type', 'application/json')
    self.end_headers()

  # --- process GET request   ------------------------------------------------

  def do_GET(self):
    self.server._options.logger.msg("DEBUG","do_get(): requestline: %s" %
                             self.requestline)
    query_string = urllib.parse.urlparse(self.path)[4]
    self.server._options.logger.msg("DEBUG","do_get(): query-string: %s" %
                             query_string)
    query_dict = urllib.parse.parse_qs(query_string)
    self.server._options.logger.msg("DEBUG","do_get(): query-dict: %r" %
                             (query_dict,))

    # check for groups and metrics in query_dict
    if not ('groups' in query_dict and 'metrics' in query_dict):
      self._set_headers(httplib.BAD_REQUEST,0)
      return

    #extract groups and metriecs
    groups  = query_dict['groups'][0].split(',')
    metrics = query_dict['metrics'][0].split(',')
    self.server._options.logger.msg("DEBUG","do_get(): groups: %r" %
                                    (groups,))
    self.server._options.logger.msg("DEBUG","do_get(): metrics: %r" %
                                    (metrics,))

    # create requested content
    code,content = self._get_content(groups,metrics)
    self._set_headers(code,len(content))
    self.wfile.write(content)

  # --- process HEAD request   -----------------------------------------------

  def do_HEAD(self):
    self._set_headers()

# --- server class   ---------------------------------------------------------

class WSDataServer(HTTPServer):
  """ simplistic web-server for data-queries """

  # --- constructor   --------------------------------------------------------

  def __init__(self,options):
    """ constructor """

    self._options = options
    server_address = (self._options.web.host,self._options.web.port)
    super(WSDataServer,self).__init__(server_address,WSDataRequestHandler)

  # --- run the server   -----------------------------------------------------

  def run(self):
    """ run the server """

    self._options.logger.msg("INFO","starting data-server running on port %s" %
                       self._options.web.port)
    self.serve_forever()

  # --- shutdown the server   -----------------------------------------------

  def shutdown(self):
    """ shutdown the server """

    self._options.logger.msg("INFO","shutdown of data-server")
    super(WSDataServer,self).shutdown()
