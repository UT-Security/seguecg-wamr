#!/bin/bash

# Copyright (C) 2019 Intel Corporation.  All rights reserved.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

CUR_DIR=$PWD
OUT_DIR=$CUR_DIR/out
REPORT=$CUR_DIR/report.txt
TIME=/usr/bin/time

PLATFORM=$(uname -s | tr A-Z a-z)
IWASM_CMD=$CUR_DIR/../../../product-mini/platforms/${PLATFORM}/build/iwasm

BENCH_NAME_MAX_LEN=20

SHOOTOUT_CASES="base64 fib2 gimli heapsort matrix memmove nestedloop \
                nestedloop2 nestedloop3 random seqhash sieve strchr \
                switch2"

rm -f $REPORT
touch $REPORT

function print_bench_name()
{
    name=$1
    echo -en "$name" >> $REPORT
}

echo "Start to run cases, the result is written to report.txt"

#run benchmarks
cd $OUT_DIR
if [[ ${PLATFORM} == "linux" ]]; then
    echo -en "\tnative\tiwasm-aot\tiwasm-aot-segue\tiwasm-aot-segue-store\tiwasm-aot-segue-load\n" >> $REPORT
else
    echo -en "\tnative\tiwasm-aot\n" >> $REPORT
fi

for t in $SHOOTOUT_CASES
do
    print_bench_name $t

    echo "run $t with native .."
    echo -en "\t" >> $REPORT
    hyperfine -N --warmup 5 -m 10 --export-json ./hyperfine.out -i "./${t}_native"
    cat ./hyperfine.out | jq '.results[0].median' | awk 'NR>1{print PREV} {PREV=$0} END{printf("%s",$0)}' >> $REPORT

    echo "run $t with iwasm aot .."
    echo -en "\t" >> $REPORT
    hyperfine -N --warmup 5 -m 10 --export-json ./hyperfine.out "$IWASM_CMD ${t}.aot"
    cat ./hyperfine.out | jq '.results[0].median' | awk 'NR>1{print PREV} {PREV=$0} END{printf("%s",$0)}' >> $REPORT

    if [[ ${PLATFORM} == "linux" ]]; then
        echo "run $t with iwasm aot segue .."
        echo -en "\t" >> $REPORT
        hyperfine -N --warmup 5 -m 10 --export-json ./hyperfine.out "$IWASM_CMD ${t}_segue.aot"
        cat ./hyperfine.out | jq '.results[0].median' | awk 'NR>1{print PREV} {PREV=$0} END{printf("%s",$0)}' >> $REPORT

        echo "run $t with iwasm aot segue store .."
        echo -en "\t" >> $REPORT
        hyperfine -N --warmup 5 -m 10 --export-json ./hyperfine.out "$IWASM_CMD ${t}_segue_store.aot"
        cat ./hyperfine.out | jq '.results[0].median' | awk 'NR>1{print PREV} {PREV=$0} END{printf("%s",$0)}' >> $REPORT

        echo "run $t with iwasm aot segue load .."
        echo -en "\t" >> $REPORT
        hyperfine -N --warmup 5 -m 10 --export-json ./hyperfine.out "$IWASM_CMD ${t}_segue_load.aot"
        cat ./hyperfine.out | jq '.results[0].median' | awk 'NR>1{print PREV} {PREV=$0} END{printf("%s",$0)}' >> $REPORT
    fi

    echo -en "\n" >> $REPORT
done
