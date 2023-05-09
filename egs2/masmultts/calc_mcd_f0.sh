
function process () {

    dir_name=$1
    token=$2

    echo "dir_name: ${dir_name}"
    echo "token: ${token}"

    datadir="data"

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

    # ./decode.sh --stage 1 --stop-stage 1

    out_name="tts_train_raw_${token_name}"

    python3 pyscripts/utils/evaluate_mcd.py \
	    exp/${out_name}/decode_hifigan/test/wav \
	    data/test/wav.scp \
	    --out_dir exp/${out_name}/decode_hifigan/test

    python3 pyscripts/utils/convert_utt2mcd_to_lang2mcd.py \
	    --utt2mcd exp/${out_name}/decode_hifigan/test/utt2mcd \
	    --wavscp data/test/wav.scp \
	    --utt2lang data/test/utt2lang \
	    --out_file exp/${out_name}/decode_hifigan/test/lang2mcd

    python3 pyscripts/utils/evaluate_f0.py \
	    exp/${out_name}/decode_hifigan/test/wav \
	    data/test/wav.scp \
	    --out_dir exp/${out_name}/decode_hifigan/test

    python3 pyscripts/utils/convert_utt2mcd_to_lang2mcd.py \
	    --utt2mcd exp/${out_name}/decode_hifigan/test/utt2log_f0_rmse \
	    --wavscp data/test/wav.scp \
	    --utt2lang data/test/utt2lang \
	    --out_file exp/${out_name}/decode_hifigan/test/lang2log_f0_rmse

    cd ..
    echo "Successfully finished!"
}

process tts2_mlmzero_bphn_lid_multi_it_encfix bphn
process tts2_mlmzero_bphn_lid_multi_ta_encfix bphn
process tts2_mlmzero_byte_lid_multi_it_encfix byte
process tts2_mlmzero_byte_lid_multi_ta_encfix byte

#process tts2_mlmtune_bphn_lid_multi_it_encfix bphn
#process tts2_mlmtune_bphn_lid_multi_ta_encfix bphn
#process tts2_mlmtune_byte_lid_multi_it_encfix byte
#process tts2_mlmtune_byte_lid_multi_ta_encfix byte

# process tts2_bphn_lid_phninf bphn
#process tts2_finetune_byte_lid_it_nopre byte
#process tts2_finetune_byte_lid_ta_nopre byte

#process tts2_finetune_bphn_lid_it bphn
#process tts2_finetune_bphn_lid_ta bphn
#process tts2_finetune_byte_lid_it byte
#process tts2_finetune_byte_lid_ta byte

#process tts2_mlmtune_bphn_lid_mono_it bphn
#process tts2_mlmtune_bphn_lid_mono_ta bphn
#process tts2_mlmtune_byte_lid_mono_it byte
#process tts2_mlmtune_byte_lid_mono_ta byte

#process tts2_mlmtune_bphn_lid_multi_it bphn
#process tts2_mlmtune_bphn_lid_multi_ta bphn
#process tts2_mlmtune_byte_lid_multi_it byte
#process tts2_mlmtune_byte_lid_multi_ta byte

#process tts2_mlmtune_encfr_bphn_lid_multi_it bphn
#process tts2_mlmtune_encfr_bphn_lid_multi_ta bphn
#process tts2_mlmtune_laefr_bphn_lid_multi_it bphn
#process tts2_mlmtune_laefr_bphn_lid_multi_ta bphn

# process tts2_finetune_bphn_lid_it bphn
# process tts2_finetune_byte_lid_it byte
# process tts2_mlmzero_bphn_lid_multi_it bphn
# process tts2_mlmzero_byte_lid_multi_it byte
# process tts2_mlmtune_bphn_lid_multi_it bphn
# process tts2_mlmtune_byte_lid_multi_it byte
# process tts2_finetune_bphn_lid_it bphn
# process tts2_finetune_byte_lid_it byte
# process tts2_mlmzero_bphn_lid_multi_it bphn
# process tts2_mlmzero_byte_lid_multi_it byte
# process tts2_mlmtune_bphn_lid_multi_it bphn
# process tts2_mlmtune_byte_lid_multi_it byte

#process tts2_finetune_bphn_lid_it bphn

#process tts2_mlmtune_byte_lid_mono_it byte
#process tts2_mlmtune_byte_lid_mono_ta byte
#process tts2_mlmtune_encfr_bphn_lid_multi_it bphn
#process tts2_mlmtune_encfr_bphn_lid_multi_ta bphn
#process tts2_mlmtune_laefr_bphn_lid_multi_it bphn
#process tts2_mlmtune_laefr_bphn_lid_multi_ta bphn

