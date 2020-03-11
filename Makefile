.PHONY = v
.SILENT:

all: rpt

rpt: *.zig Makefile
	zig build-exe --release-fast --single-threaded --strip -mcpu native rpt.zig \
		-lc -lm \
		-I./Prime95-29.8b6/gwnum/ --library ./Prime95-29.8b6/gwnum/gwnum.a \
		-I./gmp-6.2.0 --library ./gmp-6.2.0/.libs/libgmp.a \
		--name rpt
debug: *.zig Makefile
	zig build-exe --single-threaded -mcpu native rpt.zig \
		-lc -lm \
		-I./Prime95-29.8b6/gwnum/ --library ./Prime95-29.8b6/gwnum/gwnum.a \
		-I./gmp-6.2.0 --library ./gmp-6.2.0/.libs/libgmp.a \
		--name rpt

rpt_release: *.zig
	zig build-exe --release-small --single-threaded --strip -mcpu x86_64 rpt.zig \
		-lc -lm \
		-I./Prime95-29.8b6/gwnum/ --library ./Prime95-29.8b6/gwnum/gwnum.a \
		-I./gmp-6.2.0 --library ./gmp-6.2.0/.libs/libgmp.a \
		--name rpt_release_linux64
	PATH=/home/tanel/software/upx-3.96-amd64_linux/:$PATH \
	upx -9 ./rpt_release_linux64

v:
	#v -cg -prod -cc gcc-9 -cflags -fauto-profile=altllr.gcov altllr.v
	cp Prime95-29.8b6/gwnum/gwnum.a Prime95-29.8b6/gwnum/libgwnum.a
	v -cg -prod -cc gcc-9 -- experiments/alt_llr.v
	#v -cg -prod -cc gcc-9 -cflags -fdata-sections -ffunction-sections -Wl,--gc-sections -fwhole-program -O3 -funroll-loops -march=native altllr.v
