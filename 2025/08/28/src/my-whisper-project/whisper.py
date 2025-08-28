# $Source: /Users/x/Dropbox/2/src/blog/2025/08/28/src/my-whisper-project/RCS/whisper.py,v $
# $Date: 2025/08/28 15:18:08 $
# $Revision: 1.3 $

# uv init
# uv add mlx-whisper
# uv run python whisper.py my_input_file.mp3

import mlx_whisper
import os
import sys

for speech_file in sys.argv[1:]:
    base_name = os.path.splitext(speech_file)[0]
    output_file = f"{base_name}.txt"
    print(f"{speech_file} ↦ {output_file}")

    # Model will be cached in
    #
    # ~/.cache/huggingface/hub/models--mlx-community--whisper-large-v3-mlx
    #
    result = mlx_whisper.transcribe(
      speech_file,
      path_or_hf_repo='mlx-community/whisper-large-v3-mlx')

    with open(output_file, 'w') as fh1:
      fh1.write(result['text'])

# vim: set et ff=unix ft=python nocp sts=4 sw=4 ts=4:
