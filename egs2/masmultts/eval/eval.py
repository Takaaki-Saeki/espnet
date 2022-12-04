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

import tqdm

DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

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

class EvalSet(torch.utils.data.Dataset):
    """
    A simple class to wrap LibriSpeech and trim/pad the audio to 30 seconds.
    It will drop the last few seconds of a very small portion of the utterances.
    """
    def __init__(
        self,
        wavpaths,
        data_dir,
        setname="test",
        device=DEVICE,
        calc_gt=False,
        is_family=False,
        db_dir=None):

        self.wavpaths = wavpaths
        self.data_dir = data_dir
        self.device = device

        self.utt2text = {}
        with open(data_dir/ setname / "text", "r") as fr:
            for line in fr:
                uttid, text = line.strip().split(maxsplit=1)
                self.utt2text[uttid] = text

        corpus_wavpaths = list(data_dir.glob(f"*/{setname}/wav.scp"))
        self.utt2corpus = {}
        self.utt2gtwav = {}
        for cp in corpus_wavpaths:
            with open(cp, "r") as fr:
                for line in fr:
                    uttid = line.strip().split()[0]
                    gtwav = line.strip().split()[1]
                    self.utt2gtwav[uttid] = gtwav
                    if cp.parent.parent.name == "mailabs":
                        self.utt2corpus[uttid] = "m_ailabs"
                    elif cp.parent.parent.name == "css10":
                        self.utt2corpus[uttid] = "css10"
                    elif cp.parent.parent.name == "fleurs":
                        self.utt2corpus[uttid] = "fleurs"
                    else:
                        raise ValueError(f"Unknown corpus {cp.parent.parent.name}")

        self.utt2lang = {}
        if is_family:
            assert db_dir is not None
            for uttid in self.utt2corpus:
                corpus = self.utt2corpus[uttid]
                tsv_path = db_dir / f"{corpus}_norm.tsv"
                with open(tsv_path, "r") as fr:
                    for line in fr:
                        line_list = line.strip().split("\t")
                        lang = line_list[2]
                        if corpus == "m_ailabs":
                            lang = langtable_mailabs()[lang]
                        elif corpus == "css10":
                            lang = langtable_css10()[lang]
                        self.utt2lang[line_list[0]] = lang
        else:
            with open(data_dir / setname / "utt2lang", "r") as fr:
                for line in fr:
                    uttid, lang = line.strip().split()
                    self.utt2lang[uttid] = lang

        self.lang_all = list(set([x.split("_")[0] for x in self.utt2lang.values()]))
        self.calc_gt = calc_gt

    def __len__(self):
        return len(self.wavpaths)

    def __getitem__(self, item):
        audio, sr = torchaudio.load(self.wavpaths[item])
        assert sr == 16000
        uttid = self.wavpaths[item].stem
        lang = self.utt2lang[uttid].split("_")[0]
        corpus = self.utt2corpus[uttid]
        text = self.utt2text[uttid]
        audio = whisper.pad_or_trim(audio.flatten()).to(self.device)
        mel = whisper.log_mel_spectrogram(audio)
        out = (mel, text, lang, corpus)
        if self.calc_gt:
            audio_gt, sr_gt = torchaudio.load(self.utt2gtwav[uttid])
            if sr_gt != sr:
                print(f"Skipping uttid: {uttid} because sr_gt != sr")
                return (mel, text, lang, corpus, "BREAK")
            audio_gt = whisper.pad_or_trim(audio_gt.flatten()).to(self.device)
            mel_gt = whisper.log_mel_spectrogram(audio_gt)
            out = (mel, text, lang, corpus, mel_gt)
        return out

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--decode_dir",required=True, type=pathlib.Path)
    parser.add_argument("--data_dir",required=True, type=pathlib.Path)
    parser.add_argument("--setname", default="test", type=str)
    parser.add_argument("--case_name", required=True, type=str)
    parser.add_argument("--is_family", action="store_true")
    parser.add_argument("--db_dir", required=False, type=pathlib.Path, default=None)
    parser.add_argument("--calc_gt", action="store_true")
    args = parser.parse_args()

    print(f"Case name: {args.case_name}")
    result_dir = pathlib.Path("results")
    os.makedirs(result_dir, exist_ok=True)

    wav_dir = args.decode_dir / args.setname / "wav"
    wavpaths = list(wav_dir.glob("*.wav"))

    dataset = EvalSet(
        wavpaths,
        args.data_dir,
        args.setname,
        DEVICE,
        calc_gt=args.calc_gt,
        is_family=args.is_family,
        db_dir=args.db_dir
    )
    lang_all = dataset.lang_all

    # Only allowing batchsize: 1 for now
    loader = torch.utils.data.DataLoader(dataset, batch_size=1)

    model = whisper.load_model("base")
    print(
        f"Model is {'multilingual' if model.is_multilingual else 'English-only'} "
        f"and has {sum(np.prod(p.shape) for p in model.parameters()):,} parameters."
    )

    hypotheses = {}
    references = {}
    if args.calc_gt:
        hypotheses_gt = {}
    for lang in lang_all:
        hypotheses[lang] = []
        references[lang] = []
        if args.calc_gt:
            hypotheses_gt[lang] = []
    
    lang_supported = set()

    for batch in tqdm.tqdm(loader):
        if batch[-1] == "BREAK":
            continue
        if args.calc_gt:
            mels, texts, langs, corpora, mels_gt = batch
        else:
            mels, texts, langs, corpora = batch
        lang = langs[0]
        corpus = corpora[0]
        try:
            options = whisper.DecodingOptions(language=lang, without_timestamps=True)
            results = model.decode(mels, options)
            lang_supported.add(lang)
            hypotheses[lang].extend([result.text for result in results])
            references[lang].extend(texts)
            if args.calc_gt:
                options_gt = whisper.DecodingOptions(language=lang, without_timestamps=True)
                results_gt = model.decode(mels_gt, options_gt)
                hypotheses_gt[lang].extend([result.text for result in results_gt])
        except ValueError:
            continue
    
    normalizer = BasicTextNormalizer()

    if args.calc_gt:
        out_list = [" ".join(["lang", "wer", "cer", "wer_gt", "cer_gt"])]
    else:
        out_list = [" ".join(["lang", "wer", "cer"])]

    for lang in lang_all:
        if lang not in lang_supported:
            print(f"{lang} is not supported by whisper!")

    lang_supported = list(lang_supported)

    for lang in lang_supported:

        try:
            data_dict = dict(hypothesis=hypotheses[lang], reference=references[lang])
            if args.calc_gt:
                data_dict.update(hypothesis_gt=hypotheses_gt[lang])
            data = pd.DataFrame(data_dict)
            data["hypothesis_clean"] = [normalizer(text) for text in data["hypothesis"]]
            data["reference_clean"] = [normalizer(text) for text in data["reference"]]
            wer = jiwer.wer(list(data["reference_clean"]), list(data["hypothesis_clean"]))
            cer = jiwer.cer(list(data["reference_clean"]), list(data["hypothesis_clean"]))
            if args.calc_gt:
                data["hypothesis_gt_clean"] = [normalizer(text) for text in data["hypothesis_gt"]]
                wer_gt = jiwer.wer(list(data["reference_clean"]), list(data["hypothesis_gt_clean"]))
                cer_gt = jiwer.cer(list(data["reference_clean"]), list(data["hypothesis_gt_clean"]))
                out_list.append(" ".join([f"{lang}", f"{wer:.2%}", f"{cer:.2%}", f"{wer_gt:.2%}", f"{cer_gt:.2%}"]))
            else:
                out_list.append(" ".join([f"{lang}", f"{wer:.2%}", f"{cer:.2%}"]))
        except:
            print(f"{lang} has not been properly processed!")
            
    with open(result_dir / f"{args.case_name}.csv", "w") as fw:
        fw.write("\n".join(out_list))

if __name__ == "__main__":
    main()