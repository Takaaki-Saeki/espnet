#############################
name="tts_pre_byte_m_en"
#############################

datadir="data"
dumpdir="dump"

cd ${name}

echo "Traning case: ${name}"

echo "Decoding with griffin lim ..."
./run.sh --stage 7 --stop-stage 7 --inference_tag decode_griffin_lim
echo "Decoding with PWG ..."
./run.sh --stage 7 --stop-stage 7 \
    --vocoder_file ../pwg_soumi/checkpoint-400000steps.pkl \
    --inference_tag decode_soumi_pwg

#./run.sh --stage 7 --stop-stage 7 \
#   --inference_args "--vocoder_tag parallel_wavegan/arctic_slt_parallel_wavegan.v1" \
#   --inference_tag decode_with_arctic_slt_parallel_wavegan.v1