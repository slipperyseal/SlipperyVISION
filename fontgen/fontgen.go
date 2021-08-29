package main

import (
    "fmt"
    "image/png"
    "os"
)

// this is a quick little go program used to convert the PETSCII font to source needed for this project.
// there's no need to run this unless you are changing the font in some way, as the project contains the
// generated source. but if you do, this is how it's run...
//
//    go run fontgen.go c64combined.png >../font.s

// maps ASCII to the PETSCII positions
var mapping =
    "@abcdefghijklmno" +
    "pqrstuvwxyz[_]__" +
    " !\"#$%&'()*+,-./" +
    "0123456789:;<=>?" +
    "-ABCDEFGHIJKLMNO" +
    "PQRSTUVWXYZ[.].." +
    "                " +
    "                " +
    "                " +
    "                " +
    "                " +
    "                " +
    "                " +
    "                " +
    "                " +
    "                "

func main() {
    infile, err := os.Open(os.Args[1])
    if err != nil {
        panic(err)
    }
    defer infile.Close()

    src, err := png.Decode(infile)
    if err != nil {
        panic(err)
    }

    bounds := src.Bounds()
    w, h := bounds.Max.X/8, bounds.Max.Y/8

    fmt.Println()
    fmt.Println("    .section .text")
    fmt.Println()

    for line := 0; line < 8; line++ {
        if line == 0 {
            fmt.Println("    .balign 512")
            fmt.Println("    .global fontdata");
            fmt.Println("fontdata:");
        }
        fmt.Printf("    ; %s line %d\n", os.Args[1], line)
        i := uint8(0)
        for row := 0; row < h; row++ {
            for col := 0; col < w; col++ {
                if col == 0 {
                    fmt.Print("    .ascii \"")
                }
                mcol, mrow := locate(i, col, row)
                i++
                b := 0
                for z := 0; z < 8; z++ {
                    r, _, _, _ := src.At((mcol*8)+z, (mrow*8)+line).RGBA()
                    if r > 100*256 {
                        b |= 1 << z
                    }
                }
                fmt.Printf("\\%03o", b)
            }
            fmt.Println("\"")
        }
        fmt.Println()
    }
    fmt.Println()
    fmt.Println("    .end")
    fmt.Println()
}

func locate(c uint8, col, row int) (x,y int) {
    // spaces are "pass through"
    if mapping[c] == ' ' {
        return col, row
    }
    for x := 0; x < 16*16; x++ {
        if mapping[x] == c {
            row := x/16
            return x-(row*16), row
        }
    }
    return 0, 2
}
