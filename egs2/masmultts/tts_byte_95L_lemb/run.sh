#!/usr/bin/env bash
# Set bash to 'debug' mode, it will exit on :
# -e 'error', -u 'undefined variable', -o ... 'error in pipeline', -x 'print commands',
set -e
set -u
set -o pipefail

fs=16000
n_fft=1024
n_shift=256

################# Configs to be set #####################
token_type=byte
use_mailabs=true
use_css10=true
use_fleurs=true
use_lid=false
mos_filtering=true
lang_set="lang_set.txt"
do_trimming=false
lang_family=false
#########################################################

local_data_opts=""
local_data_opts+=" --token_type ${token_type}"
local_data_opts+=" --use_mailabs ${use_mailabs}"
local_data_opts+=" --use_css10 ${use_css10}"
local_data_opts+=" --use_fleurs ${use_fleurs}"
local_data_opts+=" --mos_filtering ${mos_filtering}"
local_data_opts+=" --lang_set ${lang_set}"
local_data_opts+=" --lang_family ${lang_family}"
local_data_opts+=" --do_trimming ${do_trimming}"

opts=
if [ "${fs}" -eq 22050 ]; then
    # To suppress recreation, specify wav format
    opts="--audio_format wav "
else
    opts="--audio_format flac "
fi

lang=noinfo
cleaner=none
if [ ${token_type} = "byte" ]; then
    model_token_type=byte
    g2p=byte
elif [ ${token_type} = "tphn" ]; then
    model_token_type=char
    g2p=none
else
    echo "Error: token_type must be either byte or tphn"
    exit 1
fi

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
    --use_lvector true \
    --lvector_feats_type fam \
    --token_type "${model_token_type}" \
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
