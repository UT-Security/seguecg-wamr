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

REP_ROOT_PATH=$(realpath ../../../../)
SEGUECG_WASM2C_RUNTIME_PATH=$REP_ROOT_PATH/seguecg-wasm2c
SEGUECG_WASM2C_RUNTIME_SRC_PATH=$SEGUECG_WASM2C_RUNTIME_PATH/wasm2c
SEGUECG_WASM2C_BIN_PATH=$SEGUECG_WASM2C_RUNTIME_PATH/build_release
SEGUECG_UVWASI_PATH=$SEGUECG_WASM2C_RUNTIME_PATH/third_party/uvwasi

echo "Compiler coremark_wasm2c .."

# $REP_ROOT_PATH/seguecg-wasm2c/build_release/wasm2c coremark.wasm -o ./coremark.wasm.c

clang -O3 -DWASM_RT_MEMCHECK_GUARD_PAGES=1 -o ./coremark_wasm2c ./coremark.wasm.c \
    $SEGUECG_WASM2C_RUNTIME_PATH/wasm2c/wasm-rt-impl.c $SEGUECG_WASM2C_RUNTIME_PATH/wasm2c/uvwasi-rt.c $SEGUECG_WASM2C_RUNTIME_PATH/wasm2c/wasm-rt-runner-static.c \
    -I$SEGUECG_WASM2C_RUNTIME_SRC_PATH -I$SEGUECG_UVWASI_PATH/include -L$SEGUECG_WASM2C_BIN_PATH/_deps/libuv-build -L$SEGUECG_WASM2C_BIN_PATH/third_party/uvwasi -luvwasi_a -luv_a -lpthread -lm \
    -DWASM_MODULE_NAME=coremark -include ./coremark.wasm.h

echo "Compiler coremark_wasm2c_segue .."

clang -O3 -DWASM_RT_MEMCHECK_GUARD_PAGES=1 -DWASM_RT_USE_SEGUE=1 -mfsgsbase -o ./coremark_wasm2c_segue ./coremark.wasm.c \
    $SEGUECG_WASM2C_RUNTIME_PATH/wasm2c/wasm-rt-impl.c $SEGUECG_WASM2C_RUNTIME_PATH/wasm2c/uvwasi-rt.c $SEGUECG_WASM2C_RUNTIME_PATH/wasm2c/wasm-rt-runner-static.c \
    -I$SEGUECG_WASM2C_RUNTIME_SRC_PATH -I$SEGUECG_UVWASI_PATH/include -L$SEGUECG_WASM2C_BIN_PATH/_deps/libuv-build -L$SEGUECG_WASM2C_BIN_PATH/third_party/uvwasi -luvwasi_a -luv_a -lpthread -lm \
    -DWASM_MODULE_NAME=coremark -include ./coremark.wasm.h

echo "Compiler coremark_wasm2c_segue store .."

clang -O3 -DWASM_RT_MEMCHECK_GUARD_PAGES=1 -DWASM_RT_USE_SEGUE_STORE=1 -mfsgsbase -o ./coremark_wasm2c_segue_store ./coremark.wasm.c \
    $SEGUECG_WASM2C_RUNTIME_PATH/wasm2c/wasm-rt-impl.c $SEGUECG_WASM2C_RUNTIME_PATH/wasm2c/uvwasi-rt.c $SEGUECG_WASM2C_RUNTIME_PATH/wasm2c/wasm-rt-runner-static.c \
    -I$SEGUECG_WASM2C_RUNTIME_SRC_PATH -I$SEGUECG_UVWASI_PATH/include -L$SEGUECG_WASM2C_BIN_PATH/_deps/libuv-build -L$SEGUECG_WASM2C_BIN_PATH/third_party/uvwasi -luvwasi_a -luv_a -lpthread -lm \
    -DWASM_MODULE_NAME=coremark -include ./coremark.wasm.h

echo "Compiler coremark_wasm2c_segue load .."

clang -O3 -DWASM_RT_MEMCHECK_GUARD_PAGES=1 -DWASM_RT_USE_SEGUE_LOAD=1 -mfsgsbase -o ./coremark_wasm2c_segue_load ./coremark.wasm.c \
    $SEGUECG_WASM2C_RUNTIME_PATH/wasm2c/wasm-rt-impl.c $SEGUECG_WASM2C_RUNTIME_PATH/wasm2c/uvwasi-rt.c $SEGUECG_WASM2C_RUNTIME_PATH/wasm2c/wasm-rt-runner-static.c \
    -I$SEGUECG_WASM2C_RUNTIME_SRC_PATH -I$SEGUECG_UVWASI_PATH/include -L$SEGUECG_WASM2C_BIN_PATH/_deps/libuv-build -L$SEGUECG_WASM2C_BIN_PATH/third_party/uvwasi -luvwasi_a -luv_a -lpthread -lm \
    -DWASM_MODULE_NAME=coremark -include ./coremark.wasm.h

touch "./build_complete.txt"
echo "Done"
