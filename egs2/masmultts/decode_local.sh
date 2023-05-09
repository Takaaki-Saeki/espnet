
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
    rm -rf ${expdir}

    # change token list
    if [ ${token} = "tphn" ]; then
        token_name="char"
    elif [ ${token} = "phn" ]; then
        token_name="phn_none"
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
    for fname in config.yaml train.log latest.pth train.loss.best.pth valid.loss.best.pth train.total_count.best.pth; do
        scp "${abci_base}/${dir_name}/exp/${out_name}/${fname}" "${base}/${dir_name}/exp/${out_name}/${fname}"
    done
    scp "${abci_base}/${dir_name}/exp/${out_name}/images/loss.png" "${base}/${dir_name}/exp/${out_name}/loss.png"

    echo "Decoding with HiFiGAN ..."
    hifigan_dir=/home/saeki/workspace/multilingual-tts/espnet-voc/egs/masmultts/voc1/exp/train_nodev_hifigan.v1
    hifigan_ckpt=checkpoint-2000000steps.pkl

    ./decode.sh --stage 7 --stop-stage 7 \
        --gpu_inference false \
        --vocoder_file "${hifigan_dir}/${hifigan_ckpt}" \
        --inference_tag decode_hifigan
    
    # rm -rf ${datadir}
    rm -rf ${dumpdir}
    cd ..
    echo "Successfully finished!"
}

function decode () {

    dir_name=$1
    token=$2

    echo "dir_name: ${dir_name}"
    echo "token: ${token}"

    cd ${dir_name}

    # change token list
    if [ ${token} = "tphn" ]; then
        token_name="char"
    elif [ ${token} = "phn" ]; then
        token_name="phn_none"
    elif [ ${token} = "byte" ]; then
        token_name="byte"
    elif [ ${token} = "bphn" ]; then
        token_name="word"
    else
        echo "No such token: ${token}"
        exit 1
    fi

    base="/home/saeki/workspace/multilingual-tts/cmu/espnet/egs2/masmultts"

    out_name="tts_train_raw_${token_name}"

    echo "Decoding with HiFiGAN ..."
    hifigan_dir=/home/saeki/workspace/multilingual-tts/espnet-voc/egs/masmultts/voc1/exp/train_nodev_hifigan.v1
    hifigan_ckpt=checkpoint-2000000steps.pkl

    ./run.sh --stage 7 --stop-stage 7 \
        --gpu_inference false \
        --vocoder_file "${hifigan_dir}/${hifigan_ckpt}" \
        --inference_tag decode_hifigan

    cd ..
    echo "Successfully finished!"
}

decode tts2_mlmzero_bphn_lid_multi_it_encfix bphn
decode tts2_mlmzero_bphn_lid_multi_ta_encfix bphn
decode tts2_mlmzero_byte_lid_multi_it_encfix byte
decode tts2_mlmzero_byte_lid_multi_ta_encfix byte

#decode tts2_mlmtune_bphn_lid_multi_it_encfix bphn
#decode tts2_mlmtune_bphn_lid_multi_ta_encfix bphn
#decode tts2_mlmtune_byte_lid_multi_it_encfix byte
#decode tts2_mlmtune_byte_lid_multi_ta_encfix byte

# decode tts2_bphn_lid_phninf bphn
#decode tts2_finetune_byte_lid_it_nopre byte
#decode tts2_finetune_byte_lid_ta_nopre byte

#decode tts2_finetune_bphn_lid_it bphn
#decode tts2_finetune_bphn_lid_ta bphn
#decode tts2_finetune_byte_lid_it byte
#decode tts2_finetune_byte_lid_ta byte

#decode tts2_mlmtune_bphn_lid_mono_it bphn
#decode tts2_mlmtune_bphn_lid_mono_ta bphn
#decode tts2_mlmtune_byte_lid_mono_it byte
#decode tts2_mlmtune_byte_lid_mono_ta byte

#decode tts2_mlmtune_bphn_lid_multi_it bphn
#decode tts2_mlmtune_bphn_lid_multi_ta bphn
#decode tts2_mlmtune_byte_lid_multi_it byte
#decode tts2_mlmtune_byte_lid_multi_ta byte

#decode tts2_mlmtune_encfr_bphn_lid_multi_it bphn
#decode tts2_mlmtune_encfr_bphn_lid_multi_ta bphn
#decode tts2_mlmtune_laefr_bphn_lid_multi_it bphn
#decode tts2_mlmtune_laefr_bphn_lid_multi_ta bphn

# decode tts2_bphn_lid bphn
# decode tts2_byte_lid byte
# decode tts2_finetune_bphn_lid_it bphn
# decode tts2_finetune_bphn_lid_it bphn
# decode tts2_finetune_byte_lid_it byte
# decode tts2_mlmzero_bphn_lid_multi_it bphn
# decode tts2_mlmzero_byte_lid_multi_it byte
# decode tts2_mlmtune_bphn_lid_multi_it bphn
# decode tts2_mlmtune_byte_lid_multi_it byte

