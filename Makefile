.PHONY = zig v 
.SILENT:

zig:
	#gcc -I./Prime95/gwnum/ -l:./Prime95/gwnum/gwnum.a libgwhelper.c -c -o libgwhelper.o 
	#gcc -I./Prime95/gwnum/ -l:./Prime95/gwnum/gwnum.a -c -o libgwhelper.o 
	#ar rcs libgwhelper.a libgwhelper.o
	cp Prime95/gwnum/gwnum.a ./libgwnum.a

	#--object libgwnum.a
	zig build-exe --release-fast --single-threaded --strip -mcpu native alt_llr.zig \
		-lc -lm \
		-I./Prime95/gwnum/ --library ./Prime95/gwnum/gwnum.a \
		-I./home/tanel/software/gmp-6.2.0 --library /home/tanel/software/gmp-6.2.0/.libs/libgmp.a \
		--name alt_llr_zig 

zig2:
	cp Prime95/gwnum/gwnum.a ./libgwnum.a
	zig build

v:
	#v -cg -prod -cc gcc-9 -cflags -fauto-profile=altllr.gcov altllr.v
	v -cg -prod -cc gcc-9 -o alt_llr_v alt_llr.v
	#v -cg -prod -cc gcc-9 -cflags -fdata-sections -ffunction-sections -Wl,--gc-sections -fwhole-program -O3 -funroll-loops -march=native altllr.v
