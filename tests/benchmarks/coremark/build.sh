#!/bin/bash

# Copyright (C) 2019 Intel Corporation.  All rights reserved.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

if [ -e "./build_complete.txt" ]; then
    exit 0
fi

PLATFORM=$(uname -s | tr A-Z a-z)

WAMRC="../../../wamr-compiler/build/wamrc"

if [ ! -d coremark ]; then
    git clone https://github.com/eembc/coremark.git
fi

cd coremark

echo "Build coremark with gcc .."
gcc -O3 -Iposix -I. -DFLAGS_STR=\""-O3 -DPERFORMANCE_RUN=1  -lrt"\" \
        -DITERATIONS=400000 -DSEED_METHOD=SEED_VOLATILE -DPERFORMANCE_RUN=1 \
        core_list_join.c core_main.c core_matrix.c core_state.c \
        core_util.c posix/core_portme.c \
        -o ../coremark.exe -lrt

echo "Build coremark with wasi-sdk .."
/opt/wasi-sdk/bin/clang -O3 -Iposix -I. -DFLAGS_STR=\""-O3 -DPERFORMANCE_RUN=1"\" \
        -Wl,--export=main \
        -DITERATIONS=400000 -DSEED_METHOD=SEED_VOLATILE -DPERFORMANCE_RUN=1 \
        -Wl,--allow-undefined \
        core_list_join.c core_main.c core_matrix.c core_state.c \
        core_util.c posix/core_portme.c \
        -o ../coremark.wasm

cd ..

echo "Compile coremark.wasm to coremark.aot .."
${WAMRC} -o coremark.aot coremark.wasm

if [[ ${PLATFORM} == "linux" ]]; then
    echo "Compile coremark.wasm to coremark_segue.aot .."
    ${WAMRC} --enable-segue -o coremark_segue.aot coremark.wasm

    echo "Compile coremark.wasm to coremark_segue_store.aot .."
    ${WAMRC} --enable-segue=i32.store -o coremark_segue_store.aot coremark.wasm

    echo "Compile coremark.wasm to coremark_segue_load.aot .."
    ${WAMRC} --enable-segue=i32.load -o coremark_segue_load.aot coremark.wasm
fi

touch "./build_complete.txt"
echo "Done"
