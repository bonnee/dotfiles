#!/bin/bash

VIDEO_DIR="BDMV/STREAM"
OUTPUT_DIR="conv"

mkdir -p "$OUTPUT_DIR"

for m2ts_file in "$VIDEO_DIR"/*.m2ts; do
    base=$(basename "$m2ts_file" .m2ts)
    output_file="$OUTPUT_DIR/$base.mp4"

    echo "------------------------------------------------"
    echo "Processing: $base"

    # 1. Lossless Remux
    # Video is untouched, Audio is converted to AAC for maximum device support
    ffmpeg -i "$m2ts_file" -c copy "$output_file" -y -loglevel error

    # 2. Total Metadata Injection
    # -ee: Deep scan of the stream packets
    # -all:all: Copy every single tag found
    # -time:all: Ensure all time-related tags are prioritized
    # -api LargeFileSupport=1: Handles files over 4GB
    echo "Transferring all metadata tags..."
    exiftool -ee -api LargeFileSupport=1 -tagsfromfile "$m2ts_file" \
    "-all:all" \
    "-time:all" \
    "-FileModifyDate<DateTimeOriginal" \
    "$output_file" -overwrite_original

    echo "Done with $base"
done

echo "------------------------------------------------"
echo "Full Archive Processed!"
