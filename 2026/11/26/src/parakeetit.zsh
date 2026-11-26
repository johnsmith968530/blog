#!/usr/bin/env zsh

# $Source: /home/x/Dropbox/2/src/blog/2026/11/26/src/RCS/parakeetit.zsh,v $
# $Date: 2026/11/26 17:01:22 $
# $Revision: 1.1 $

emulate -L zsh

PARAKEET='/mnt/git/com/github/ggml-org/whisper.cpp/build/bin/parakeet-cli'
MODEL='/mnt/h374/co/huggingface/ggml-org⁄parakeet-GGUF꞉ggml-parakeet-tdt-0.6b-v3-f32.bin/ggml-parakeet-tdt-0.6b-v3-f32.bin'

transcribe() {
    local input="${1:a}"
    local stem="${input:r}"
    local output="${stem}.txt"
    local audio="$input"
    local intermediate="${input}.whisper.wav"
    local tmpdir

    if [[ -e "$output" || -L "$output" ]]; then
        print -u2 "WARNING: Already exists: $output"
        return 0
    fi

    if [[ ! -f "$input" ]]; then
        print -u2 "ERROR: Not a regular file: $input"
        return 1
    fi

    tmpdir=$(mktemp -d "${stem}.whisper-tmp.XXXXXXXX") || return 1

    # Try native Parakeet decoding for supported audio formats.
    case "${(L)input:e}" in
        wav|mp3|flac|ogg)
            if "$PARAKEET" \
                -m "$MODEL" \
                -otxt \
                -of "$tmpdir/transcript" \
                -f "$input" &&
                [[ -f "$tmpdir/transcript.txt" ]]; then

                audio="$input"
            else
                print -u2 "WARNING: Native decoding failed; trying ffmpeg."
                rm -f -- "$tmpdir/transcript.txt"
                audio=''
            fi
            ;;
        *)
            audio=''
            ;;
    esac

    # Convert to 16 kHz, mono, signed 16-bit PCM WAV if needed.
    if [[ -z "$audio" ]]; then

        # Reuse an intermediate if it is newer than the source.
        if [[ -f "$intermediate" && -s "$intermediate" &&
              "$intermediate" -nt "$input" ]]; then
            print "Reusing: $intermediate"
        else
            # Never overwrite an existing intermediate.
            if [[ -e "$intermediate" || -L "$intermediate" ]]; then
                intermediate=$(mktemp --suffix=.wav \
                    "${input}.whisper.XXXXXXXX") || {
                    rm -rf -- "$tmpdir"
                    return 1
                }
            fi

            print "Converting: $input -> $intermediate"

            if ! ffmpeg -nostdin -hide_banner -loglevel error -y \
                -i "$input" \
                -map 0:a:0 \
                -vn \
                -ar 16000 \
                -ac 1 \
                -c:a pcm_s16le \
                "$tmpdir/audio.wav"; then

                print -u2 "ERROR: Conversion failed: $input"
                rm -rf -- "$tmpdir"
                return 1
            fi

            if ! mv -f -- "$tmpdir/audio.wav" "$intermediate"; then
                rm -rf -- "$tmpdir"
                return 1
            fi
        fi

        audio="$intermediate"

        if ! "$PARAKEET" \
            -m "$MODEL" \
            -l auto \
            -otxt \
            -of "$tmpdir/transcript" \
            -f "$audio"; then

            print -u2 "ERROR: Transcription failed: $input"
            rm -rf -- "$tmpdir"
            return 1
        fi
    fi

    # Publish the completed transcript without overwriting anything.
    if [[ ! -f "$tmpdir/transcript.txt" ]]; then
        print -u2 "ERROR: Parakeet produced no transcript: $input"
        rm -rf -- "$tmpdir"
        return 1
    fi

    if ! ln -- "$tmpdir/transcript.txt" "$output"; then
        print -u2 "ERROR: Could not create: $output"
        rm -rf -- "$tmpdir"
        return 1
    fi

    rm -rf -- "$tmpdir"
    print "Created: $output"
}

if (( $# == 0 )); then
    print -u2 "Usage: ${0:t} FILE [FILE ...]"
    exit 1
fi

if [[ ! -x "$PARAKEET" || ! -r "$MODEL" ]]; then
    print -u2 "ERROR: Parakeet executable or model unavailable."
    exit 1
fi

integer failures=0

for input in "$@"; do
    transcribe "$input" || (( failures += 1 ))
done

if (( failures > 0 )); then
    print -u2 "WARNING: $failures file(s) failed."
    exit 1
fi

exit 0

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
