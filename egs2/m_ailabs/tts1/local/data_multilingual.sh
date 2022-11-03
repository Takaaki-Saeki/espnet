#!/usr/bin/env bash

set -e
set -u
set -o pipefail

log() {
    local fname=${BASH_SOURCE[1]##*/}
    echo -e "$(date '+%Y-%m-%dT%H:%M:%S') (${fname}:${BASH_LINENO[0]}:${FUNCNAME[1]}) $*"
}
SECONDS=0

log "$0 $*"
. utils/parse_options.sh

if [ $# -ne 0 ]; then
    log "Error: No positional arguments are required."
    exit 2
fi

stage=-1
stop_stage=3

. ./path.sh || exit 1
. ./cmd.sh || exit 1
. ./db.sh || exit 1

if [ -z "${M_AILABS}" ]; then
    log "Fill the value of 'JSUT' of db.sh"
    exit 1
fi
db_root=${M_AILABS}
# silence part trimming related
do_trimming=true
nj=32
do_filtering=true
# Only valid when do_filtering=true
mos_thresh="3.5"
csv_path="nisqa_results.csv"

token_type=byte

# locale all
langs=("de_DE" "en_UK" "it_IT" "es_ES" "en_US" "fr_FR" "uk_UK" "ru_RU" "pl_PL")

if [ ${stage} -le -1 ] && [ ${stop_stage} -ge -1 ]; then
    if [ -e ${db_root} ]; then
        log "The dataset already exists. Skipping..."
    else
        log "stage -1: Downloading data"
        for lang in ${langs[@]}; do
            local/download.sh ${db_root} ${lang}
        done
    fi
fi

whole_set_all=""
train_set_all=""
dev_set_all=""
eval_set_all=""

suffix=""
if [ "${token_type}" = phn ]; then
    suffix="_phn"
fi

out_all="data_all"
out="data"

if [ ${stage} -le 1 ] && [ ${stop_stage} -ge 1 ]; then
    log "stage 0-1: Data preparation and division to subsets"

    for lang in ${langs[@]}; do

        # Listing all the speakers for each locale
        if [ ${lang} = "de_DE" ]; then
            spkrs=("angela" "rebecca" "ramona" "eva" "karlsson")
            g2p="espeak_ng_german"
        elif [ ${lang} = "en_UK" ]; then
            spkrs=("elizabeth")
            g2p="g2p_en"
        elif [ ${lang} = "it_IT" ]; then
            spkrs=("lisa" "riccardo")
            g2p="espeak_ng_italian"
        elif [ ${lang} = "es_ES" ]; then
            spkrs=("karen" "tux" "victor")
            g2p="espeak_ng_spanish"
        elif [ ${lang} = "en_US" ]; then
            spkrs=("judy" "mary" "elliot")
            g2p="g2p_en"
        elif [ ${lang} = "fr_FR" ]; then
            spkrs=("ezwa" "nadine" "bernard" "gilles" "zeckou")
            g2p="espeak_ng_french"
        elif [ ${lang} = "uk_UK" ]; then
            spkrs=("sumska" "loboda" "miskun" "obruchov" "shepel")
            # Using russian g2p because phonemizer does not support uk
            g2p="espeak_ng_russian"
        elif [ ${lang} = "ru_RU" ]; then
            spkrs=("hajdurova" "minaev" "nikolaev")
            g2p="espeak_ng_russian"
        elif [ ${lang} = "pl_PL" ]; then
            spkrs=("nina" "piotr")
            g2p="espeak_ng_polish"
        else
            log "${lang} is not supported."
            exit 1
        fi

        # Preparing the dataset for each locale and speaker
        for spkr in ${spkrs[@]}; do

            # org set, and train, dev, eval sets with suffix
            org_set=${lang}_${spkr}

            log "Processing ${lang}_${spkr}."
            local/data_prep.sh ${db_root} ${lang} ${spkr} ${out_all}/${org_set}
            utils/fix_data_dir.sh ${out_all}/${org_set}
            utils/validate_data_dir.sh --no-feats ${out_all}/${org_set}

            # Trim silence parts at the beginning and the end of audio
            if ${do_trimming}; then
                log "Trimmng silence."
                scripts/audio/trim_silence.sh \
                    --cmd "${train_cmd}" \
                    --nj "${nj}" \
                    --fs 16000 \
                    --win_length 1024 \
                    --shift_length 256 \
                    --threshold 60 \
                    --min_silence 0.01 \
                    ${out_all}/${org_set} \
                    ${out_all}/${org_set}/log
            fi

            # Dump phoneme seq. because current espnet2 does not support multilingual g2p
            if [ "${token_type}" = phn ]; then
                log "pyscripts/utils/convert_text_to_phn.py"
                utils/copy_data_dir.sh "${out_all}/${org_set}" "${out_all}/${org_set}_phn"
                pyscripts/utils/convert_text_to_phn.py \
                    --g2p "${g2p}" --nj "${nj}" \
                    "${out_all}/${org_set}/text" "${out_all}/${org_set}_phn/text"
                utils/fix_data_dir.sh "${out_all}/${org_set}_phn"
            fi

            # Making train, dev, and eval subsets for each ${lang}_${spkr}
            whole_set="${org_set}${suffix}"
            train_set="${whole_set}_train"
            dev_set="${whole_set}_dev"
            eval_set="${whole_set}_eval"

            # Appending each data dir to combine them after all
            whole_set_all="${whole_set_all} ${out_all}/${whole_set}"
            train_set_all="${train_set_all} ${out_all}/${train_set}"
            dev_set_all="${dev_set_all} ${out_all}/${dev_set}"
            eval_set_all="${eval_set_all} ${out_all}/${eval_set}"

            utils/subset_data_dir.sh --last ${out_all}/${whole_set} 50 ${out_all}/${whole_set}_tmp
            utils/subset_data_dir.sh --last ${out_all}/${whole_set}_tmp 25 ${out_all}/${dev_set}
            utils/subset_data_dir.sh --first ${out_all}/${whole_set}_tmp 25 ${out_all}/${eval_set}
            n=$(($(wc -l <${out_all}/${whole_set}/wav.scp) - 50))
            utils/subset_data_dir.sh --first ${out_all}/${whole_set} ${n} ${out_all}/${train_set}
            rm -rf ${out_all}/${whole_set}_tmp

        done
    done
fi

if [ ${stage} -le 2 ] && [ ${stop_stage} -ge 2 ]; then
    log "stage 2: Combining all the languages and speakers"
    # Combining all the sets
    utils/data/combine_data.sh ${out_all}/whole${suffix} ${whole_set_all}
    utils/data/combine_data.sh ${out_all}/tr_no_dev${suffix} ${train_set_all}
    utils/data/combine_data.sh ${out_all}/dev${suffix} ${dev_set_all}
    utils/data/combine_data.sh ${out_all}/eval${suffix} ${eval_set_all}

    # Delete original filders
    rm -rf ${whole_set_all}
    rm -rf ${train_set_all}
    rm -rf ${dev_set_all}
    rm -rf ${eval_set_all}
fi

if [ ${stage} -le 3 ] && [ ${stop_stage} -ge 3 ]; then
    if ${do_trimming}; then
        log "stage 3: Filtering data based on precomputed MOS."
        python3 local/filter_data.py \
            --ref_csv_path ${csv_path} \
            --score_thresh ${mos_thresh} \
            --in_dir ${out_all} \
            --out_dir ${out}
    else
        cp -r ${out_all} ${out}
    fi
fi

log "Successfully finished. [elapsed=${SECONDS}s]"
