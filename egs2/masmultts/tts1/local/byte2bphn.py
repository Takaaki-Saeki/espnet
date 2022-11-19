import pathlib
import argparse
import tqdm
from transphone.g2p import read_g2p
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

def get_p2p(lang2code):
    from phonepiece import read_inventory
    d_phone2phoneme = {}    
    d_phoneme2phone = {}
    for key in lang2code.keys():
        lcode = lang2code[key]
        inv = read_inventory(lcode)
        phone2phoneme = inv.phone2phoneme
        d_phone2phoneme[lcode] = phone2phoneme
        phoneme2phone = defaultdict(list)
        for key in phone2phoneme.keys():
            phonemes = phone2phoneme[key]
            for phoneme in phonemes:
                phoneme2phone[phoneme].append(key)
        d_phoneme2phone[lcode] = phoneme2phone
    return d_phone2phoneme, d_phoneme2phone

def main():
    lang_table_path = pathlib.Path(__file__).parent / "lang_table.csv"

    parser = argparse.ArgumentParser()
    parser.add_argument("--in_tsv",required=True, type=pathlib.Path)
    parser.add_argument("--data_type",required=True, type=str, choices=["mailabs", "css10", "fleurs"])
    args = parser.parse_args()

    model = read_g2p()

    lang2code = {}
    with open(lang_table_path, "r") as fr:
        for line in fr:
            line_list = line.strip().split()
            lang2code[line_list[0]] = line_list[1]

    with open(args.in_tsv, "r") as fr:
        in_list = [line.strip() for line in fr]

    out_list_tphn = []
    out_list_bphn = []
    for line in tqdm.tqdm(in_list):
        line_list = line.strip().split("\t")
        uttid = line_list[0]
        wavpath = line_list[1]
        lang = line_list[2]
        if args.data_type == "mailabs":
            lang = langtable_mailabs()[lang]
        elif args.data_type == "css10":
            lang = langtable_css10()[lang]
        spk = line_list[3]
        text = line_list[4]
        lcode = lang2code[lang]
        words = text.strip().split()
        out_tphn = []
        out_bphn = []
        for word in words:
            byte = [str(x) for x in list(text.encode("utf-8"))]
            out_bphn += byte
            # adding boundary token for byte and tphn
            out_bphn.append("<bnd>")
            tphn = model.inference_word(word, lcode)
            out_bphn += tphn
            out_bphn.append("<space>")
            out_tphn.append("".join(tphn))
        out_bphn = out_bphn[:-1]
        bphn_text = " ".join(out_bphn)
        tphn_text = " ".join(out_tphn)
        out_line_list_bphn = [uttid, wavpath, lang, spk, bphn_text]
        out_line_list_tphn = [uttid, wavpath, lang, spk, tphn_text]
        out_list_bphn.append("\t".join(out_line_list_bphn))
        out_list_tphn.append("\t".join(out_line_list_tphn))

    out_name_bphn = args.in_tsv.stem.strip().rsplit("_", maxsplit=1)[0] + "_bphn.tsv"
    out_name_tphn = args.in_tsv.stem.strip().rsplit("_", maxsplit=1)[0] + "_tphn.tsv"

    with open(out_name_bphn, "w") as fw:
        fw.write("\n".join(out_list_bphn))
    with open(out_name_tphn, "w") as fw:
        fw.write("\n".join(out_list_tphn))

if __name__ == "__main__":
    main()