#!/bin/bash

# Copyright (C) 2019 Intel Corporation.  All rights reserved.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

PLATFORM=$(uname -s | tr A-Z a-z)

IWASM="../../../product-mini/platforms/${PLATFORM}/build/iwasm"
WAMRC="../../../wamr-compiler/build/wamrc"

echo "Run coremark with native .."
./coremark.exe

echo "Run coremark with iwasm aot mode .."
${IWASM} coremark.aot

if [[ ${PLATFORM} == "linux" ]]; then
    echo "Run coremark with iwasm aot-segue mode .."
    ${IWASM} coremark_segue.aot

    echo "Run coremark with iwasm aot-segue store mode .."
    ${IWASM} coremark_segue_store.aot

    echo "Run coremark with iwasm aot-segue load mode .."
    ${IWASM} coremark_segue_load.aot
fi

# echo "Run coremark with iwasm interpreter mode .."
# ${IWASM} coremark.wasm
