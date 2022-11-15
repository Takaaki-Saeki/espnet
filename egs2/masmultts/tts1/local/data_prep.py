import pathlib
import argparse
import numpy as np
import os
from collections import defaultdict

def langtable_mailabs():
    return {
        "de_DE": "de_de",
        "en_US": "en_us",
        "en_UK": "en_uk",
        "es_ES": "es_419",
        "fr_FR": "fr_fr",
        "it_IT": "it_it",
        "pl_PL": "pl_pl",
        "ru_RU": "ru_ru",
        "uk_UK": "uk_ua",
    }

def langtable_css10():
    return {
        "chinese": "cmn_hans_cn",
        "dutch": "nl_nl",
        "finnish": "fi_fi",
        "french": "fr_fr",
        "german": "de_de",
        "greek": "el_gr",
        "hungarian": "hu_hu",
        "japanese": "ja_jp",
        "russian": "ru_ru",
        "spanish": "es_419",
    }

class DataProcessor:
    def __init__(self, data_type, tsv_path, token_type, mos_filtering=False, lang_set=None):
        self.dst_dir = pathlib.Path("data")
        self.data_type = data_type
        self.tsv_path = tsv_path
        self.token_type = token_type
        self.mos_filtering = mos_filtering
        self.mos_thresh = 3.0
        self.seed = 0

        if lang_set is not None:
            with open(lang_set, "r") as fr:
                self.lang_set = [line.strip() for line in fr]
        else:
            self.lang_set = None

        if self.data_type == "mailabs":
            self.langtable = langtable_mailabs()
            self.data_name = "m_ailabs"
            self.n_dev = 25
            self.n_test = 25
        elif self.data_type == "css10":
            self.langtable = langtable_css10()
            self.data_name = "css10"
            self.n_dev = 25
            self.n_test = 25
            self.mos_filtering = False
        elif self.data_type == "fleurs":
            self.langtable = None
            self.data_name = "fleurs"
            self.n_dev = 10
            self.n_test = 10
        
        self.mos_filtered_utt = None
        if self.mos_filtering:
            self.mos_filtered_utt = set()
            mos_path = pathlib.Path(f"nisqa_results_{data_type}.csv")
            with open(mos_path, "r") as fr:
                for i, line in enumerate(fr):
                    if i == 0:
                        continue
                    line_list = line.strip().split(",")
                    uttid = line_list[0]
                    mos_val = float(line_list[1])
                    if mos_val > self.mos_thresh:
                        self.mos_filtered_utt.add(uttid)

    def get_mos_filtered_uttids(self, utt_list):
        print(f"Filtering utterances with MOS value: {self.mos_thresh}")
        out_utt_list = [
            uttid for uttid in utt_list if uttid in self.mos_filtered_utt]
        return out_utt_list

    def process(self):

        db_dir = self.tsv_path.parent

        lang2utt = defaultdict(list)
        utt2spk = {}
        utt2lang = {}
        utt2wav = {}
        utt2text = {}

        with open(self.tsv_path, "r") as fr:
            for line in fr:
                line_list = line.strip().split("\t")
                if len(line_list) != 5:
                    # Filtering out invalid data
                    continue
                if len(line_list[1].split(".")) != 2:
                    # Filtering out invalid data
                    continue
                elif line_list[1].split(".")[-1] != "wav":
                    # Filtering out invalid data
                    continue
                uttid = line_list[0]
                wavpath = db_dir / self.data_name / line_list[1]
                lang = line_list[2]
                spk = line_list[3]
                text = line_list[4]
                if self.token_type == "byte":
                    text = text.upper().replace("\u3000", " ")
                if self.langtable is not None:
                    lang = self.langtable[lang]
                if self.lang_set is not None:
                    if lang not in self.lang_set:
                        continue
                lang2utt[lang].append(uttid)
                utt2spk[uttid] = spk
                utt2lang[uttid] = lang
                utt2wav[uttid] = wavpath
                utt2text[uttid] = text

        uttids_all = {"train": [], "dev": [], "test": []}

        for lang in lang2utt.keys():
            np.random.seed(self.seed)
            rand_idx = np.random.permutation(len(lang2utt[lang]))
            train_idx = rand_idx[self.n_dev+self.n_test :]
            uttids_all["train"] += [lang2utt[lang][idx] for idx in train_idx]
            dev_idx = rand_idx[: self.n_dev]
            uttids_all["dev"] += [lang2utt[lang][idx] for idx in dev_idx]
            test_idx = rand_idx[self.n_dev : self.n_dev+self.n_test]
            uttids_all["test"] += [lang2utt[lang][idx] for idx in test_idx]
        
        for setname in ["train", "dev", "test"]:
            if setname == "train" and self.mos_filtering:
                utt_list = self.get_mos_filtered_uttids(uttids_all[setname])
            else:
                utt_list = uttids_all[setname]
            
            utt2lang_list = []
            wavscp_list = []
            utt2spk_list = []
            text_list = []
            d_spk2utt = defaultdict(list)
            for uttid in utt_list:
                utt2lang_list.append(f"{uttid} {utt2lang[uttid]}")
                wavscp_list.append(f"{uttid} {utt2wav[uttid]}")
                utt2spk_list.append(f"{uttid} {utt2spk[uttid]}")
                text_list.append(f"{uttid} {utt2text[uttid]}")
                d_spk2utt[utt2spk[uttid]].append(uttid)
            spk2utt_list = [f"{spk} {' '.join(utt_list)}" for spk, utt_list in d_spk2utt.items()]

            destination = self.dst_dir / self.data_type / setname
            os.makedirs(destination, exist_ok=True)
            with open(destination / "utt2lang", "w") as fw:
                fw.write("\n".join(utt2lang_list))
            with open(destination / "utt2spk", "w") as fw:
                fw.write("\n".join(utt2spk_list))
            with open(destination / "spk2utt", "w") as fw:
                fw.write("\n".join(spk2utt_list))
            with open(destination / "text", "w") as fw:
                fw.write("\n".join(text_list))
            with open(destination / "wav.scp", "w") as fw:
                fw.write("\n".join(wavscp_list))

