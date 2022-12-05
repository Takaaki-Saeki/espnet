
function evaluate () {

    name=$1
    decode_name=$2
    inf_tag=$3
    use_gt=$4

    echo "Processing ${name}"

    opt=""
    if [ ${use_gt} = true ]; then
        opt="--calc_gt"
    fi

    datadir="data"
    dumpdir="dump"

    cd "eval"
    python3 eval.py \
        --decode_dir ../${name}/exp/${decode_name}/${inf_tag} \
        --data_dir ../${name}/data \
        --setname test \
        --case_name  ${name} ${opt}
    cd ..
}

evaluate "tts_byte_hq13" \
    "tts_train_raw_byte" \
    "decode_hifigan" \
    true

evaluate "tts_byte_hq13_lemb_fam" \
    "tts_train_raw_byte" \
    "decode_hifigan" \
    false

evaluate "tts_byte_hq13_lemb_inv" \
    "tts_train_raw_byte" \
    "decode_hifigan" \
    false

evaluate "tts_byte_hq13_lemb_pho" \
    "tts_train_raw_byte" \
    "decode_hifigan" \
    false

evaluate "tts_byte_hq13_lemb_syn" \
    "tts_train_raw_byte" \
    "decode_hifigan" \
    false

evaluate "tts_byte_hq13_lemb_inv" \
    "tts_train_raw_byte" \
    "decode_hifigan" \
    false

evaluate "tts_byte_hq13_xvsb" \
    "tts_train_raw_byte" \
    "decode_hifigan" \
    false

evaluate "tts_phn_hq13" \
    "tts_train_raw_char" \
    "decode_hifigan" \
    false

evaluate "tts_tphn_hq13" \
    "tts_train_raw_char" \
    "decode_hifigan" \
    false