# decode tts2_finetune_bphn_lid_it bphn

#decode tts2_mlmtune_byte_lid_mono_it byte
#decode tts2_mlmtune_byte_lid_mono_ta byte
#decode tts2_mlmtune_encfr_bphn_lid_multi_it bphn
#decode tts2_mlmtune_encfr_bphn_lid_multi_ta bphn
#decode tts2_mlmtune_laefr_bphn_lid_multi_it bphn
#decode tts2_mlmtune_laefr_bphn_lid_multi_ta bphn

#decode tts2_mlmzero_bphn_lid_mono_it bphn
#decode tts2_mlmzero_bphn_lid_mono_ta bphn
#decode tts2_mlmzero_bphn_lid_multi_it bphn
#decode tts2_mlmzero_bphn_lid_multi_ta bphn

#decode tts2_mlmzero_byte_lid_mono_it byte
#decode tts2_mlmzero_byte_lid_mono_ta byte
#decode tts2_mlmzero_byte_lid_multi_it byte
#decode tts2_mlmzero_byte_lid_multi_ta byte

#decode tts2_finetune_bphn_lid_it bphn
#decode tts2_finetune_bphn_lid_ta bphn
#decode tts2_finetune_byte_lid_it byte
#decode tts2_finetune_byte_lid_ta byte

#decode tts2_mlmtune_bphn_lid_mono_it bphn
#decode tts2_mlmtune_bphn_lid_mono_ta bphn
#decode tts2_mlmtune_bphn_lid_multi_it bphn
#decode tts2_mlmtune_bphn_lid_multi_ta bphn
#decode tts2_mlmtune_byte_lid_multi_it byte
#decode tts2_mlmtune_byte_lid_multi_ta byte

#decode tts2_finetune_bphn_lid_it bphn
#decode tts2_finetune_byte_lid_it byte
#decode tts2_finetune_bphn_lid_ta bphn
#decode tts2_finetune_byte_lid_ta byte

# decode tts2_finetune_bphn_lid_ta bphn
# decode tts2_finetune_byte_lid_ta byte
# decode tts2_finetune_bphn_lid_it bphn
# decode tts2_finetune_byte_lid_it byte
# decode tts2_mlmzero_bphn_lid_multi_it bphn
# decode tts2_mlmzero_byte_lid_multi_it byte
# decode tts2_mlmtune_bphn_lid_multi_it bphn
# decode tts2_mlmtune_byte_lid_multi_it byte

# process "tts_byte_css10_adap_hu_residual_freeze" "byte"
# process "tts_phn_css10_hu" "phn"
# process "tts_byte_css10_adap_residual_update" "byte"
# process "tts_vits_byte_css10_adap_residual_freeze" "byte"
# process "tts_vits_phn_css10_adap_residual_freeze" "phn"
# process "tts_byte_masmul" "byte"
# process "tts_byte_masmul_adap_residual_freeze" "byte"
# process "tts_byte_css10_adap_residual_load" "byte"
# process "tts_byte_css10_adap_transformer_freeze" "byte"
# process "tts_byte_css10_pre" "byte"
# process "tts_phn_css10_pre" "phn"
# process "tts_byte_1L_es_renamed" "byte"
# process "tts_phn_1L_de" "phn"
# process "tts_phn_1L_es" "phn"
# process "tts_vits_phn_1L_de" "phn"
# process "tts_vits_byte_css10_all" "byte"
# process "tts_vits_byte_css10" "byte"
# process "tts_vits_byte_css10_adap_residual_freeze" "byte"
# process "tts_vits_byte_css10_all" "byte"
# process "tts_vits_phn_1L_de" "phn"
# process "tts_vits_phn_1L_es" "phn"
# process "tts_vits_phn_css10" "phn"
# process "tts_vits_phn_css10_all" "phn"
# process "tts_vits_phn_css10_adap_residual_freeze" "phn"
# process "tts_phn_css10_all" "phn"
# process "tts_byte_css10_adap_residual_freeze_noenc" "byte"
# process "tts_byte_css10_adap_residual_update" "byte"
# process "tts_byte_css10" "byte"
# process "tts_byte_css10_east" "byte"
# process "tts_byte_css10_all" "byte"
# process "tts_byte_css10_adap_identity_freeze" "byte"
# process "tts_byte_css10_adap_residual_freeze" "byte"
# process "tts_byte_css10_east_adap_residual_freeze" "byte"
# process "tts_byte_css10_adap_transformer_freeze" "byte"
# process "tts_phn_css10" "phn"
# process "tts_phn_css10_adap_residual_freeze" "phn"
# process "tts_vits_phn_1L_de" "phn"
# process "tts_vits_phn_1L_es" "phn"