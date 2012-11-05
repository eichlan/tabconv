
PREFIX ?= /usr/local
INSTALL ?= install

.PHONY: default clean install

default: tabconv

clean:
	-rm tabconv.c tabconv

install: tabconv
	${INSTALL} tabconv ${PREFIX}/bin

tabconv: tabconv.c
	cc tabconv.c -g -o tabconv

tabconv.c: tabconv.l
	flex -o tabconv.c tabconv.l

