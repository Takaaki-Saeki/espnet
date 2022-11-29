#############################
name="tts_byte_hq13_mlm"
token="byte"
use_mlm=true
#############################

datadir="data"
dumpdir="dump"

if [ ${use_mlm} = true ]; then
    cp conf/train.yaml conf/train_override.yaml
fi


# Run preprocessing
cd ${name}
./run.sh --stage 1 --stop-stage 4

if [ ${use_mlm} = true ]; then
    python3 local/write_holdout_info.py \
	    --lang_set lang_set.txt \
	    --holdout_lang holdout_lang_set.txt \
	    --org_dir ${dumpdir}/raw/org \
	    --config conf/train.yaml
fi

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

train_args="--init_param ../${pretrain_name}/exp/tts_train_raw_${token_name}/valid.loss.best.pth:::tts.lid_emb"

rm -rf ${dumpdir}/token_list/${token_name}/tokens.txt
cp ../token_list_${token}.txt ${dumpdir}/token_list/${token_name}/tokens.txt

# run training
./run.sh --stage 5 --stop-stage 6 --ngpu 1 --train_args "${train_args}"
