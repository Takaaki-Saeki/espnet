import pathlib
import argparse
import tqdm
from transphone import read_tokenizer
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
        phoneme2phone = inv.phoneme2phone
        d_phone2phoneme[lcode] = phone2phoneme
        d_phoneme2phone[lcode] = phoneme2phone
    return d_phone2phoneme, d_phoneme2phone

def main():
    lang_table_path = pathlib.Path(__file__).parent / "lang_table.csv"

    parser = argparse.ArgumentParser()
    parser.add_argument("--in_tsv",required=True, type=pathlib.Path)
    parser.add_argument("--data_type",required=True, type=str, choices=["mailabs", "css10", "fleurs"])
    args = parser.parse_args()

    lang2code = {}
    with open(lang_table_path, "r") as fr:
        for line in fr:
            line_list = line.strip().split()
            lang2code[line_list[0]] = line_list[1]

    with open(args.in_tsv, "r") as fr:
        in_list = [line.strip() for line in fr]

    out_names = {}
    for name in ["phn", "tphn", "bphn", "btphn"]:
        out_names[name] = args.in_tsv.stem.strip().rsplit("_", maxsplit=1)[0] + f"_{name}.tsv"
        with open(out_names[name], "w") as fw:
            pass

    _, phoneme2phone = get_p2p(lang2code)

    for line in tqdm.tqdm(in_list):
        line_list = line.strip().split("\t")
        if len(line_list) < 5:
            # Filtering out lines with less than 5 columns
            continue
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

        tokenizer = read_tokenizer(lcode)
        
        out_list = {}
        for name in ["phn", "tphn", "bphn", "btphn"]:
            out_list[name] = []

        for word in words:
            byte = [str(x) for x in list(text.encode("utf-8"))]
            out_list["bphn"] += byte
            out_list["btphn"] += byte
            # adding boundary token for byte and tphn
            out_list["bphn"].append("<bnd>")
            out_list["btphn"].append("<bnd>")
            tphn = tokenizer.tokenize(word)
            # Ignoring unknown in phoneme2phone
            phn = [phoneme2phone[lcode][w][0] for w in tphn if w in phoneme2phone[lcode]]
            out_list["bphn"] += phn
            out_list["bphn"].append("<space>")
            out_list["btphn"] += tphn
            out_list["btphn"].append("<space>")
            out_list["phn"].append("".join(phn).strip())
            out_list["tphn"].append("".join(tphn).strip())
        out_list["bphn"] = out_list["bphn"][:-1]
        out_list["btphn"] = out_list["btphn"][:-1]
        for name in ["phn", "tphn", "bphn", "btphn"]:
            processed_text = " ".join(out_list[name])
            out_line_list = [uttid, wavpath, lang, spk, processed_text]

            with open(out_names[name], "a") as fw:
                fw.write("\t".join(out_line_list))
                fw.write("\n")

if __name__ == "__main__":
    main()