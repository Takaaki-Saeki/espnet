#######################
dir_name="tts_byte_hq13_lemb_pho"
train_name="tts_train_raw_byte_init_param../tts_pre_byte_m_en/exp/tts_train_raw_byte/valid.loss.best.pth:::tts.lid_emb"
out_name="tts_train_raw_byte"
token="byte"
#######################

datadir="data"
dumpdir="dump"
expdir=exp

cd ${dir_name}

rm -rf ${datadir}
rm -rf ${dumpdir}
rm -rf ${expdir}

./decode.sh --stage 1 --stop-stage 4

# change token list
rm -rf ${dumpdir}/token_list/${token}/tokens.txt
cp ../token_list_${token}.txt ${dumpdir}/token_list/${token}/tokens.txt

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

echo "Successfully finished!"