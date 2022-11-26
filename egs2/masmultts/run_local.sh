#############################
name="tts_byte_1L_es"
token="byte"
train_args=""

# If using fine-tuning
train_args="--init_param ../tts_pre_byte_m_en/exp/tts_train_raw_byte/valid.loss.best.pth:::tts.lid_emb"
#############################

datadir="data"
dumpdir="dump"

# Run preprocessing
cd ${name}
#./run.sh --stage 1 --stop-stage 4

# change token list
#rm -rf ${dumpdir}/token_list/${token}/tokens.txt
#cp ../token_list_${token}.txt ${dumpdir}/token_list/${token}/tokens.txt

# run training
./run.sh --stage 5 --stop-stage 6 --ngpu 1 --train_args "${train_args}"
