
function process () {

    dir_name=$1
    train_name=$2
    out_name=$3
    token=$4

    echo "dir_name: ${dir_name}"
    echo "train_name: ${train_name}"
    echo "out_name: ${out_name}"
    echo "token: ${token}"

    datadir="data"
    dumpdir="dump"
    expdir=exp

    cd ${dir_name}

    rm -rf ${datadir}
    rm -rf ${dumpdir}
    rm -rf ${expdir}

    ./decode.sh --stage 1 --stop-stage 4

    # change token list
    if [ ${token} = "tphn" ]; then
        token_name="char"
    elif [ ${token} = "phn" ]; then
        token_name="char"
    elif [ ${token} = "byte" ]; then
        token_name="byte"
    elif [ ${token} = "bphn" ]; then
        token_name="word"
    else
        echo "No such token: ${token}"
        exit 1
    fi

    # change token list
    rm -rf ${dumpdir}/token_list/${token_name}/tokens.txt
    cp ../token_list_${token}.txt ${dumpdir}/token_list/${token_name}/tokens.txt

    echo "Collecting stats ..."
    ./decode.sh --stage 5 --stop-stage 5

    base="/home/saeki/workspace/multilingual-tts/cmu/espnet/egs2/masmultts"
    abci_base="abci:/home/acc12075gq/workspace/multilingual-tts/espnet/egs2/masmultts"

    echo "Making exp dir ..."
    mkdir -p ${base}/${dir_name}/${expdir}/${out_name}

    for fname in config.yaml train.log latest.pth train.loss.best.pth valid.loss.best.pth; do
        scp "${abci_base}/${dir_name}/exp/${train_name}/${fname}" "${base}/${dir_name}/${expdir}/${out_name}/${fname}"
    done
    scp "${abci_base}/${dir_name}/exp/${train_name}/images/loss.png" "${base}/${dir_name}/${expdir}/${out_name}/loss.png"

    echo "Decoding with griffin lim ..."
    ./decode.sh --stage 7 --stop-stage 7 \
        --gpu_inference false \
        --vocoder_file /home/saeki/workspace/multilingual-tts/espnet-voc/egs/masmultts/voc1/exp/train_nodev_hifigan.v1/checkpoint-450000steps.pkl \
        --inference_tag decode_hifigan

    cd ..
    echo "Successfully finished!"
}

process "tts_phn_hq13" \
    "tts_train_raw_char_init_param../tts_pre_phn_m_en/exp/tts_train_raw_char/valid.loss.best.pth:::tts.lid_emb" \
    "tts_train_raw_char" \
    "phn"

process "tts_tphn_hq13" \
    "tts_train_raw_char_init_param../tts_pre_tphn_m_en/exp/tts_train_raw_char/valid.loss.best.pth:::tts.lid_emb" \
    "tts_train_raw_char" \
    "tphn"

process "tts_byte_hq13_lemb_syn" \
    "tts_train_raw_byte_init_param../tts_pre_byte_m_en/exp/tts_train_raw_byte/valid.loss.best.pth:::tts.lid_emb" \
    "tts_train_raw_byte" \
    "byte"

process "tts_byte_hq13_xvsb" \
    "tts_train_raw_byte_init_param../tts_pre_byte_m_en_xvsb/exp/tts_train_raw_byte/valid.loss.best.pth:::tts.lid_emb" \
    "tts_train_raw_byte" \
    "byte"