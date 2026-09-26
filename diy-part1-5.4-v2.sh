#!/bin/bash
#
# diy-part1 for 5.4-v2 build: enforce 6.6-style partition layout for KST WF3000A
# in the padavanonly immortalwrt-mt798x-24.10 tree.
#
# 6.6 版分区基准（128MB SPI-NAND）：
#   BL2 0x100000 | u-boot-env 0x80000 | Factory 0x200000 | FIP 0x200000
#   ubi @0x580000 size 0x7200000 (114MB)，IMAGE_SIZE=116736k，KERNEL_IN_UBI=1
#
set -e

DTS=target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/mt7981-kst-wf3000a.dts
MK=target/linux/mediatek/image/mt7981.mk

echo "==> WF3000A DTS partition layout (before):"
grep -A2 'partition@580000' "$DTS" || true

# ubi 分区强制为 0x580000 + 0x7200000（与 6.6 自定义 DTS 完全一致，吃满 128MB NAND）
if grep -q 'reg = <0x580000 0x7200000>;' "$DTS"; then
    echo "==> ubi size already 0x7200000, no patch needed"
else
    sed -i 's/reg = <0x580000 0x[0-9a-fA-F]*>;/reg = <0x580000 0x7200000>;/' "$DTS"
    echo "==> ubi size patched to 0x7200000"
fi

echo "==> WF3000A DTS partition layout (after):"
grep -A2 'partition@580000' "$DTS"

echo "==> Device IMAGE_SIZE in mt7981.mk (expect 116736k):"
grep -A12 'define Device/kst_wf3000a' "$MK" | grep -E 'IMAGE_SIZE|KERNEL_IN_UBI'
