
function evaluate () {

    name=$1
    token=$2
    use_gt=$3

    # change token list
    if [ ${token} = "tphn" ]; then
        token_name="char"
        ref_name=`echo ${name//tphn/byte}`
    elif [ ${token} = "phn" ]; then
        token_name="phn_none"
        ref_name=`echo ${name//phn/byte}`
    elif [ ${token} = "byte" ]; then
        token_name="byte"
        ref_name=${name}
    elif [ ${token} = "bphn" ]; then
        token_name="word"
        ref_name=`echo ${name//bphn/byte}`
    else
        echo "No such token: ${token}"
        exit 1
    fi

    # Replacing phn with byte
    # Removing vits
    ref_name=`echo ${ref_name//_vits/}`

    # Removing suffixes
    ref_name=`echo ${ref_name//_encfr/}`
    ref_name=`echo ${ref_name//_laefr/}`
    ref_name=`echo ${ref_name//_phninf/}`
    ref_name=`echo ${ref_name//_encfix/}`

    # replacing mono to multi
    ref_name=`echo ${ref_name//mono/multi}`

    opt=""
    if [ ${use_gt} = true ]; then
        opt="--calc_gt"
    fi

    echo "dir_name: ${name}"
    echo "token: ${token}"
    echo "ref_name: ${ref_name}"

    out_name="tts_train_raw_${token_name}"

    cd "eval"
    python3 eval.py \
        --decode_dir ../${name}/exp/${out_name}/decode_hifigan \
        --data_dir ../${ref_name}/data \
        --setname test \
        --case_name  ${name} ${opt}
    cd ..
}


function evaluate_ref () {

    name=$1
    ref_name=$2
    token=$3
    use_gt=$4

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

    opt=""
    if [ ${use_gt} = true ]; then
        opt="--calc_gt"
    fi

    echo "dir_name: ${name}"
    echo "token: ${token}"
    echo "ref_name: ${ref_name}"

    out_name="tts_train_raw_${token_name}"

    cd "eval"
    python3 eval.py \
        --decode_dir ../${name}/exp/${out_name}/decode_hifigan \
        --data_dir ../${ref_name}/data \
        --setname test \
        --case_name  ${name} ${opt}
    cd ..
}

function evaluate_xv () {

    name=$1
    ref_name=$2
    token=$3
    use_gt=$4

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

    opt=""
    if [ ${use_gt} = true ]; then
        opt="--calc_gt"
    fi

    echo "dir_name: ${name}"
    echo "token: ${token}"
    echo "ref_name: ${ref_name}"

    out_name="tts_train_raw_${token_name}"

    cd "eval"
    python3 eval.py \
        --decode_dir ../${name}/exp/${out_name}/xvector \
        --data_dir ../${ref_name}/data \
        --setname test \
        --results_dir "results_xvector" \
        --case_name  ${name} ${opt}
    cd ..
}

evaluate tts2_mlmzero_bphn_lid_multi_it_encfix bphn true
evaluate tts2_mlmzero_bphn_lid_multi_ta_encfix bphn true
evaluate tts2_mlmzero_byte_lid_multi_it_encfix byte true
evaluate tts2_mlmzero_byte_lid_multi_ta_encfix byte true

#evaluate tts2_mlmtune_bphn_lid_multi_it_encfix bphn true
#evaluate tts2_mlmtune_bphn_lid_multi_ta_encfix bphn true
#evaluate tts2_mlmtune_byte_lid_multi_it_encfix byte true
#evaluate tts2_mlmtune_byte_lid_multi_ta_encfix byte true

#evaluate tts2_finetune_byte_lid_it_nopre byte true
#evaluate tts2_finetune_byte_lid_ta_nopre byte true

# evaluate tts2_bphn_lid_phninf bphn true

#evaluate tts2_finetune_bphn_lid_it bphn true
#evaluate tts2_finetune_bphn_lid_ta bphn true
#evaluate tts2_finetune_byte_lid_it byte true
#evaluate tts2_finetune_byte_lid_ta byte true

#evaluate tts2_mlmtune_bphn_lid_mono_it bphn true
#evaluate tts2_mlmtune_bphn_lid_mono_ta bphn true
#evaluate tts2_mlmtune_byte_lid_mono_it byte true
#evaluate tts2_mlmtune_byte_lid_mono_ta byte true

#evaluate tts2_mlmtune_bphn_lid_multi_it bphn true
#evaluate tts2_mlmtune_bphn_lid_multi_ta bphn true
#evaluate tts2_mlmtune_byte_lid_multi_it byte true
#evaluate tts2_mlmtune_byte_lid_multi_ta byte true

