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
cd ..
dir=`pwd`; log "Current dir: ${dir}"

# Set up dir paths
localdir="${SGE_LOCALDIR}"
target_dataset_root="${localdir}/dataset"
rm -rf ${target_dataset_root}

# Copying data to working directory
log "Copying data to ${localdir} ..."
mkdir -p ${target_dataset_root}
cp -r /$HOME/share-storage/dataset/LJSpeech-1.1.tar.gz ${target_dataset_root}/
tar -zxvf ${target_dataset_root}/LJSpeech-1.1.tar.gz -C ${target_dataset_root}
echo "Successfully copied datasets"

# Specifying the dataset path
egs_dir=egs2/ljspeech/tts1
cd ${egs_dir}
db_name=LJSPEECH
db_path=db.sh
log "target root: ${target_dataset_root}"
sed -i -e "s@${db_name}.*@${db_name}=${target_dataset_root}@g" "${db_path}"
cat ${db_path}

# Running training
./run.sh --stage 1 --stop-stage 6
