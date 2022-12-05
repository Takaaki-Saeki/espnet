#######################
dir_name="tts_byte_hq13"
train_name="tts_train_raw_byte"
#######################

base="/home/saeki/workspace/multilingual-tts/cmu/espnet/egs2/masmultts"
abci_base="abci:/home/acc12075gq/workspace/multilingual-tts/espnet/egs2/masmultts"

if [ ! -e ${base}/${dir_name} ]; then
    echo "No such directory: ${base}/${dir_name}"
    exit 1
fi

if [ ! -e ${base}/${dir_name}/data ]; then
    echo "Make data dir first."
    exit 1
fi

if [ ! -e ${base}/${dir_name}/dump ]; then
    echo "Make dump dir first."
    exit 1
fi

if [ ! -e ${base}/${dir_name}/exp/${train_name} ]; then
    echo "Making exp dir ..."
    mkdir -p ${base}/${dir_name}/exp/${train_name}
fi

for fname in config.yaml train.log latest.pth train.loss.best.pth valid.loss.best.pth; do
    scp "${abci_base}/${dir_name}/exp/${train_name}/${fname}" "${base}/${dir_name}/exp/${train_name}/${fname}"
done
scp "${abci_base}/${dir_name}/exp/${train_name}/images/loss.png" "${base}/${dir_name}/exp/${train_name}/loss.png"

echo "Successfully finished!"
