import os
import numpy as np

try:
    import tensorflow  # required in Colab to avoid protobuf compatibility issues
except ImportError:
    pass

import torch
import pandas as pd
import pathlib
import whisper
import torchaudio
import argparse
import jiwer
from whisper.normalizers import BasicTextNormalizer

from tqdm.notebook import tqdm

DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

class EvalSet(torch.utils.data.Dataset):
    """
    A simple class to wrap LibriSpeech and trim/pad the audio to 30 seconds.
    It will drop the last few seconds of a very small portion of the utterances.
    """
    def __init__(self, wavpaths, data_dir, device=DEVICE):
        self.wavpaths = wavpaths
        self.data_dir = data_dir
        self.device = device
        self.utt2lang = {}
        with open(data_dir / "utt2lang", "r") as fr:
            for line in fr:
                uttid, lang = line.strip().split()
                self.utt2lang[uttid] = lang
        self.utt2text = {}
        with open(data_dir / "text", "r") as fr:
            for line in fr:
                uttid, text = line.strip().split(maxsplit=1)
                self.utt2text[uttid] = text

    def __len__(self):
        return len(self.wavpaths)

    def __getitem__(self, item):
        audio, sr = torchaudio.load(self.wavpaths[item])
        assert sr == 16000
        uttid = self.wavpaths[item].stem
        lang = self.utt2lang[uttid].split("_")[0]
        text = self.utt2text[uttid]
        audio = whisper.pad_or_trim(audio.flatten()).to(self.device)
        mel = whisper.log_mel_spectrogram(audio)
        return (mel, text, lang)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--decode_dir",required=True, type=pathlib.Path)
    parser.add_argument("--data_dir",required=True, type=pathlib.Path)
    parser.add_argument("--setname", default="test", type=str)
    args = parser.parse_args()

    wav_dir = args.decode_dir / args.setname / "wav"
    data_dir = args.data_dir / args.setname
    wavpaths = wav_dir.glob("*.wav")

    dataset = EvalSet(wavpaths, data_dir, DEVICE)

    # Only allowing batchsize: 1 for now
    loader = torch.utils.data.DataLoader(dataset, batch_size=1)

    model = whisper.load_model("base")
    print(
        f"Model is {'multilingual' if model.is_multilingual else 'English-only'} "
        f"and has {sum(np.prod(p.shape) for p in model.parameters()):,} parameters."
    )

    hypotheses = []
    references = []

    for mels, texts, langs in tqdm(loader):
        options = whisper.DecodingOptions(language=langs, without_timestamps=True)
        results = model.decode(mels, options)
        hypotheses.extend([result.text for result in results])
        references.extend(texts)
    
    normalizer = BasicTextNormalizer()

    data["hypothesis_clean"] = [normalizer(text) for text in data["hypothesis"]]
    data["reference_clean"] = [normalizer(text) for text in data["reference"]]
    
    data = pd.DataFrame(dict(hypothesis=hypotheses, reference=references))
    wer = jiwer.wer(list(data["reference_clean"]), list(data["hypothesis_clean"]))
    cer = jiwer.cer(list(data["reference_clean"]), list(data["hypothesis_clean"]))

    print(f"WER: {wer * 100:.2f} %")
    print(f"CER: {cer * 100:.2f} %")


if __name__ == "__main__":
    main()