#evaluate tts2_mlmtune_encfr_bphn_lid_multi_it bphn true
#evaluate tts2_mlmtune_encfr_bphn_lid_multi_ta bphn true
#evaluate tts2_mlmtune_laefr_bphn_lid_multi_it bphn true
#evaluate tts2_mlmtune_laefr_bphn_lid_multi_ta bphn true

# evaluate tts2_bphn_lid "bphn" true
# evaluate tts2_byte_lid "byte" true
# evaluate tts2_finetune_bphn_lid_it bphn true
# evaluate tts2_finetune_byte_lid_it byte true
# evaluate tts2_mlmzero_bphn_lid_multi_it bphn true
# evaluate tts2_mlmzero_byte_lid_multi_it byte true
# evaluate tts2_mlmtune_bphn_lid_multi_it bphn true
# evaluate tts2_mlmtune_byte_lid_multi_it byte true
# evaluate tts2_finetune_bphn_lid_it bphn true
# evaluate tts2_finetune_byte_lid_it byte true
# evaluate tts2_mlmzero_bphn_lid_multi_it bphn true
# evaluate tts2_mlmzero_byte_lid_multi_it byte true
# evaluate tts2_mlmtune_bphn_lid_multi_it bphn true
# evaluate tts2_mlmtune_byte_lid_multi_it byte true
# evaluate tts2_finetune_bphn_lid_it bphn true
# evaluate tts2_finetune_byte_lid_it byte true
# evaluate tts2_finetune_bphn_lid_ta bphn true
# evaluate tts2_finetune_byte_lid_ta byte true

# evaluate tts2_finetune_bphn_lid_it bphn false

#evaluate tts2_mlmtune_byte_lid_mono_it byte true
#evaluate tts2_mlmtune_byte_lid_mono_ta byte true
#evaluate tts2_mlmtune_encfr_bphn_lid_multi_it bphn true
#evaluate tts2_mlmtune_encfr_bphn_lid_multi_ta bphn true
#evaluate tts2_mlmtune_laefr_bphn_lid_multi_it bphn true
#evaluate tts2_mlmtune_laefr_bphn_lid_multi_ta bphn true

#evaluate tts2_mlmzero_bphn_lid_mono_it bphn true
#evaluate tts2_mlmzero_bphn_lid_mono_ta bphn true
#evaluate tts2_mlmzero_bphn_lid_multi_it bphn true
#evaluate tts2_mlmzero_bphn_lid_multi_ta bphn true

#evaluate tts2_mlmzero_byte_lid_mono_it byte true
#evaluate tts2_mlmzero_byte_lid_mono_ta byte true
#evaluate tts2_mlmzero_byte_lid_multi_it byte true
#evaluate tts2_mlmzero_byte_lid_multi_ta byte true

#evaluate tts2_finetune_bphn_lid_it bphn true
#evaluate tts2_finetune_bphn_lid_ta bphn true
#evaluate tts2_finetune_byte_lid_it byte true
#evaluate tts2_finetune_byte_lid_ta byte true

#evaluate tts2_mlmtune_bphn_lid_mono_it bphn true
#evaluate tts2_mlmtune_bphn_lid_mono_ta bphn true
#evaluate tts2_mlmtune_bphn_lid_multi_it bphn true
#evaluate tts2_mlmtune_bphn_lid_multi_ta bphn true
#evaluate tts2_mlmtune_byte_lid_multi_it byte true
#evaluate tts2_mlmtune_byte_lid_multi_ta byte true

# evaluate_xv "tts_byte_css10_de" "tts_byte_css10_adap_de_residual_freeze" "byte" false
# evaluate_xv "tts_byte_css10_hu" "tts_byte_css10_adap_hu_residual_freeze" "byte" false
# evaluate_xv "tts_phn_css10_adap_de_residual_freeze" "tts_byte_css10_adap_de_residual_freeze" "phn" false
# evaluate_xv "tts_phn_css10_adap_hu_residual_freeze" "tts_byte_css10_adap_hu_residual_freeze" "phn" false

#evaluate "tts_taco_byte_1L_hu" "byte" false
#evaluate "tts_taco_byte_1L_nl" "byte" false
#evaluate "tts_taco_byte_1L_el" "byte" false
#evaluate "tts_taco_phn_1L_hu" "phn" false
#evaluate "tts_taco_phn_1L_nl" "phn" false
#evaluate "tts_taco_phn_1L_el" "phn" false

# evaluate_ref "tts_byte_css10_adap_hu_residual_freeze" "tts_byte_css10_adap_residual_freeze" "byte" false
# evaluate_ref "tts_phn_css10_hu" "tts_byte_css10_adap_residual_freeze" "phn" false

