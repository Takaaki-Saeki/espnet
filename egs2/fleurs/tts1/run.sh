#!/usr/bin/env bash
# Set bash to 'debug' mode, it will exit on :
# -e 'error', -u 'undefined variable', -o ... 'error in pipeline', -x 'print commands',
set -e
set -u
set -o pipefail

fs=16000
n_fft=1024
n_shift=256
lang_filt=false
mos_filt=true
mos_filt_thresh=3.5

local_data_opts+=" --fs ${fs} --lang_filt ${lang_filt} --mos_filt ${mos_filt} --mos_filt_thresh ${mos_filt_thresh}"

opts=
if [ "${fs}" -eq 22050 ]; then
    # To suppress recreation, specify wav format
    opts="--audio_format wav "
else
    opts="--audio_format flac "
fi

# Data prep related
token_type=byte
# Training the model only on the en_us single-speaker data
lang=noinfo
cleaner=none
g2p=byte
use_lid=true

train_config=conf/train.yaml
inference_config=conf/decode.yaml

train_set=train
valid_set=dev
test_sets=test

./tts.sh \
    --lang ${lang} \
    --local_data_opts "${local_data_opts}" \
    --feats_type raw \
    --use_lid ${use_lid} \
    --fs "${fs}" \
    --n_fft "${n_fft}" \
    --n_shift "${n_shift}" \
    --use_xvector true \
    --xvector_tool rawnet \
    --token_type "${token_type}" \
    --cleaner "${cleaner}" \
    --g2p "${g2p}" \
    --train_config "${train_config}" \
    --inference_config "${inference_config}" \
    --inference_model valid.loss.best.pth \
    --min_wav_duration 0.1 \
    --max_wav_duration 15 \
    --train_set "${train_set}" \
    --valid_set "${valid_set}" \
    --test_sets "${test_sets}" \
    --srctexts "data/${train_set}/text" \
    ${opts} "$@"
