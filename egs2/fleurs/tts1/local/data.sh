#!/usr/bin/env bash

set -e
set -u
set -o pipefail

log() {
    local fname=${BASH_SOURCE[1]##*/}
    echo -e "$(date '+%Y-%m-%dT%H:%M:%S') (${fname}:${BASH_LINENO[0]}:${FUNCNAME[1]}) $*"
}
SECONDS=0

stage=-1
stop_stage=1

# Options for silence trimming
fs=16000
do_trimming=true
nj=32
# Options for dataset filtering
lang_filt=true
lang_filt_top=10
mos_filt=true
mos_filt_thresh=3.5

log "$0 $*"
. utils/parse_options.sh

if [ $# -ne 0 ]; then
    log "Error: No positional arguments are required."
    exit 2
fi

. ./path.sh || exit 1;
. ./cmd.sh || exit 1;
. ./db.sh || exit 1;

if [ -z "${FLEURS}" ]; then
   log "Fill the value of 'LIBRITTS' of db.sh"
   exit 1
fi
db_root=${FLEURS}

if [ ${stage} -le -1 ] && [ ${stop_stage} -ge -1 ]; then
    log "stage -1: We assume the dataset has already been downloaded."
fi

if [ ${stage} -le 0 ] && [ ${stop_stage} -ge 0 ]; then
    log "stage 0: local/data_prep.sh"
    for setname in test dev train; do
        local/data_prep.sh \
            "${db_root}" \
            "data/${setname}" \
            "${lang_filt}" \
            "${lang_filt_top}" \
            "${mos_filt}" \
            "${mos_filt_thresh}"
    done
fi

if [ ${stage} -le 1 ] && [ ${stop_stage} -ge 1 ] && [ "${do_trimming}" = true ]; then
    log "stage 1: scripts/audio/trim_silence.sh"
    for setname in test dev train; do
        scripts/audio/trim_silence.sh \
            --cmd "${train_cmd}" \
            --nj "${nj}" \
            --fs "${fs}" \
            --win_length 1024 \
            --shift_length 256 \
            --threshold 60 \
            --min_silence 0.01 \
            "data/${setname}" "data/${setname}/log"
    done
fi

log "Successfully finished. [elapsed=${SECONDS}s]"
