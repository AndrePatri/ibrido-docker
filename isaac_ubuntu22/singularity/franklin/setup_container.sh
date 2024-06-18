#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source $SCRIPT_DIR/setup_cfg.sh 

$SCRIPT_DIR/../build_singularity_isaac.sh --init --do_setup