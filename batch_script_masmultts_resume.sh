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

# Installation of espnet
dir=`pwd`; log "Current dir: ${dir}"
cd tools; ./setup_python.sh $(command -v python3)
make TH_VERSION=1.11.0 CUDA_VERSION=11.3
./installers/install_pyopenjtalk.sh
pip3 install --upgrade pip
# Installing speechbrain for x-vector
pip3 install speechbrain
cd ..
dir=`pwd`; log "Current dir: ${dir}"

# Set up dir paths
localdir="${SGE_LOCALDIR}"

######################################
case_name="tts_byte_cm1"
######################################

share_storage="/$HOME/share-storage/dataset"

# Specifying the dataset path
egs_dir=egs2/masmultts/${case_name}
rm -rf ${egs_dir}/exp
dataset_name=MasMulTTS
target_dataset="${share_storage}/${dataset_name}"
cd ${egs_dir}
db_name=MASMULTTS
db_path=db.sh
log "target root: ${target_dataset_root}"
sed -i -e "s@${db_name}.*@${db_name}=${target_dataset}@g" "${db_path}"
cat ${db_path}

# Running training
./run.sh \
--stage 2 --stop-stage 7 \
--dumpdir "${localdir}/dump" \
--ngpu 1
