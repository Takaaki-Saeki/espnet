import pathlib
import argparse
from collections import defaultdict

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--in_csv",required=True, type=pathlib.Path)
    parser.add_argument("--lang_set",required=True, type=pathlib.Path)
    args = parser.parse_args()

    with open(args.lang_set, "r") as fr:
        lang_set = [x.strip().split("_")[0] for x in fr]
    lang_set = set(lang_set)

    print(f"language set: {lang_set}")

    lang2scores = defaultdict(float)
    lang2scores_gt = defaultdict(float)
    print(f"Processing {str(args.in_csv)} ...")
    with open(args.in_csv, "r") as fr:
        for i, line in enumerate(fr):
            if i == 0:
                continue
            else:
                values = line.strip().split()
            if len(values) == 3:
                lang, _, cer = values
                if lang in lang_set:
                    lang2scores[lang] = float(cer.strip("%"))
            if len(values) == 5:
                lang, _, cer, _, cer_gt = values
                if lang in lang_set:
                    lang2scores[lang] = float(cer.strip("%"))
                    lang2scores_gt[lang] = float(cer_gt.strip("%"))
    
    out_synth = []
    out_gt = []
    for lang in lang2scores:
        out_synth.append(lang2scores[lang])
        if lang in lang2scores_gt:
            out_gt.append(lang2scores_gt[lang])
    
    print(f"Synthesized: {sum(out_synth)/len(out_synth)}")
    if len(out_gt) > 0:
        print(f"Ground truth: {sum(out_gt)/len(out_gt)}")
            
            

            
            

if __name__ == "__main__":
    main()