log() {
    local fname=${BASH_SOURCE[1]##*/}
    echo -e "$(date '+%Y-%m-%dT%H:%M:%S') (${fname}:${BASH_LINENO[0]}:${FUNCNAME[1]}) $*"
}

# module import
log "Import basic modules ..."
source /etc/profile.d/modules.sh
module load gcc/9.3.0
module load python/3.8/3.8.13
module load cuda/11.3/11.3.1
module load cudnn/8.2/8.2.4
module load nccl/2.9/2.9.9-1
source $HOME/ssl-tts/bin/activate
log "Successfully done."

# Installation of transphone
pip3 install transphone

######################################
data_type="fleurs"
data_name="fleurs"
# data_type="css10"
# data_type="fleurs"
######################################

share_storage="/$HOME/share-storage/dataset"

# Specifying the dataset path
egs_dir=egs2/masmultts/tts1
cd ${egs_dir}
dir=`pwd`; log "Current dir: ${dir}"
python3 local/byte2bphn.py \
    --in_tsv ${share_storage}/MasMulTTS/${data_name}_norm.tsv \
    --data_type ${data_type}