def merge_data_set(data_types, setname):
    dst_dir = pathlib.Path("data")
    os.makedirs(dst_dir / setname, exist_ok=True)
    for fname in ["utt2lang", "utt2spk", "spk2utt", "text", "wav.scp"]:
        out_list = []
        for data_type in data_types:
            with open(dst_dir / data_type / setname / fname, "r") as fr:
                out_list += [line.strip() for line in fr]
        with open(dst_dir / setname / fname, "w") as fw:
            fw.write("\n".join(out_list))

def merge_data(data_types):
    for setname in ["train", "dev", "test"]:
        merge_data_set(data_types, setname)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--db_dir",required=True, type=pathlib.Path)
    parser.add_argument("--token_type", required=True, type=str, choices=["byte", "tphn"])
    parser.add_argument("--use_mailabs", action="store_true")
    parser.add_argument("--use_fleurs", action="store_true")
    parser.add_argument("--use_css10", action="store_true")
    parser.add_argument("--mos_filtering", action="store_true")
    parser.add_argument("--lang_set", default=None, type=pathlib.Path)
    args = parser.parse_args()

    data_types = []

    suffix = ""
    if args.token_type == "tphn":
        suffix = "_tphn"

    if args.use_mailabs:
        print("Processing M-AILABS ...")
        tsv_path = args.db_dir / f"m_ailabs{suffix}.tsv"
        DataProcessor(
            "mailabs",
            tsv_path,
            args.token_type,
            args.mos_filtering,
            args.lang_set).process()
        data_types.append("mailabs")
    if args.use_fleurs:
        print("Processing FLEURS ...")
        tsv_path = args.db_dir / f"fleurs{suffix}.tsv"
        DataProcessor(
            "fleurs",
            tsv_path,
            args.token_type,
            args.mos_filtering,
            args.lang_set).process()
        data_types.append("fleurs")
    if args.use_css10:
        print("Processing CSS10 ...")
        tsv_path = args.db_dir / f"css10{suffix}.tsv"
        DataProcessor(
            "css10",
            tsv_path,
            args.token_type,
            args.mos_filtering,
            args.lang_set).process()
        data_types.append("css10")
    
    assert len(data_types) > 0, "No data type is specified."

    print("Merging all the data ...")
    merge_data(data_types)

if __name__ == "__main__":
    main()
