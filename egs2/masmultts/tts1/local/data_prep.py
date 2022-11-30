import pathlib
import argparse
import numpy as np
import os
import re
import string
from collections import defaultdict

def lang2group():
    return {
        "ast_es": "western_european_we", "bs_ba": "western_european_we", "ca_es": "western_european_we",
        "hr_hr": "western_european_we", "da_dk": "western_european_we", "nl_nl": "western_european_we",
        "en_us": "western_european_we", "en_uk": "western_european_we", "fi_fi": "western_european_we",
        "fr_fr": "western_european_we", "gl_es": "western_european_we", "de_de": "western_european_we",
        "el_gr": "western_european_we", "hu_hu": "western_european_we", "is_is": "western_european_we",
        "ga_ie": "western_european_we", "it_it": "western_european_we", "kea_cv": "western_european_we",
        "lb_lu": "western_european_we", "mt_mt": "western_european_we", "nb_no": "western_european_we",
        "oc_fr": "western_european_we", "pt_br": "western_european_we", "es_419": "western_european_we",
        "sv_se": "western_european_we", "cy_gb": "western_european_we", "hy_am": "eastern_european_ee",
        "be_by": "eastern_european_ee", "bg_bg": "eastern_european_ee", "cs_cz": "eastern_european_ee",
        "et_ee": "eastern_european_ee", "ka_ge": "eastern_european_ee", "lv_lv": "eastern_european_ee",
        "lt_lt": "eastern_european_ee", "mk_mk": "eastern_european_ee", "pl_pl": "eastern_european_ee",
        "ro_ro": "eastern_european_ee", "ru_ru": "eastern_european_ee", "sr_rs": "eastern_european_ee",
        "sk_sk": "eastern_european_ee", "sl_si": "eastern_european_ee", "uk_ua": "eastern_european_ee",
        "ar_eg": "central_asia_middle_north_african_cmn", "az_az": "central_asia_middle_north_african_cmn",
        "he_il": "central_asia_middle_north_african_cmn", "kk_kz": "central_asia_middle_north_african_cmn",
        "ky_kg": "central_asia_middle_north_african_cmn", "mn_mn": "central_asia_middle_north_african_cmn",
        "ps_af": "central_asia_middle_north_african_cmn", "fa_ir": "central_asia_middle_north_african_cmn",
        "ckb_iq": "central_asia_middle_north_african_cmn", "tg_tj": "central_asia_middle_north_african_cmn",
        "tr_tr": "central_asia_middle_north_african_cmn", "uz_uz": "central_asia_middle_north_african_cmn",
        "af_za": "sub_saharan_african_ssa", "am_et": "sub_saharan_african_ssa", "ff_sn": "sub_saharan_african_ssa",
        "lg_ug": "sub_saharan_african_ssa", "ha_ng": "sub_saharan_african_ssa", "ig_ng": "sub_saharan_african_ssa",
        "kam_ke": "sub_saharan_african_ssa", "ln_cd": "sub_saharan_african_ssa", "luo_ke": "sub_saharan_african_ssa",
        "nso_za": "sub_saharan_african_ssa", "ny_mw": "sub_saharan_african_ssa", "om_et": "sub_saharan_african_ssa",
        "sn_zw": "sub_saharan_african_ssa", "so_so": "sub_saharan_african_ssa", "sw_ke": "sub_saharan_african_ssa",
        "umb_ao": "sub_saharan_african_ssa", "wo_sn": "sub_saharan_african_ssa", "xh_za": "sub_saharan_african_ssa",
        "yo_ng": "sub_saharan_african_ssa", "zu_za": "sub_saharan_african_ssa",
        "as_in": "south_asian_sa", "bn_in": "south_asian_sa", "gu_in": "south_asian_sa", "hi_in": "south_asian_sa",
        "kn_in": "south_asian_sa", "ml_in": "south_asian_sa", "mr_in": "south_asian_sa", "ne_np": "south_asian_sa",
        "or_in": "south_asian_sa", "pa_in": "south_asian_sa", "sd_in": "south_asian_sa", "ta_in": "south_asian_sa",
        "te_in": "south_asian_sa", "ur_pk": "south_asian_sa",
        "my_mm": "south_east_asian_sea", "ceb_ph": "south_east_asian_sea", "fil_ph": "south_east_asian_sea",
        "id_id": "south_east_asian_sea", "jv_id": "south_east_asian_sea", "km_kh": "south_east_asian_sea",
        "lo_la": "south_east_asian_sea", "ms_my": "south_east_asian_sea", "mi_nz": "south_east_asian_sea",
        "th_th": "south_east_asian_sea", "vi_vn": "south_east_asian_sea",
        "cmn_hans_cn": "chinese_japanase_korean_cjk", "yue_hant_hk": "chinese_japanase_korean_cjk",
        "ja_jp": "chinese_japanase_korean_cjk", "ko_kr": "chinese_japanase_korean_cjk",
    }

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
    def __init__(self, data_type, tsv_path, token_type, mos_filtering=False, lang_set=None, lang_family=False, byte_len_filtering=False):
        self.dst_dir = pathlib.Path("data")
        self.data_type = data_type
        self.tsv_path = tsv_path
        self.token_type = token_type
        self.mos_filtering = mos_filtering
        self.mos_thresh = 2.0
        self.byte_len_thresh = 250
        self.seed = 0

        if lang_set is not None:
            with open(lang_set, "r") as fr:
                self.lang_set = [line.strip() for line in fr]
        else:
            self.lang_set = None

        if lang_family:
            self.lang2group = lang2group()
        else:
            self.lang2group = None

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
        
        self.byte_len_filtered_utt = None
        if self.byte_len_filtering:
            self.byte_len_filtered_utt = set()
            tsv_path_norm = self.tsv_path.parent / f"{self.data_name}_norm.tsv"
            with open(tsv_path_norm, "r") as fr:
                for line in fr:
                    line_list = line.strip().split("\t")
                    if len(line_list) < 5:
                        continue
                    uttid = line_list[0]
                    text = line_list[4]
                    byte_len = len(list(text.encode("utf-8")))
                    if byte_len <= self.byte_len_thresh:
                        self.byte_len_filtered_utt.add(uttid)

    def get_mos_filtered_uttids(self, utt_list):
        print(f"Filtering utterances with MOS value: {self.mos_thresh}")
        out_utt_list = [
            uttid for uttid in utt_list if uttid in self.mos_filtered_utt]
        return out_utt_list

    def get_byte_len_filtered_uttids(self, utt_list):
        print(f"Filtering utterances with byte lengths: {self.byte_len_thresh}")
        out_utt_list = [
            uttid for uttid in utt_list if uttid in self.byte_len_filtered_utt]
        return out_utt_list

    def remove_non_printable_chars(self, in_string):
        return ''.join(c for c in in_string if c.isprintable())

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
                    # Removing invalid characters
                    text = self.remove_non_printable_chars(text)
                    text = text.replace("\u3000", " ")
                    text = text.lower()
                if self.langtable is not None:
                    lang = self.langtable[lang]
                if self.lang_set is not None:
                    if lang not in self.lang_set:
                        continue
                if self.lang2group is not None:
                    lang = self.lang2group[lang]
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
            utt_list = uttids_all[setname]
            if setname == "train" and self.mos_filtering:
                utt_list = self.get_mos_filtered_uttids(utt_list)
            if setname == "train" and self.byte_len_filtering:
                utt_list = self.get_byte_len_filtered_uttids(utt_list)

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
    parser.add_argument("--token_type", required=True, type=str, choices=["byte", "tphn", "phn", "bphn"])
    parser.add_argument("--use_mailabs", action="store_true")
    parser.add_argument("--use_fleurs", action="store_true")
    parser.add_argument("--use_css10", action="store_true")
    parser.add_argument("--mos_filtering", action="store_true")
    parser.add_argument("--byte_len_filtering", action="store_true")
    parser.add_argument("--lang_family", action="store_true")
    parser.add_argument("--lang_set", default=None, type=pathlib.Path)
    args = parser.parse_args()

    data_types = []

    if args.token_type == "byte":
        suffix = "_norm"
    else:
        suffix = f"_{args.token_type}"

    if args.use_mailabs:
        print("Processing M-AILABS ...")
        tsv_path = args.db_dir / f"m_ailabs{suffix}.tsv"
        DataProcessor(
            "mailabs",
            tsv_path,
            args.token_type,
            args.mos_filtering,
            args.lang_set,
            args.lang_family).process()
        data_types.append("mailabs")
    if args.use_fleurs:
        print("Processing FLEURS ...")
        tsv_path = args.db_dir / f"fleurs{suffix}.tsv"
        DataProcessor(
            "fleurs",
            tsv_path,
            args.token_type,
            args.mos_filtering,
            args.lang_set,
            args.lang_family).process()
        data_types.append("fleurs")
    if args.use_css10:
        print("Processing CSS10 ...")
        tsv_path = args.db_dir / f"css10{suffix}.tsv"
        DataProcessor(
            "css10",
            tsv_path,
            args.token_type,
            args.mos_filtering,
            args.lang_set,
            args.lang_family).process()
        data_types.append("css10")
    
    assert len(data_types) > 0, "No data type is specified."

    print("Merging all the data ...")
    merge_data(data_types)

if __name__ == "__main__":
    main()
