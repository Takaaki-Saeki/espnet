
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
        token_name="word"
    elif [ ${token} = "byte" ]; then
        token_name="byte"
    elif [ ${token} = "bphn" ]; then
        token_name="word"
    else
        echo "No such token: ${token}"
        exit 1
    fi

    ./decode.sh --stage 1 --stop-stage 1

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

# process "tts_phn_1L_de" "phn"
# process "tts_byte_1L_de" "byte"
# process "tts_phn_1L_es" "phn"
# process "tts_byte_1L_es_renamed" "byte"
# process "tts_phn_css10" "phn"
# process "tts_phn_css10_all" "phn"
process "tts_byte_css10" "byte"