#process tts2_mlmzero_bphn_lid_mono_it bphn
#process tts2_mlmzero_bphn_lid_mono_ta bphn
#process tts2_mlmzero_bphn_lid_multi_it bphn
#process tts2_mlmzero_bphn_lid_multi_ta bphn

#process tts2_mlmzero_byte_lid_mono_it byte
#process tts2_mlmzero_byte_lid_mono_ta byte
#process tts2_mlmzero_byte_lid_multi_it byte
#process tts2_mlmzero_byte_lid_multi_ta byte

#process tts2_finetune_bphn_lid_it bphn
#process tts2_finetune_bphn_lid_ta bphn
#process tts2_finetune_byte_lid_it byte
#process tts2_finetune_byte_lid_ta byte

#process tts2_mlmtune_bphn_lid_mono_it bphn
#process tts2_mlmtune_bphn_lid_mono_ta bphn
#process tts2_mlmtune_bphn_lid_multi_it bphn
#process tts2_mlmtune_bphn_lid_multi_ta bphn
#process tts2_mlmtune_byte_lid_multi_it byte
#process tts2_mlmtune_byte_lid_multi_ta byte

#process tts2_finetune_bphn_lid_it bphn
#process tts2_finetune_byte_lid_it byte
#process tts2_finetune_bphn_lid_ta bphn
#rocess tts2_finetune_byte_lid_ta byte

# process tts2_byte_lid byte
# process "tts_byte_css10_de" "byte"
# process "tts_byte_css10_hu" "byte"
# process "tts_phn_css10_adap_de_residual_freeze" "phn"
# process "tts_phn_css10_adap_hu_residual_freeze" "phn"

#process "tts_taco_byte_1L_hu" "byte"
#process "tts_taco_byte_1L_nl" "byte"
#process "tts_taco_byte_1L_el" "byte"
#process "tts_taco_phn_1L_hu" "phn"
#process "tts_taco_phn_1L_nl" "phn"
#process "tts_taco_phn_1L_el" "phn"

# process "tts_byte_css10_adap_voxpara_residual_freeze" "byte"
# process "tts_byte_css10_adap_hu_residual_freeze" "byte"
# process "tts_phn_css10_hu" "phn"

# process "tts_byte_css10_adap_residual_freeze_nolid" "byte"

# process "tts_byte_css10_adap_de_residual_freeze" "byte"
# process "tts_byte_css10_adap_ru_residual_freeze" "byte"
# process "tts_phn_css10_de" "phn"
# process "tts_phn_css10_ru" "phn"

# process "tts_byte_css10_adap_residual_update" "byte"
# process "tts_vits_byte_css10" "byte" 
# process "tts_vits_byte_css10_adap_residual_freeze" "byte"
# process "tts_vits_byte_css10_all" "byte"
# process "tts_vits_phn_css10" "phn"
# process "tts_vits_phn_css10_all" "phn"
# process "tts_vits_phn_css10_adap_residual_freeze" "phn"

# process "tts_byte_masmul" "byte"
# process "tts_byte_masmul_adap_residual_freeze" "byte"

# process "tts_byte_css10_adap_transformer_freeze" "byte"

# process "tts_taco_byte_1L_ru" "byte"
# process "tts_taco_phn_1L_ru" "phn"

# process "tts_byte_css10_pre" "byte"
# process "tts_phn_css10_pre" "phn"

# process "tts_taco_byte_1L_de" "byte"
# process "tts_taco_byte_1L_es" "byte"
# process "tts_taco_byte_1L_fr" "byte"
# process "tts_taco_byte_1L_fi" "byte"
# process "tts_taco_byte_1L_ru" "byte"
# process "tts_taco_phn_1L_de" "phn"
# process "tts_taco_phn_1L_es" "phn"
# process "tts_taco_phn_1L_fr" "phn"
# process "tts_taco_phn_1L_fi" "phn"
# process "tts_taco_phn_1L_ru" "phn"

# process "tts_vits_byte_css10" "byte"
# process "tts_vits_byte_css10_adap_residual_freeze" "byte"
# process "tts_vits_byte_css10_all" "byte"
# process "tts_vits_phn_1L_de" "phn"
# process "tts_vits_phn_1L_es" "phn"
# process "tts_vits_phn_css10" "phn"
# process "tts_vits_phn_css10_all" "phn"
# process "tts_vits_phn_css10_adap_residual_freeze" "phn"

# process "tts_byte_css10_adap_residual_freeze_noenc" "byte"
# process "tts_phn_css10_all" "phn"
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