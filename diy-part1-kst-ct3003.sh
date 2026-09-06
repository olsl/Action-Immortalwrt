#!/bin/bash
# DIY part 1 for KST WF3000A — based on cetron CT3003 template
# Source: olsl/immortalwrt-mt798x-6.6, 2410 branch, 5.4 kernel

# 1. Override DTS with ct3003-based version
cp $GITHUB_WORKSPACE/mt7981-kst-wf3000a.dts \
   target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/mt7981-kst-wf3000a.dts

# 2. Remove existing kst_wf3000a definition, re-add based on cetron_ct3003
sed -i '/define Device\/kst_wf3000a/,/TARGET_DEVICES += kst_wf3000a/d' \
   target/linux/mediatek/image/mt7981.mk

cat >> target/linux/mediatek/image/mt7981.mk <<'EOF'

define Device/kst_wf3000a
  DEVICE_VENDOR := KST
  DEVICE_MODEL := WF3000A
  DEVICE_DTS := mt7981-kst-wf3000a
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := kst,wf3000a
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 116736k
  KERNEL_IN_UBI := 1
  IMAGES += factory.bin
  IMAGE/factory.bin := append-ubi | check-size $$$$(IMAGE_SIZE)
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += kst_wf3000a
EOF

# 3. Add OpenClash
git clone --depth=1 https://github.com/vernesong/OpenClash.git package/openclash
