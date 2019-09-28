# ----------------------------------------------------------------------------
# Makefile for remote-sensor KTY81-110 with RFM12B
#
# Author: Bernhard Bablok
# License: GPL3
#
# Website: https://github.com/bablokb/pi-wstation2
#
# ----------------------------------------------------------------------------

.PHONY: flash clean

PROJECT=pic-rfm12b-reader
MODEL=16F690

$(PROJECT).hex: *.asm
	gpasm -a inhx8m $(PROJECT).asm


flash: $(PROJECT).hex
	pk2cmd -Ppic$(MODEL) -X -M -F $(PROJECT).hex

clean:
	@rm -f *.o *.map *.hex *.cod *.lst
