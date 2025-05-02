#!/bin/bash

# Usage check
if [ $# -ne 1 ]; then
  echo "Usage: $0 <video_file_or_directory>"
  exit 1
fi

convert_file() {
  input_file="$1"
  extension="${input_file##*.}"
  filename="${input_file%.*}"

  case "$extension" in
    mp4|MP4)
      output_file="${filename}.mov"
      ffmpeg -y -i "$input_file" \
        -vcodec mjpeg -q:v 2 \
        -acodec pcm_s16be -q:a 0 \
        -f mov "$output_file"
      ;;
    mov|MOV)
      output_file="${filename}.mp4"
      ffmpeg -y -i "$input_file" \
        -vf scale=in_range=full:out_range=tv \
        -c:v libx264 -pix_fmt yuv420p -r 30 \
        -c:a aac -movflags +faststart \
        "$output_file"
      ;;
    *)
      echo "Skipped (unsupported extension): $input_file"
      return
      ;;
  esac

  if [ $? -eq 0 ]; then
    echo "✅ Success: $output_file"
  else
    echo "❌ Failed to convert: $input_file"
  fi
}

# Main logic
if [ -f "$1" ]; then
  convert_file "$1"

elif [ -d "$1" ]; then
  export -f convert_file
  find "$1" -type f \( -iname "*.mp4" -o -iname "*.mov" \) -print0 |
    xargs -0 -n 1 bash -c 'convert_file "$0"' 
else
  echo "Error: $1 is not a valid file or directory"
  exit 1
fi

