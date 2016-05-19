help:
	cat README.md

### PROGRAMS
programs:
	make -C programs
	cp programs/mmap_pagefault_test .

### INPUTS

all_inputs: inputs/ inputs/50mb-A inputs/50mb-B inputs/50mb-C inputs/1G-A inputs/1G-B inputs/1G-C inputs/1G-D

inputs/:
	mkdir inputs

inputs/50mb-A:
	dd if=/dev/urandom of=$@ bs=1M count=50
inputs/50mb-B:
	dd if=/dev/urandom of=$@ bs=1M count=50
inputs/50mb-C:
	dd if=/dev/urandom of=$@ bs=1M count=50

inputs/1G-A:
	dd if=/dev/urandom of=$@ bs=1M count=1024
inputs/1G-B:
	dd if=/dev/urandom of=$@ bs=1M count=1024
inputs/1G-C:
	dd if=/dev/urandom of=$@ bs=1M count=1024
inputs/1G-D:
	dd if=/dev/urandom of=$@ bs=1M count=1024

.PHONY: inputs programs
