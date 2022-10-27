import argparse
import subprocess

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "tsv_path", type=str, help="path to tsv fle including metadata"
    )
    parser.add_argument(
        "wav_name", type=str, help="wav file name"
    )
    args = parser.parse_args()

    line = subprocess.run(
        f'cat {args.tsv_path} | grep {args.wav_name}',
        shell=True,
        capture_output=True,
        text=True).stdout
    line = line.strip()
    text = line.split("\t")[3]
    fileterd_text = ''.join(c for c in text if c.isprintable())
    print(fileterd_text)

if __name__ == "__main__":
    main()