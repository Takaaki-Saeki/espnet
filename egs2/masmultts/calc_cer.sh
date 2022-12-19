
function evaluate () {

    name=$1
    ref_name=$2
    token=$3
    use_gt=$4

    echo "dir_name: ${name}"
    echo "token: ${token}"

    # change token list
    if [ ${token} = "tphn" ]; then
        token_name="char"
    elif [ ${token} = "phn" ]; then
        token_name="word"
    elif [ ${token} = "byte" ]; then
        token_name="byte"
    elif [ ${token} = "bphn" ]; then
        token_name="word"
    else
        echo "No such token: ${token}"
        exit 1
    fi

    opt=""
    if [ ${use_gt} = true ]; then
        opt="--calc_gt"
    fi

    out_name="tts_train_raw_${token_name}"

    cd "eval"
    python3 eval.py \
        --decode_dir ../${name}/exp/${out_name}/decode_hifigan \
        --data_dir ../${ref_name}/data \
        --setname test \
        --case_name  ${name} ${opt}
    cd ..
}

# Need to set "ref_name" because data/text in phn case includes dumped phoneme tokens.
evaluate "tts_phn_css10" "tts_byte_css10" "phn" true
# evaluate "tts_byte_css10" "tts_byte_css10" "byte" false
# evaluate "tts_phn_css10_all" "tts_byte_css10" "phn" false
# evaluate "tts_byte_1L_de" "tts_byte_1L_de" "byte" true
# evaluate "tts_byte_1L_es_renamed" "tts_byte_1L_es_renamed" "byte" true
# evaluate "tts_phn_1L_de" "tts_byte_1L_de" "phn" true
# evaluate "tts_phn_1L_es" "tts_byte_1L_es_renamed" "phn" true