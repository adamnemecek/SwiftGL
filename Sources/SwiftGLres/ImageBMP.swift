// Copyright (c) 2015-2016 David Turnbull
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and/or associated documentation files (the
// "Materials"), to deal in the Materials without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Materials, and to
// permit persons to whom the Materials are furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Materials.
//
// THE MATERIALS ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// MATERIALS OR THE USE OR OTHER DEALINGS IN THE MATERIALS.


// Microsoft BMP format.
// First implemented thanks to logic from Sean Barrett et al.
// https://github.com/nothings/stb


final public class SGLImageDecoderBMP : SGLImageDecoder {

    override public class func test(l: SGLImageLoader) -> Bool
    {
        if read16be(l) != chars("BM") {
            return false
        }
        read32le(l) // discard filesize
        read16le(l) // discard reserved
        read16le(l) // discard reserved
        read32le(l) // discard data offset
        let s = read32le(l)
        return s == 12 || s == 40 || s == 56 || s == 108 || s == 124
    }

    override public func info()
    {
        parseHeader()
        channels = (ma == 0) ? 3 : 4
    }

    override public func load<T:SGLImageType>(img:T)
    {
        if (bpp <= 8) {
            loadPalletized(img)
        } else {
            loadDiscrete(img)
        }

        if (aZero == 0) {
            // buggy file where alpha is fully transparent
            fill(img, alpha: cast(UInt16(0xffff)))
        }
    }


    public func fill<T:SGLImageType>(img:T, alpha a:T.Element) {
        if img.channels == 1 || img.channels == 3 {
            return // no alpha
        }
        img.withUnsafeMutableBufferPointer { (ptr) in
            var p = img.channels - 1
            for _ in 0 ..< img.width {
                for _ in 0 ..< img.width {
                    ptr[p] = a; p += channels
                }
            }

        }
    }


    // if aZero is 0 at end, then we loaded alpha channel but it was all 0
    var aZero:UInt16 = 0 &- 1
    // channel masks
    var mr = 0, mg = 0, mb = 0, ma = 0
    // important header values
    var offset = 0, hsize = 0, bpp = 0
    // negative ysize is normal 0,0==topLeft
    var flipVerticalBMP = true

    func parseHeader()
    {
        if read16be() != chars("BM") {
            error = "bad BMP"
            return
        }

        read32le() // discard filesize
        read16le() // discard reserved
        read16le() // discard reserved

        offset = read32le()
        hsize = read32le()

        if hsize != 12 && hsize != 40 && hsize != 56 && hsize != 108 && hsize != 124 {
            error = "BMP type not supported: \(hsize)"
            return
        }

        if hsize == 12 {
           xsize = read16le()
           ysize = read16le()
        } else {
           xsize = read32le()
           ysize = read32le()
        }

        if ysize < 0 {
            ysize = -ysize
            flipVerticalBMP = false
        }

        if (read16le() != 1) {
            error = "bad BMP"
            return
        }

        bpp = read16le()

        if bpp == 1 {
            error = "BMP type not supported: 1-bit monochrome"
            return
        }

        if (hsize == 12) {
            return // success
        }

        let compress = read32le()
        if compress == 1 || compress == 2 {
            error = "BMP type not supported: RLE"
            return
        }

        read32le() // discard sizeof
        read32le() // discard hres
        read32le() // discard vres
        read32le() // discard colorsused
        read32le() // discard max important

        if hsize == 40 || hsize == 56 {
            if (hsize == 56) {
                read32le()
                read32le()
                read32le()
                read32le()
            }
            if bpp == 16 || bpp == 32 {
                if (compress == 0) {
                    if (bpp == 32) {
                        mr = 0xff << 16
                        mg = 0xff <<  8
                        mb = 0xff <<  0
                        ma = 0xff << 24
                        aZero = 0
                    } else {
                        mr = 0x1f << 10
                        mg = 0x1f <<  5
                        mb = 0x1f <<  0
                    }
                } else if (compress == 3) {
                    mr = read32le()
                    mg = read32le()
                    mb = read32le()
                    // not documented, but generated by photoshop and handled by mspaint
                    if mr == mg && mg == mb {
                        // greyscale??
                        error = "bad BMP"
                        return
                    }
                } else {
                    error = "bad BMP"
                    return
                }
            }
            return // success
        }

        if hsize == 108 || hsize == 124 {
            mr = read32le()
            mg = read32le()
            mb = read32le()
            ma = read32le()
            read32le() // discard color space
            for _ in 0 ..< 12 {
                read32le() // discard color space parameters
            }
            if (hsize == 124) {
                read32le() // discard rendering intent
                read32le() // discard offset of profile data
                read32le() // discard size of profile data
                read32le() // discard reserved
            }
            return // success
        }

        // should never get here
        fatalError()
    }


    func loadPalletized<T:SGLImageType>(img:T)
    {
        let psize:Int
        if hsize == 12 {
            psize = (offset - 14 - 24) / 3
        } else {
            psize = (offset - 14 - hsize) >> 2
        }

        if (psize < 1 || psize > 256) {
            error = "bad BMP"
            return
        }

        var pal:Array<(r:T.Element,g:T.Element,b:T.Element,a:T.Element)> = Array<(r:T.Element,g:T.Element,b:T.Element,a:T.Element)>(
            count: psize, repeatedValue: (cast(UInt8(0)),cast(UInt8(0)),cast(UInt8(0)),castAlpha(UInt8(255)))
        )

        for i in 0 ..< psize {
            let b:T.Element = cast(UInt8(read8()))
            let g:T.Element = cast(UInt8(read8()))
            let r:T.Element = cast(UInt8(read8()))
            pal[i] = (r,g,b,castAlpha(UInt8(255)))
            if hsize != 12 {
                read8()
            }
        }

        skip(offset - 14 - hsize - psize * (hsize == 12 ? 3 : 4))

        let pad:Int
        if bpp == 4 {
            pad = ((-xsize - 1) >> 1) & 3
        } else if bpp == 8 {
            pad = (-xsize) & 3
        } else {
            error = "bad BMP"
            return
        }

        for j in 0 ..< ysize {
            let row = flipVerticalBMP ? ysize-j-1 : j
            if bpp == 8 {
                // 256 colors
                fill(img, row:row) { () -> (T.Element,T.Element,T.Element,T.Element) in
                    pal[read8()]
                }
            } else {
                // 16 colors
                var i = 0
                var even = true
                fill(img, row:row) { () -> (T.Element,T.Element,T.Element,T.Element) in
                    if even {
                        even = false
                        i = read8()
                        return pal[i & 0x0f]
                    } else {
                        even = true
                        i >>= 4
                        return pal[i]
                    }
                }
            }
            skip(pad)
        }
    }


    func loadDiscrete<T:SGLImageType>(img:T)
    {
        skip(offset - 14 - hsize)

        let pad:Int
        if (bpp == 24) {
            pad = (-3 * xsize) & 3
        } else if (bpp == 16) {
            pad = (-2 * xsize) & 3
        } else {
            pad = 0
        }

        var simple = false
        if (bpp == 24) {
            simple = true
        } else if (bpp == 32 && mb == 0xff && mg == 0xff00 &&
            mr == 0xff0000 && ma == 0xff000000) {
                simple = true
        }

        if simple {
            // simple 8 bit per channel with common ordering
            // slightly faster by avoiding bitwise operations
            let hasAlpha = bpp == 32
            for j in 0 ..< ysize {
                let row = flipVerticalBMP ? ysize-j-1 : j
                fill(img, row:row) { () -> (T.Element,T.Element,T.Element,T.Element) in
                    let b = readUInt8()
                    let g = readUInt8()
                    let r = readUInt8()
                    let a =  hasAlpha ? readUInt8() : UInt8(0xFF)
                    aZero |= UInt16(a)
                    return (cast(r), cast(g), cast(b), castAlpha(a))
                }
                skip(pad)
            }
            return // success
        }

        // Explicitly bit masked, could be 16 bpp or unusual ordering of 32bpp
        let sr = shiftCount(mr)
        let sg = shiftCount(mg)
        let sb = shiftCount(mb)
        let sa = shiftCount(ma)
        let hasAlpha = ma != 0

        for j in 0 ..< ysize {
            let row = flipVerticalBMP ? ysize-j-1 : j
            fill(img, row:row) { () -> (T.Element,T.Element,T.Element,T.Element) in
                let v = (bpp == 16) ? read16le() : read32le()
                let r = mask(v, mr, sr)
                let g = mask(v, mg, sg)
                let b = mask(v, mb, sb)
                let a = hasAlpha ? self.mask(v, ma, sa) : UInt16(0xFFFF)
                aZero |= a
                return (cast(r), cast(g), cast(b), castAlpha(a))
            }
            skip(pad)
        }
    }


    // For bit masking, finds the highest bit and the numbers of bits.
    func shiftCount(m:Int) -> (sh:Int,ct:UInt16)
    {
        // 64 ensures mask doesn't infinite loop
        if (m == 0) { return (0, 64) }

        var n = 0 // high bit -1...31
        var z = UInt(bitPattern: m)
        if (z >= 0x10000) { n += 16; z >>= 16 }
        if (z >= 0x00100) { n +=  8; z >>=  8 }
        if (z >= 0x00010) { n +=  4; z >>=  4 }
        if (z >= 0x00004) { n +=  2; z >>=  2 }
        if (z >= 0x00002) { n +=  1; z >>=  1 }

        // Since 1 bits are exected to be contiguous, we can count
        // bits by measuring distance between first and last 1 bit.
        // Faster and easier than fancy "count bits" algorithm.
        var a = UInt(m << (31 - n))
        var c = UInt16(0)
        while (a != 0) {
            c += 1
            a <<= 1
        }

        return (Int(n - 15), c)
    }


    // Uses the shiftCount tuple to construct a 16 bit value that's
    // properly interpolated to be exactly 0...65535. Even though
    // BMPs are only 8 bits per channel, we build the 16 bit
    // version to avoid upscaling with a rounding error.
    //   11110 -> 11110111 -> 1111011111110111 -> 11110111
    //   11110       ->       1111011110111101 -> 11110111
    func mask(v:Int, _ mask:Int, _ shiftCount:(sh:Int,ct:UInt16)) -> UInt16
    {
        let i = UInt16((shiftCount.sh < 0) ?
            (v & mask) << -shiftCount.sh :
            (v & mask) >> shiftCount.sh)
        var result = i
        var z = shiftCount.ct
        while (z < 16) {
            result |= i >> z
            z += shiftCount.ct
        }
        return result
    }

}
