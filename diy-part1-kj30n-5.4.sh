#!/bin/bash
#
# diy-part1 for KJ30-N 5.4 build
# Source: dailook/immortalwrt-mt798x-6.6  branch 24.10-5.4-high_kernel
# Kernel 5.4 + closed-source MTK WiFi (mtwifi 7.6.6.x / mtwifi-cfg / warp)
#
# KJ30-N (Device/kjd_kj30-n in mt7981.mk) is NATIVELY supported in this tree,
# and its DTS already uses the 114MB (0x7200000) ubi partition, so no partition
# patch is required (unlike the wf3000A build on padavanonly, whose DTS needed
# the ubi size enforced). We keep a defensive check anyway.
#
# The one 5.4-specific fix that IS required: mac80211 backports-6.12.6
# unconditionally includes <linux/args.h>, which only exists since kernel 6.4,
# so it is fatal on kernel 5.4. Fix: add a backport-include/linux/args.h stub
# (new-file patch -> always applies cleanly).
#
set -e

echo "==> [KJ30-N 5.4] Verify ubi partition size (expect 0x7200000 / 114MB)"
DTS=target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/mt7981-kjd-kj30-n.dts
if [ -f "$DTS" ]; then
    grep -A2 'partition@580000' "$DTS" || true
    if grep -q 'reg = <0x580000 0x7200000>;' "$DTS"; then
        echo "==> ubi already 0x7200000, no patch needed"
    else
        sed -i 's/reg = <0x580000 0x[0-9a-fA-F]*>;/reg = <0x580000 0x7200000>;/' "$DTS"
        echo "==> ubi patched to 0x7200000"
        grep -A2 'partition@580000' "$DTS"
    fi
else
    echo "==> WARNING: $DTS not found, skipping ubi check"
fi

echo "==> [KJ30-N 5.4] Add args.h backport stub for mac80211 backports-6.12.6 on kernel 5.4"
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
