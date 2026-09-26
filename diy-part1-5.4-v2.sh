#!/bin/bash
#
# diy-part1 for 5.4-v2 build (padavanonly immortalwrt-mt798x-24.10, branch 2410)
#
# 1. Partition: enforce 6.6-style layout for KST WF3000A (128MB SPI-NAND)
#    BL2 1M | u-boot-env 0.5M | Factory 2M | FIP 2M | ubi @0x580000 = 0x7200000 (114MB)
#    IMAGE_SIZE=116736k, KERNEL_IN_UBI=1
#
# 2. mac80211 fix: backports-6.12.6 unconditionally includes <linux/args.h>,
#    which only exists since kernel 6.4 -> fatal on kernel 5.4
#    (backport-include/linux/string.h:4). Backports tarball ships no args.h.
#    Fix: add a patch providing backport-include/linux/args.h with the
#    upstream v6.6 header content. New-file patch -> always applies cleanly.
#
set -e

DTS=target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/mt7981-kst-wf3000a.dts
MK=target/linux/mediatek/image/mt7981.mk

echo "==> [1/2] WF3000A DTS partition layout (before):"
grep -A2 'partition@580000' "$DTS" || true

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

echo "==> [2/2] Adding args.h backport stub patch for backports-6.12.6 on kernel 5.4"
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
echo "==> args.h stub patch written:"
head -4 package/kernel/mac80211/patches/build/013-add-args-h-backport.patch
