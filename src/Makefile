SHELL:=/bin/bash
CURDIR=$(dir $(realpath $(lastword $(MAKEFILE_LIST))))


.PHONY: all clean synth DirectMappedBeveren TwoWayBeveren decode_test fetch_test prog_test superclean

MINISPEC_FILES=$(wildcard *.ms)
CACHE_FILES=$(wildcard *Cache*.ms)

all: Processor

Processor: Processor.ms $(MINISPEC_FILES)
	msc $< $@

DecodeTB: DecodeTB.ms Decode.ms
	msc DecodeTB.ms DecodeTB

decode_test: DecodeTB
	./DecodeTB

FetchTB: FetchTB.ms Processor.ms $(CACHE_FILES)
	msc FetchTB.ms FetchTB

fetch_test: FetchTB
	(cd $(CURDIR); rm -rf mem.vmh; ln -sf fetch_test.vmh mem.vmh)
	./FetchTB

DirectMappedBeveren:
	ms sim DirectMappedCacheTB.ms DirectMappedBeverenTest

TwoWayBeveren:
	ms sim TwoWayCacheTB.ms TwoWayBeverenTest

prog_test: Processor
	./test.py

synth:
	synth Processor.ms Processor -l multisize -p 100 | tee synth.out

clean:
	rm -rf *.v *.bo *.ba *.cxx *.o *.h *.so mem.vmh
	rm -rf test_out
	rm -rf synthDir
	rm -rf Processor
	rm -rf DecodeTB
	rm -rf FetchTB
	rm -rf tmp_msc_*

superclean: clean
	make -C sw clean
