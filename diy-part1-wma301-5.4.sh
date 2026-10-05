#!/bin/bash
#
# diy-part1 for TP-Link WMA301 V2 (5.4 build)
# Source: dailook/immortalwrt-mt798x-6.6  branch 24.10-5.4-high_kernel
#
# 注意：dailook 这个分支的设备列表里**没有** wma301（mt7981.mk 只有 62 个机型），
# 所以这里做三件事：
#   1) 把设备树塞进 target/linux/mediatek/files-5.4/.../mediatek/
#   2) 往 target/linux/mediatek/image/mt7981.mk 追加 define Device/tplink_wma301
#   3) 补 kernel 5.4 编译 mac80211 backports-6.12.6 必需的 args.h 存根
#
# 必须在 make defconfig 之前跑（本脚本在 "Load custom feeds" 阶段执行，满足）。
#
set -e

DTS_DIR=target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek
echo "==> [WMA301] 注入设备树"
mkdir -p "$DTS_DIR"
cp "$GITHUB_WORKSPACE/mt7981-tplink-wma301.dts" "$DTS_DIR/"
ls -l "$DTS_DIR/mt7981-tplink-wma301.dts"

MK=target/linux/mediatek/image/mt7981.mk
echo "==> [WMA301] 注入机型定义到 $MK"
if grep -q "define Device/tplink_wma301" "$MK"; then
    echo "==> 已存在，跳过（幂等）"
else
    cat >> "$MK" <<'MKEOF'
define Device/tplink_wma301
  DEVICE_VENDOR := TP-Link
  DEVICE_MODEL := WMA301
  DEVICE_VARIANT := V2
  DEVICE_DTS := mt7981-tplink-wma301
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := mediatek,mt7981-spim-snand-rfb
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 65536k
  KERNEL_IN_UBI := 1
  IMAGES += factory.bin
  IMAGE/factory.bin := append-ubi | check-size $$$$(IMAGE_SIZE)
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += tplink_wma301
MKEOF
    echo "==> 已追加"
fi
grep -n "tplink_wma301" "$MK" | head

echo "==> [WMA301] 核对 ubi 分区（应为 0x580000 + 0x4000000 = 64MB）"
DTS="$DTS_DIR/mt7981-tplink-wma301.dts"
grep -A2 'partition@580000' "$DTS" || true

echo "==> [5.4] 补 args.h 存根（mac80211 backports-6.12.6 在 kernel 5.4 上需要）"
mkdir -p package/kernel/mac80211/patches/build
cat > package/kernel/mac80211/patches/build/013-add-args-h-backport.patch <<'PATCH'
--- /dev/null
+++ b/backport-include/linux/args.h
@@ -0,0 +1,26 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+
+#ifndef _LINUX_ARGS_H
+#define _LINUX_ARGS_H
+
+/*
+ * How do these macros work?
+ *
+ * In __COUNT_ARGS() _0 to _12 are just placeholders from the start
+ * in order to make sure _n is positioned over the correct number
+ * from 12 to 0 (depending on X, which is a variadic argument list).
+ * They serve no purpose other than occupying a position. Since each
+ * macro parameter must have a distinct identifier, those identifiers
+ * are as good as any.
+ *
+ * In COUNT_ARGS() we use actual integers, so __COUNT_ARGS() returns
+ * that as _n.
+ */
+
+/* This counts to 12. Any more, it will return 13th argument. */
+#define __COUNT_ARGS(_0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _n, X...) _n
+#define COUNT_ARGS(X...) __COUNT_ARGS(, ##X, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
+
+/* Concatenate two parameters, but allow them to be expanded beforehand. */
+#define __CONCAT(a, b) a ## b
+#define CONCATENATE(a, b) __CONCAT(a, b)
+
+#endif	/* _LINUX_ARGS_H */
PATCH
echo "==> args.h 存根已写入"
