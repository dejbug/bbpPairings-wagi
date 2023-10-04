# bbpPairings-wagi

[bbpPairings](https://github.com/BieremaBoyzProgramming/bbpPairings) is one of the few [FIDE-endorsed](https://handbook.fide.com/chapter/C04A) pairing engines for [Swiss](https://en.wikipedia.org/wiki/Swiss-system_tournament) tournaments. (It reads **TRF** text and and prints a list of pairings.) Here I will be **porting** it to **WebAssembly** so as to make it more readily available (e.g. as a [WAGI](https://github.com/deislabs/wagi) microservice of the cloud).

## TRF

This is FIDE's [Tournament Report File Format](https://handbook.fide.com/chapter/C04A). See the [JaVaFo2 Advanced User Manual](http://www.rrweb.org/javafo/aum/JaVaFo2_AUM.htm) for detailed info on the format and **its extensions**.

There is a convenient [Lichess API endpoint](https://lichess.org/api#tag/Swiss-tournaments/operation/swissTrf) from which to get some **sample TRF**. Try `curl https://lichess.org/swiss/j8rtJ5GL.trf`.

## Modifications

Preliminary experiments determined that in order to get it to compile, two modifications are necessary (and happily sufficient):

   1. All **filesystem** handling has to be removed (and replaced with simple piping from/to stdin/stdout).

   2. All **exception** handling has to be removed (and replaced with HTTP errors).

Ideally, all modifications would have been hidden behind a preprocessor flag but the inclusion of exception semantics makes this difficult.

## Compiling & Running

Use the [WASI-SDK](https://github.com/WebAssembly/wasi-sdk/releases) for building. Invoke it as:

```sh
$ /path/to/wasi-sdk-20.0/bin/clang++ \
   --sysroot /path/to/wasi-sdk-20.0/share/wasi-sysroot/
```

Use e.g. [Wasmtime](https://github.com/bytecodealliance/wasmtime-cpp) for running it. Invoke it as e.g.:

```sh
$ cat sample.trf | wasmtime run bbpPairings.wasm
```

## Deployment

A working PoC is to **go live** with [Fermyon](https://www.fermyon.com/cloud).
