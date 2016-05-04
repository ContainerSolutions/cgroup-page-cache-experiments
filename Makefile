PROGS:=mmap_pagefault_test
CFLAGS=-static -Wall -Werror -pedantic -std=c11

all: ${PROGS}

container: all
	cp ./mmap_pagefault_test container/mmap_pagefault_test
	cd container; docker build -t cgroup-experiment .

clean:
	rm -f ${PROGS}

.PHONY: container
