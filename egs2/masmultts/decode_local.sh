#############################
name="tts_byte_95L_lemb"
#############################

datadir="data"
dumpdir="dump"

cd ${name}

echo "Traning case: ${name}"

echo "Decoding with griffin lim ..."
./decode.sh --stage 7 --stop-stage 7 --gpu_inference false --inference_tag decode_griffin_lim

# echo "Decoding with PWG ..."
#./decode.sh --stage 7 --stop-stage 7 \
#    --gpu_inference true \
#    --vocoder_file ../pwg_soumi/checkpoint-400000steps.pkl \
#    --inference_tag decode_soumi_pwg

#./run.sh --stage 7 --stop-stage 7 \
#   --inference_args "--vocoder_tag parallel_wavegan/arctic_slt_parallel_wavegan.v1" \
#   --inference_tag decode_with_arctic_slt_parallel_wavegan.v1