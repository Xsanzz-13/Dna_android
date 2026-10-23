#!/usr/bin/env bash
set -euo pipefail

echo "=== DNA Android Tools: Linux runner ==="
for tool in git curl wget unzip zip python3 simg2img img2simg \
            lz4 zstd brotli mke2fs e2fsck resize2fs \
            mkfs.erofs fsck.erofs dtc; do
  if command -v "$tool" >/dev/null 2>&1; then
    printf '[OK]      %s: %s\n' "$tool" "$(command -v "$tool")"
  else
    printf '[MISSING] %s\n' "$tool"
  fi
done
