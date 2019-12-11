Weatherstation based on a Pi and PICs
=====================================

This is yet another Pi-weatherstation. Sensors with PIC16F690 transfer the
data using the RMF12B (833MHz) to a central PIC16F690. This pic is
connected to a Pi which collects the data and provides a small web-server
for clients.

Included is also a client for a small (e.g. 4") display attached to a
Pi-Zero-W. The client can run on the same machine as the data-collector.

