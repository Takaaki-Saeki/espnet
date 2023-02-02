# Copyright 2021 Tomoki Hayashi
#  Apache 2.0  (http://www.apache.org/licenses/LICENSE-2.0)

"""Text encoder module in VITS.

This code is based on https://github.com/jaywalnut310/vits.

"""

import math
from typing import Tuple

import torch

from espnet2.asr.encoder.conformer_encoder import ConformerEncoder
from espnet2.asr.encoder.e_branchformer_encoder import EBranchformerEncoder
from espnet.nets.pytorch_backend.nets_utils import make_non_pad_mask


class TextEncoder(torch.nn.Module):
    """Text encoder module in VITS.

    This is a module of text encoder described in `Conditional Variational Autoencoder
    with Adversarial Learning for End-to-End Text-to-Speech`_.

    Instead of the relative positional Transformer, we use conformer architecture as
    the encoder module, which contains additional convolution layers.

    .. _`Conditional Variational Autoencoder with Adversarial Learning for End-to-End
        Text-to-Speech`: https://arxiv.org/abs/2006.04558

    """

    def __init__(
        self,
        vocabs: int,
        attention_dim: int = 192,
        attention_heads: int = 2,
        linear_units: int = 768,
        encoder_type: str = "conformer",
        blocks: int = 6,
        positionwise_layer_type: str = "conv1d",
        positionwise_conv_kernel_size: int = 3,
        positional_encoding_layer_type: str = "rel_pos",
        self_attention_layer_type: str = "rel_selfattn",
        activation_type: str = "swish",
        normalize_before: bool = True,
        use_macaron_style: bool = False,
        use_conformer_conv: bool = False,
        conformer_kernel_size: int = 7,
        dropout_rate: float = 0.1,
        positional_dropout_rate: float = 0.0,
        attention_dropout_rate: float = 0.0,
    ):
        """Initialize TextEncoder module.

        Args:
            vocabs (int): Vocabulary size.
            attention_dim (int): Attention dimension.
            attention_heads (int): Number of attention heads.
            linear_units (int): Number of linear units of positionwise layers.
            encoder_type (str): Encoder type.
            blocks (int): Number of encoder blocks.
            positionwise_layer_type (str): Positionwise layer type.
            positionwise_conv_kernel_size (int): Positionwise layer's kernel size.
            positional_encoding_layer_type (str): Positional encoding layer type.
            self_attention_layer_type (str): Self-attention layer type.
            activation_type (str): Activation function type.
            normalize_before (bool): Whether to apply LayerNorm before attention.
            use_macaron_style (bool): Whether to use macaron style components.
            use_conformer_conv (bool): Whether to use conformer conv layers.
            conformer_kernel_size (int): Conformer's conv kernel size.
            dropout_rate (float): Dropout rate.
            positional_dropout_rate (float): Dropout rate for positional encoding.
            attention_dropout_rate (float): Dropout rate for attention.

        """
        super().__init__()
        # store for forward
        self.attention_dim = attention_dim

        # define modules
        self.emb = torch.nn.Embedding(vocabs, attention_dim)
        torch.nn.init.normal_(self.emb.weight, 0.0, attention_dim**-0.5)
        if encoder_type == "conformer":
            self.encoder = ConformerEncoder(
                input_size=attention_dim,
                output_size=attention_dim,
                attention_heads=attention_heads,
                linear_units=linear_units,
                num_blocks=blocks,
                dropout_rate=dropout_rate,
                positional_dropout_rate=positional_dropout_rate,
                attention_dropout_rate=attention_dropout_rate,
                input_layer=None,
                normalize_before=normalize_before,
                concat_after=False,
                positionwise_layer_type=positionwise_layer_type,
                positionwise_conv_kernel_size=positionwise_conv_kernel_size,
                macaron_style=use_macaron_style,
                rel_pos_type="legacy",
                pos_enc_layer_type=positional_encoding_layer_type,
                selfattention_layer_type=self_attention_layer_type,
                activation_type="swish",
                use_cnn_module=use_conformer_conv,
                zero_triu=False,
                cnn_module_kernel=conformer_kernel_size,
                padding_idx=-1,
                interctc_layer_idx=[],
                interctc_use_conditioning=False,
                stochastic_depth_rate=0.0,
                layer_drop_rate=0.0,
                max_pos_emb_len=5000)
        elif encoder_type == "e_branchformer":
            self.encoder = EBranchformerEncoder(
                input_size=attention_dim,
                output_size=attention_dim,
                attention_heads=attention_heads,
                linear_units=linear_units,
                num_blocks=blocks,
                dropout_rate=dropout_rate,
                positional_dropout_rate=positional_dropout_rate,
                attention_dropout_rate=attention_dropout_rate,
                attention_layer_type=self_attention_layer_type,
                pos_enc_layer_type=positional_encoding_layer_type,
                rel_pos_type="legacy",
                cgmlp_linear_units=768,
                cgmlp_conv_kernel=7,
                use_linear_after_conv=False,
                gate_activation="identity",
                input_layer=None,
                zero_triu=False,
                padding_idx=-1,
                layer_drop_rate=0.0,
                max_pos_emb_len=5000,
                use_ffn=True,
                macaron_ffn=True if use_macaron_style else False,
                ffn_activation_type="swish",
                positionwise_layer_type=positionwise_layer_type,
                merge_conv_kernel=3)
        else:
            raise ValueError(f"{encoder_type} is not supported.")
        self.proj = torch.nn.Conv1d(attention_dim, attention_dim * 2, 1)

    def forward(
        self,
        x: torch.Tensor,
        x_lengths: torch.Tensor,
    ) -> Tuple[torch.Tensor, torch.Tensor, torch.Tensor, torch.Tensor]:
        """Calculate forward propagation.

        Args:
            x (Tensor): Input index tensor (B, T_text).
            x_lengths (Tensor): Length tensor (B,).

        Returns:
            Tensor: Encoded hidden representation (B, attention_dim, T_text).
            Tensor: Projected mean tensor (B, attention_dim, T_text).
            Tensor: Projected scale tensor (B, attention_dim, T_text).
            Tensor: Mask tensor for input tensor (B, 1, T_text).

        """
        x = self.emb(x) * math.sqrt(self.attention_dim)
        x_mask = (
            make_non_pad_mask(x_lengths)
            .to(
                device=x.device,
                dtype=x.dtype,
            )
            .unsqueeze(1)
        )
        # encoder assume the channel last (B, T_text, attention_dim)
        # but mask shape shoud be (B, 1, T_text)
        # x, _ = self.encoder(x, x_mask)
        x, _, _ = self.encoder(x, x_lengths)

        # convert the channel first (B, attention_dim, T_text)
        x = x.transpose(1, 2)
        stats = self.proj(x) * x_mask
        m, logs = stats.split(stats.size(1) // 2, dim=1)

        return x, m, logs, x_mask
