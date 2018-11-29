# Argon Wrapper Makefile
# This file is based on the original Argon2 reference
# Argon2 source code package
# 
# This work is licensed under a Creative Commons CC0 1.0 License/Waiver.
# 
# You should have received a copy of the CC0 Public Domain Dedication along with
# this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
#

DIST_SRC = ../phc-winner-argon2/src
SRC = $(DIST_SRC)/argon2.c $(DIST_SRC)/core.c $(DIST_SRC)/blake2/blake2b.c $(DIST_SRC)/thread.c $(DIST_SRC)/encoding.c argon_wrap.c
OBJ = $(SRC:.c=.o)

CFLAGS = -pthread -O3 -Wall -g -I../phc-winner-argon2/include -I../phc-winner-argon2/src

OPTTEST := $(shell $(CC) -Iinclude -Isrc -march=native src/opt.c -c 2>/dev/null; echo $$?)
# Detect compatible platform
ifneq ($(OPTTEST), 0)
	SRC += $(DIST_SRC)/ref.c
else
	CFLAGS += -march=native
	SRC += $(DIST_SRC)/opt.c
endif


BUILD_PATH := $(shell pwd)
KERNEL_NAME := $(shell uname -s)

LIB_NAME=argon2_wrap
ifeq ($(KERNEL_NAME), Linux)
	LIB_EXT := so
	LIB_CFLAGS := -shared -fPIC
endif
ifeq ($(KERNEL_NAME), NetBSD)
	LIB_EXT := so
	LIB_CFLAGS := -shared -fPIC
endif
ifeq ($(KERNEL_NAME), Darwin)
	LIB_EXT := bundle
	LIB_CFLAGS := -bundle
endif
ifeq ($(findstring MINGW, $(KERNEL_NAME)), MINGW)
	LIB_EXT := dll
	LIB_CFLAGS := -shared -Wl,--out-implib,lib$(LIB_NAME).$(LIB_EXT).a
endif
ifeq ($(KERNEL_NAME), $(filter $(KERNEL_NAME),OpenBSD FreeBSD))
	LIB_EXT := so
	LIB_CFLAGS := -shared -fPIC
endif
ifeq ($(KERNEL_NAME), SunOS)
    CC := gcc
    CFLAGS += -D_REENTRANT
    LIB_EXT := so
    LIB_CFLAGS := -shared -fPIC
endif

LIB_SH := lib$(LIB_NAME).$(LIB_EXT)

all: libs 
libs: $(SRC)
		$(CC) $(CFLAGS) $(LIB_CFLAGS) $^ -o libargon2_wrap.$(LIB_EXT)

#Deliberately avoiding the CFLAGS for our test cases - disable optimise and
#C89
test: $(SRC) test.c
	clang -pthread -O3 -fsanitize=address -fsanitize=undefined -Wall -g $^ -o tests $(CFLAGS)
	./tests

clean:
	rm -f tests libargon2_wrap.$(LIB_EXT)

install:
	echo none
