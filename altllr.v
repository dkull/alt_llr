import os

#flag -lc
#flag -lm
#flag -I.
#flag -L.
#flag -I./Prime95/gwnum/
#flag -l:./Prime95/gwnum/gwnum.a
#include <gwnum.h>

struct C.gwhandle
struct C.gwinit
struct C.gwnum

fn C.gw_as_string(out byteptr, k u64, b u64, n u64, c i64)
fn C.gwinit(handle C.gwhandle)
fn C.gwsetup(handle C.gwhandle, k f64, b u64, n u64, c i64) int
fn C.gw_random_number(handle C.gwhandle, x gwnum)
fn C.gwfft_description(handle C.gwhandle, out byteptr)
fn C.dbltogw(hadnle C.gwhandle, n f64, out gwnum)
fn C.gwalloc(handle C.gwhandle) gwnum
fn C.gwfree(handle C.gwhandle, num gwnum)
fn C.gwsquare(handle C.gwhandle, num gwnum)
fn C.gwsub(handle C.gwhandle, num1 gwnum, num2 gwnum)
fn C.gwiszero(handle C.gwhandle, num gwnum) i64
fn C.binarytogw(handle C.gwhandle, array &u32, arraylen u32, gwnum u32)
fn C.gwtobinary(handle C.gwhandle, num gwnum, array byteptr, len u32) u32

/*fn p_generic(m gwnum, x gwnum) gwnum {
    
}

fn calc_s0(ctx &C.gwhandle, k int, b int) gwnum {
    // p_generic(b * k // 2, p_generic(b // 2, 4))

    bk_div_2 := C.gwalloc(&ctx)
    b_div_2 := C.gwalloc(&ctx)
    four := C.gwalloc(&ctx)

    C.dbltogw(&ctx, b * k / 2, &bk_div_2)
    C.dbltogw(&ctx, b / 2, &b_div_2)
    C.dbltogw(&ctx, 4, &four)

    inner := p_generic(b_div_2, four)
    outer := p_generic(bk_div_2, inner)

    C.gwfree(&ctx, bk_div_2)
    C.gwfree(&ctx, b_div_2)
    C.gwfree(&ctx, four)

    return outer
}*/
/*fn calc_s0(ctx &C.gwhandle, k int, b int) gwnum {
    foo := C.gwalloc(ctx)
    C.dbltogw(ctx, f64(4), foo)
    return foo
}*/

fn repr_gwnum(ctx &C.gwhandle, num gwnum) string {
    outints := 1024
    mut data := byteptr(0)
    unsafe { data = malloc(4 * outints) }

    mut outbuffer := ""

    num_written := C.gwtobinary(ctx, num, data, outints)
    read_bytes := int(num_written * 4)

    for i, _ in [0].repeat(read_bytes) {
        mut result := int(data[i]).hex()
        result = result[2..]
        if result.len == 1 {
            outbuffer += "0"
        }
        outbuffer += result
        outbuffer += " "
    }
    return outbuffer
}

fn test(ctx &C.gwhandle) {
    num_truth := C.gwalloc(ctx)
    // 2 ** 42 + 1
    // 00000000 00000000 00000100 00000000 00000000 0000000 00000000 000000001
    C.dbltogw(ctx, f64(4398046511105), num_truth)
    println("ground truth: " + repr_gwnum(ctx, num_truth))

    mut nums := byteptr(0)
    // 2 uints
    unsafe { nums = malloc(2 * 4) }
    // clear memory
    for i, _ in [0].repeat(2 * 4) {
        nums[i] = 0
    }
    nums[0] = 1
    nums[5] = 4

    num := C.gwalloc(ctx)
    C.binarytogw(ctx, nums, 2, num)
    println("loaded:       " + repr_gwnum(ctx, num))

    C.gwsub(ctx, num_truth, num)
    if C.gwiszero(ctx, num) == 1 {
        println("ordering correct")
    } else {
        println("ordering incorrect")
    }
}

fn load_s0_from_file(ctx &C.gwhandle, k int) gwnum {
    // TODO check that first 4 bytes are the 'k'
    header := 0
    file_path := k.str() + ".s0"

    contents := os.read_bytes(file_path) or {
        panic(err)
    }

    mut container := byteptr(0)
    unsafe { container = malloc(contents.len - header) }
    // set bytes to null
    for i, b in [0].repeat(contents.len - header) {
        container[i] = b
    }

    for i, b in contents[header..] {
        container[i] = int(b)
    }

    num := C.gwalloc(ctx)
    C.binarytogw(ctx, container, contents.len / 4, num)

    return num
}

fn main() {
    k := 971081
    b := 2
    n := 223282
    c := -1

    ctx := &C.gwhandle(0)
    C.gwinit(&ctx)
    C.gwsetup(&ctx, k, b, n, c)

    test(&ctx)

    gwnum_2 := C.gwalloc(&ctx)
    C.dbltogw(&ctx, f64(2.0), gwnum_2)
    //mut s := calc_s0(&ctx, k, b)
    mut s := load_s0_from_file(&ctx, k)
    mut i := 1
    for {
        // until n-1
        if i == n - 1{
            break
        }
        C.gwsquare(&ctx, s)
        C.gwsub(&ctx, gwnum_2, s)
        i++
    }
    if C.gwiszero(&ctx, s) == 1 {
        println("PRIME")
    } else {
        println("NOT PRIME")
    }
    println("> REACHED END")
}
