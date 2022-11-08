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

# Not copying data directory due to storage limitation
# target_dataset_root="${localdir}/dataset"
share_storage="/$HOME/share-storage/dataset"
# rm -rf ${target_dataset_root}
# log "Copying data to ${localdir} ..."
# mkdir -p ${target_dataset_root}
# cp -r /$HOME/share-storage/dataset/mailab.tar.gz ${target_dataset_root}/
# tar -zxvf ${target_dataset_root}/mailab.tar.gz -C ${target_dataset_root} --remove-files
# tar -zxvf "${share_storage}/mailab.tar.gz" -C "${share_storage}"
# echo "Successfully copied datasets"

# Specifying the dataset path
## tts1: filtering with MOS3.5
## tts2: No filtering
case_name="tts2"

egs_dir=egs2/m_ailabs/${case_name}
dataset_name=mailab
target_dataset="${share_storage}/${dataset_name}"
cd ${egs_dir}
db_name=M_AILABS
db_path=db.sh
sed -i -e "s@${db_name}.*@${db_name}=${target_dataset}@g" "${db_path}"
cat ${db_path}

# Running training
./run_byte.sh --stage 2 --stop-stage 6 \
--dumpdir "${localdir}/dump" \
--expdir "exp_nofilt" \
--ngpu 4
