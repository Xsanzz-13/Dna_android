#!/usr/bin/env bash
set -Eeuo pipefail

URL="${IMAGE_URL:?Isi URL image terlebih dahulu}"
ADD_MB="${RESIZE_MB:?Isi ukuran tambahan dalam MB}"

[[ "$URL" =~ ^https?:// ]] || {
  echo "::error::URL harus diawali http:// atau https://"
  exit 1
}
[[ "$ADD_MB" =~ ^[0-9]+$ ]] && (( ADD_MB > 0 )) || {
  echo "::error::RESIZE_MB harus berupa angka positif"
  exit 1
}

mkdir -p work output
INPUT="work/input.img"
RAW="work/raw.img"
OUTPUT="output/resized.img"

echo "== Download image =="
curl -fL --retry 3 --connect-timeout 20 \
  --max-time 1800 "$URL" -o "$INPUT"

test -s "$INPUT" || {
  echo "::error::File input kosong"
  exit 1
}

echo "== Detect sparse image =="
if simg2img "$INPUT" "$RAW" 2>/dev/null; then
  echo "Android sparse image terdeteksi; dikonversi ke raw."
else
  cp "$INPUT" "$RAW"
  echo "Memakai image raw."
fi

echo "== Check ext filesystem =="
if ! file "$RAW" | grep -qi 'ext[234] filesystem'; then
  echo "::error::Image bukan filesystem ext yang dikenali. Resize dibatalkan."
  file "$RAW" || true
  exit 1
fi

echo "== Check filesystem =="
e2fsck -fn "$RAW" || {
  echo "::error::Filesystem tidak lolos pemeriksaan aman. Tidak mengubah image."
  exit 1
}

echo "== Expand image by ${ADD_MB} MiB =="
OLD_BYTES=$(stat -c %s "$RAW")
NEW_BYTES=$((OLD_BYTES + ADD_MB * 1024 * 1024))
truncate -s "$NEW_BYTES" "$RAW"

resize2fs "$RAW"

cp "$RAW" "$OUTPUT"
echo "== Output =="
ls -lh "$OUTPUT"
sha256sum "$OUTPUT"
