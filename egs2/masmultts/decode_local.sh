
function process () {

    dir_name=$1
    token=$2

    echo "dir_name: ${dir_name}"
    echo "token: ${token}"

    datadir="data"
    dumpdir="dump"
    expdir="exp"

    cd ${dir_name}

    rm -rf ${datadir}
    rm -rf ${dumpdir}

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

    ./decode.sh --stage 1 --stop-stage 5

    base="/home/saeki/workspace/multilingual-tts/cmu/espnet/egs2/masmultts"
    abci_base="abci:/home/acc12075gq/workspace/multilingual-tts/espnet/egs2/masmultts"

    out_name="tts_train_raw_${token_name}"

    echo "Making exp dir ..."
    mkdir -p "${base}/${dir_name}/exp/${out_name}"

    echo "Copying remote checkpoints ..."
    for fname in config.yaml train.log latest.pth train.loss.best.pth valid.loss.best.pth; do
        scp "${abci_base}/${dir_name}/exp/${out_name}/${fname}" "${base}/${dir_name}/exp/${out_name}/${fname}"
    done
    scp "${abci_base}/${dir_name}/exp/${out_name}/images/loss.png" "${base}/${dir_name}/exp/${out_name}/loss.png"

    echo "Decoding with HiFiGAN ..."
    hifigan_dir=/home/saeki/workspace/multilingual-tts/espnet-voc/egs/masmultts/voc1/exp/train_nodev_hifigan.v1
    hifigan_ckpt=checkpoint-1300000steps.pkl

    ./decode.sh --stage 7 --stop-stage 7 \
        --gpu_inference false \
        --vocoder_file "${hifigan_dir}/${hifigan_ckpt}" \
        --inference_tag decode_hifigan
    
    rm -rf ${datadir}
    rm -rf ${dumpdir}
    cd ..
    echo "Successfully finished!"
}

process "tts_byte_css10" "byte"