# evaluate "tts_byte_css10_adap_voxpara_residual_freeze" "byte" false

#evaluate_xv "tts_byte_css10_adap_residual_freeze" "tts_byte_css10_adap_residual_freeze" "byte" false
#evaluate_xv "tts_byte_css10" "tts_byte_css10_adap_residual_freeze" "byte" false
#evaluate_xv "tts_byte_css10_all" "tts_byte_css10_adap_residual_freeze" "byte" false
#evaluate_xv "tts_phn_css10_adap_residual_freeze" "tts_byte_css10_adap_residual_freeze" "phn" false
#evaluate_xv "tts_phn_css10" "tts_byte_css10_adap_residual_freeze" "phn" false
#evaluate_xv "tts_phn_css10_all" "tts_byte_css10_adap_residual_freeze" "phn" false

# evaluate_xv "tts_byte_1L_de" "tts_byte_1L_de" "byte"

# evaluate "tts_byte_css10_adap_de_residual_freeze" "byte" false
# evaluate "tts_byte_css10_adap_ru_residual_freeze" "byte" false
# evaluate "tts_phn_css10_de" "phn" false
# evaluate "tts_phn_css10_ru" "phn" false
# evaluate_ref "tts_phn_css10_de" "tts_byte_css10_adap_de_residual_freeze" "phn" false

# evaluate "tts_byte_css10_adap_residual_freeze" "byte" false

# evaluate "tts_byte_css10_adap_residual_freeze_noenc" "byte" false
# evaluate "tts_byte_css10" "byte" false
# evaluate "tts_byte_css10_east" "byte" false
# evaluate "tts_byte_css10_all" "byte" true
# evaluate "tts_byte_css10_adap_identity_freeze" "byte" false
# evaluate "tts_byte_css10_adap_residual_freeze" "byte" false
# evaluate "tts_byte_css10_adap_para_residual_freeze" "byte" false
# evaluate "tts_byte_css10_adap_residual_update" "byte" false
# evaluate "tts_byte_css10_east_adap_residual_freeze" "byte" false
# evaluate "tts_byte_css10_adap_transformer_freeze" "byte" false
# evaluate "tts_phn_css10" "phn" false
# evaluate "tts_phn_css10_all" "phn" false
# evaluate "tts_phn_css10_adap_residual_freeze" "phn" false

#evaluate "tts_taco_byte_1L_de" "byte" false
#evaluate "tts_taco_byte_1L_es" "byte" false
#evaluate "tts_taco_byte_1L_fr" "byte" false
#evaluate "tts_taco_byte_1L_fi" "byte" false
#evaluate "tts_taco_byte_1L_ru" "byte" false
#evaluate "tts_taco_phn_1L_de" "phn" false
#evaluate "tts_taco_phn_1L_es" "phn" false
#evaluate "tts_taco_phn_1L_fr" "phn" false
#evaluate "tts_taco_phn_1L_fi" "phn" false
#evaluate "tts_taco_phn_1L_ru" "phn" false

#evaluate "tts_byte_css10_adap_transformer_freeze" "byte" false
#evaluate "tts_byte_css10_adap_residual_freeze_noenc" "byte" false

# evaluate "tts_byte_css10_adap_residual_load" "byte" false
# evaluate "tts_taco_byte_1L_ru" "byte" false
# evaluate "tts_taco_phn_1L_ru" "phn" false

# evaluate "tts_byte_css10_pre" "byte" false
# evaluate "tts_phn_css10_pre" "phn" false

# evaluate_ref "tts_byte_1L_de" "tts_byte_1L_de" "byte"
# evaluate_ref "tts_byte_1L_es_renamed" "tts_byte_1L_es_renamed" "byte"
# evaluate_ref "tts_phn_1L_de" "tts_byte_1L_de" "phn"
# evaluate_ref "tts_phn_1L_es" "tts_byte_1L_es_renamed" "phn"

# evaluate_ref "tts_vits_phn_1L_de" "tts_byte_1L_de" "phn" false
# evaluate_ref "tts_vits_phn_1L_es" "tts_byte_1L_es_renamed" "phn" false

#evaluate "tts_vits_byte_css10" "byte" false
#evaluate "tts_vits_byte_css10_adap_residual_freeze" "byte" false
#evaluate "tts_vits_byte_css10_all" "byte" false
#evaluate "tts_vits_phn_1L_de" "phn" false
#evaluate "tts_vits_phn_1L_es" "phn" false
#evaluate "tts_vits_phn_css10" "phn" false
#evaluate "tts_vits_phn_css10_all" "phn" false
#evaluate "tts_vits_phn_css10_adap_residual_freeze" "phn" false
