# ----------------------------------------------------------------------------
# Makefile for remote-sensor LM75A with RFM12B
#
# Author: Bernhard Bablok
# License: GPL3
#
# Website: https://github.com/bablokb/pi-wstation2
#
# ----------------------------------------------------------------------------

.PHONY: flash clean

PROJECT=sonde-tx3
MODEL=16F690

$(PROJECT).hex: *.asm
	gpasm -a inhx8m $(PROJECT).asm


flash: $(PROJECT).hex
	pk2cmd -Ppic$(MODEL) -X -M -F $(PROJECT).hex

clean:
	@rm -f *.o *.map *.hex *.cod *.lst
