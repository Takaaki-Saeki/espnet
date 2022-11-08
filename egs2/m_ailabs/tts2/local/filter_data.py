import pathlib
import argparse
import os

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--ref_csv_path",
        type=pathlib.Path)
    parser.add_argument("--score_thresh", type=float)
    parser.add_argument("--in_dir", type=pathlib.Path)
    parser.add_argument("--out_dir", type=pathlib.Path)
    args = parser.parse_args()

    # names of directories to be filtered
    names = ["tr_no_dev", "dev", "eval", "whole"]

    # Making dictionary of utt_id and score
    utt2score = {}
    with open(args.ref_csv_path, "r") as fr:
        for i, line in enumerate(fr):
            if i == 0:
                continue
            utt_id, score = line.strip().split(",")[:2]
            utt2score[utt_id] = float(score)
    
    utt2stem = {}

    for name in names:
        dirpath = args.in_dir / name
        out_dirpath = args.out_dir / name
        os.makedirs(out_dirpath, exist_ok=True)
        
        # wav.scp
        out_wavs = []
        with open(dirpath / "wav.scp", "r") as fr:
            for line in fr:
                if line.strip() == "":
                    continue
                utt_id = line.strip().split()[0]
                filepath = line.strip().split()[1]
                stem = pathlib.Path(filepath).stem
                utt2stem[utt_id] = stem
                try:
                    if utt2score[stem] > args.score_thresh:
                        out_wavs.append(line)
                except KeyError:
                    print(f"Skipping {stem} because it is not in the reference csv file.")
        with open(out_dirpath / "wav.scp", "w") as fw:
            fw.write("".join(out_wavs))
        
        # utt2spk
        out_utt2spk = []
        with open(dirpath / "utt2spk", "r") as fr:
            for line in fr:
                if line.strip() == "":
                    continue
                utt_id = line.strip().split()[0]
                stem = utt2stem[utt_id]
                try:
                    if utt2score[stem] > args.score_thresh:
                        out_utt2spk.append(line)
                except KeyError:
                    print(f"Skipping {stem} because it is not in the reference csv file.")
        with open(out_dirpath / "utt2spk", "w") as fw:
            fw.write("".join(out_utt2spk))
        
        # segments
        out_segments = []
        with open(dirpath / "segments", "r") as fr:
            for line in fr:
                if line.strip() == "":
                    continue
                utt_id = line.strip().split()[0]
                stem = utt2stem[utt_id]
                try:
                    if utt2score[stem] > args.score_thresh:
                        out_segments.append(line)
                except KeyError:
                    print(f"Skipping {stem} because it is not in the reference csv file.")
        with open(out_dirpath / "segments", "w") as fw:
            fw.write("".join(out_segments))
        
        # spk2utt
        out_spk2utt = []
        with open(dirpath / "spk2utt", "r") as fr:
            for line in fr:
                if line.strip() == "":
                    continue
                utts = line.strip().split()
                spk = utts[0]
                out_utts = [spk]
                for utt in utts[1:]:
                    stem = utt2stem[utt]
                    try:
                        if utt2score[stem] > args.score_thresh:
                            out_utts.append(utt)
                    except KeyError:
                        print(f"Skipping {stem} because it is not in the reference csv file.")
                out_line = " ".join(out_utts)
                out_spk2utt.append(out_line)
        with open(out_dirpath / "spk2utt", "w") as fw:
            fw.write("\n".join(out_spk2utt))

        # utt2lang
        out_utt2lang = []
        with open(dirpath / "utt2lang", "r") as fr:
            for line in fr:
                if line.strip() == "":
                    continue
                utt_id = line.strip().split()[0]
                stem = utt2stem[utt_id]
                try:
                    if utt2score[stem] > args.score_thresh:
                        out_utt2lang.append(line)
                except KeyError:
                    print(f"Skipping {stem} because it is not in the reference csv file.")
        with open(out_dirpath / "utt2lang", "w") as fw:
            fw.write("".join(out_utt2lang))

        # text
        out_texts = []
        with open(dirpath / "text", "r") as fr:
            for line in fr:
                if line.strip() == "":
                    continue
                utt_id = line.strip().split()[0]
                stem = utt2stem[utt_id]
                try:
                    if utt2score[stem] > args.score_thresh:
                        out_texts.append(line)
                except KeyError:
                    print(f"Skipping {stem} because it is not in the reference csv file.")
        with open(out_dirpath / "text", "w") as fw:
            fw.write("".join(out_texts))

if __name__ == "__main__":
    main()