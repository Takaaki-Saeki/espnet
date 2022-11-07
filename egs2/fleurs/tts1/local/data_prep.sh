#!/usr/bin/env bash

log() {
    local fname=${BASH_SOURCE[1]##*/}
    echo -e "$(date '+%Y-%m-%dT%H:%M:%S') (${fname}:${BASH_LINENO[0]}:${FUNCNAME[1]}) $*"
}

if [ "$#" -ne 6 ]; then
  echo "Usage: $0 <src-dir> <dst> <lang_filtering> <lang_filtreing_top> <mos_filtering> <mos_filtering_thresh>"
  echo "e.g.: $0 /downloads/fleurs data/dev"
  exit 1
fi

src=$1 # dir path to dataset
dst=$2 # destination (e.g., data/dev)
setname=`basename ${dst}` # train, dev, test

spk_label_dir=spk_label

# Performing language filtering
langs=""
if [ "$3" = true ]; then
  lang_filt=true
  while IFS=',' read -ra array; do
    langs_all+=("${array[0]}")
  done < csv/mean_mos_langs.csv
  if [ ! -f "csv/mean_mos_langs.csv" ]; then
    log "Error: csv/mean_mos_langs.csv does not exist."
    exit 1
  fi
  cnt=0
  while [[ $cnt -lt $4 ]]; do
    langs+=("${langs_all[cnt]}")
    cnt=$((cnt+1))
  done
  log "Language list: ${langs[@]}"
else
  lang_filt=false
fi

# Performing MOS filtering
if [ "$5" = true ] && [ "${setname}" = "train" ]; then
  log "Enabling MOS filtering."
  mos_filt=true
  mos_filt_thresh=$6
  mos_filt_thresh=${mos_filt_thresh//./}
else
  log "Disabling MOS filtering."
  mos_filt=false
fi

[ ! -d $src ] && log "$0: no such directory $src" && exit 1
[ ! -f $spk_file ] && log "$0: expected file $spk_file to exist" && exit 1

# check if the source data is already prepared
if [ -e ${dst} ]; then
  log "${dst} already exists. Skipping."
else
  mkdir -p $dst || exit 1
  
  wav_scp=$dst/wav.scp; [[ -f "$wav_scp" ]] && rm $wav_scp
  trans=$dst/text; [[ -f "$trans" ]] && rm $trans
  utt2spk=$dst/utt2spk; [[ -f "$utt2spk" ]] && rm $utt2spk
  utt2lang=$dst/utt2lang; [[ -f "$utt2lang" ]] && rm $utt2lang

  for lang_dir in $(find -L $src -mindepth 1 -maxdepth 1 -type d | sort); do
    lang=`basename $lang_dir`
    tsv_path=$lang_dir/${setname}.tsv
    audio_dir=$lang_dir/audio/${setname}
    # Language filtering
    if [ "$lang_filt" = true ]; then
      if [[ " ${langs[@]} " =~ " ${lang} " ]]; then
        log "Language filtering: ${lang} is in the list of languages."
      else
        continue
      fi
    fi
    # MOS filtering
    if [ "$mos_filt" = true ]; then
      csv_path="csv/${lang}_mos${mos_filt_thresh}.csv"
      if [ -f "$csv_path" ]; then
        log "Loading a MOS csv file ${csv_path}."
      else
        log "MOS filtering: ${lang} does not have a MOS csv file."
        exit 1
      fi
    fi
    [ ! -f $tsv_path ] && echo "$0: expected file $tsv_path to exist" && exit 1
    [ ! -d $audio_dir ] && echo "$0: expected directory $audio_dir to exist" && exit 1
    log "Processing ${lang}, ${setname} set ..."
    find -L $audio_dir/ -iname "*.wav" | sort | while read -r wav_file; do
      base=`basename $wav_file`
      id=$(basename $wav_file .wav)
      spk=`grep "$id" "$spk_label_dir/${lang}/utt2spk"| awk '{ print $2 }'`
      uttid="${spk}_${id}"
      if [ "$mos_filt" = false ]; then
        echo "$uttid $wav_file" >>$wav_scp
        txt=`python3 local/extract.py ${tsv_path} ${base}`
        echo "$uttid $txt" >>$trans
        echo "$uttid $spk" >>$utt2spk
        echo "$uttid $lang" >>$utt2lang
      elif [ "$(grep ${id}.wav ${csv_path})" != "" ]; then
        echo "$uttid $wav_file" >>$wav_scp
        txt=`python3 local/extract.py ${tsv_path} ${base}`
        echo "$uttid $txt" >>$trans
        echo "$uttid $spk" >>$utt2spk
        echo "$uttid $lang" >>$utt2lang
      fi
    done
  done
  #sort -o $utt2spk $utt2spk -k2

  spk2utt=$dst/spk2utt
  utils/utt2spk_to_spk2utt.pl <$utt2spk >$spk2utt || exit 1
  ntrans=$(wc -l <$trans)
  nutt2spk=$(wc -l <$utt2spk)
  ! [ "$ntrans" -eq "$nutt2spk" ] && \
    echo "Inconsistent #transcripts($ntrans) and #utt2spk($nutt2spk)" && exit 1
fi

utils/fix_data_dir.sh $dst || exit 1

utils/validate_data_dir.sh --no-feats $dst || exit 1

echo "$0: successfully prepared data in $dst"

exit 0
