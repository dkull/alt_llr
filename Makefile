.PHONY = zig v 
.SILENT:

zig:
	#gcc -I./Prime95/gwnum/ -l:./Prime95/gwnum/gwnum.a libgwhelper.c -c -o libgwhelper.o 
	#gcc -I./Prime95/gwnum/ -l:./Prime95/gwnum/gwnum.a -c -o libgwhelper.o 
	ar rcs libgwhelper.a libgwhelper.o

	zig build-exe alt_llr.zig \
		-lc -lm \
		-I. -L. \
		-I./Prime95/gwnum/ -l:./Prime95/gwnum/gwnum.a
		#-I. -L. -ldemo -lgwhelper \


v:
	#v -cg -prod altllr.v
	v -cg -prod -cc gcc -cflags -flto -O3 -march=skylake altllr.v
