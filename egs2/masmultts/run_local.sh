#############################
name="tts_pre_byte_m_en"
token="byte"
#############################

datadir="data"
dumpdir="dump"

cd ${name}
./run.sh --stage 3 --stop-stage 4
# change token list
rm -rf ${dumpdir}/token_list/${token}/tokens.txt
cd ${dumpdir}/token_list/${token}
ln -s ../../../../token_list_${token}.txt tokens.txt
cd ../../../
# run training
./run.sh --stage 5 --stop-stage 6 --ngpu 1
