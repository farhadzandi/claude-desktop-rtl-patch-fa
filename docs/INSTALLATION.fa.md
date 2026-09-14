# راهنمای کامل نصب، به‌روزرسانی و حذف

## 1) قبل از شروع

این Patch فایل‌های نصب‌شده Claude Desktop را تغییر می‌دهد. به همین دلیل:

1. Claude Desktop باید نصب شده باشد.
2. حساب اجراکننده باید بتواند UAC را تأیید کند.
3. از **Windows PowerShell 5.1** استفاده کنید.
4. Node.js حداقل `22.12.0` لازم است.
5. فایل ZIP را کامل Extract کنید.

بررسی:

```powershell
powershell -Version
node --version
npx --version
```

## 2) دریافت پروژه

### Git

```powershell
git clone https://github.com/farhadzandi/claude-desktop-rtl-patch-fa.git
cd claude-desktop-rtl-patch-fa
```

### ZIP

از GitHub Releases آخرین ZIP را بگیرید و مثلاً در این مسیر Extract کنید:

```text
C:\Tools\claude-desktop-rtl-patch-fa
```

اسکریپت را مستقیماً از داخل ZIP اجرا نکنید.

## 3) Verify فایل‌های دانلودشده

از داخل پوشه پروژه:

```powershell
powershell -ExecutionPolicy Bypass -File .\Verify-Package.ps1
```

خروجی سالم:

```text
[PASS] Verified ... file(s) against MANIFEST-SHA256.txt
```

اگر `HASH MISMATCH` یا `MISSING` دیدید، Patch را اجرا نکنید و فایل‌ها را دوباره از Release معتبر بگیرید.

## 4) اگر قبلاً Patch قدیمی داشتید

```powershell
powershell -ExecutionPolicy Bypass -File .\ClaudeRtlPatch-Audit.ps1 -ExportReport
```

اگر ACL residue گزارش شد:

```powershell
powershell -ExecutionPolicy Bypass -File .\ClaudeRtlPatch-ACL-Repair.ps1
```

ابتدا Dry Run را بررسی کنید. فقط در صورت صحیح بودن:

```powershell
powershell -ExecutionPolicy Bypass -File .\ClaudeRtlPatch-ACL-Repair.ps1 -Apply
```

Audit را دوباره اجرا کنید.

## 5) نصب

راحت‌ترین راه:

```text
run-patch.bat
```

یا:

```powershell
powershell -ExecutionPolicy Bypass -File .\patch.ps1
```

اگر UAC ظاهر شد، فقط زمانی تأیید کنید که فایل‌ها را از Repository/Release مورد اعتماد گرفته‌اید.

از منو:

```text
1. Install / Re-Apply Persian RTL Patch
```

را انتخاب کنید.

Patch در حین کار Claude و سرویس مربوط به آن را موقتاً می‌بندد.

## 6) چه تغییراتی در زمان نصب رخ می‌دهد؟

به‌طور خلاصه:

1. Claude Desktop و مسیر نصب شناسایی می‌شود.
2. وضعیت ACL/Owner اهداف لازم ثبت می‌شود.
3. Backup امن از فایل‌های Vendor گرفته می‌شود.
4. دسترسی موقت فقط روی اهداف لازم ایجاد می‌شود.
5. `app.asar` باز، RTL payload تزریق و دوباره بسته می‌شود.
6. Hash لازم در مسیر integrity Claude هماهنگ می‌شود.
7. Certificate محلی موقت برای signing ساخته می‌شود.
8. Private key پس از استفاده حذف و حذف آن Verify می‌شود.
9. ACL/Owner اصلی Restore و Verify می‌شود.
10. Claude دوباره راه‌اندازی می‌شود.

اگر مرحله‌ای از کنترل‌های اجباری شکست بخورد، Patch باید Rollback کند.

## 7) Verify بعد از نصب

```powershell
powershell -ExecutionPolicy Bypass -File .\Verify-Security-State.ps1 -ExportReport
```

یا از منو:

```text
Security & Maintenance
→ Verify current patched security state
```

وجود Root certificate عمومی Patch در حالت patched طبیعی است، اما `HasPrivateKey=True` نباید باقی بماند.

## 8) فونت فارسی

فونت دلخواه مثل `Vazirmatn` را ابتدا روی Windows نصب کنید، سپس:

```text
3. Set Persian / Custom Text Font
```

یا:

```powershell
powershell -ExecutionPolicy Bypass -File .\patch.ps1 -CustomFont "Vazirmatn" -CustomFontScope persian
```

## 9) پس از Update Claude

Claude update معمولاً فایل‌های Patch شده را جایگزین می‌کند. چون Auto-Repatch در نسخه امن حذف شده:

```text
run-patch.bat
→ Install / Re-Apply Persian RTL Patch
```

را دوباره اجرا کنید.

## 10) Restore

```text
run-patch.bat
→ Restore Original Claude Files & Remove Patch
```

پس از آن Verify Security State را اجرا کنید.

## 11) حذف residueهای قدیمی

Dry Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\ClaudeRtlPatch-Cleanup.ps1
```

Apply:

```powershell
powershell -ExecutionPolicy Bypass -File .\ClaudeRtlPatch-Cleanup.ps1 -Apply
```

این ابزار برای پاک‌سازی آثار شناخته‌شده نسخه‌های قدیمی ساخته شده است. قبل از Apply خروجی را بررسی کنید.

## 12) حذف کامل ابزار از سیستم

پس از Restore موفق و در صورت نیاز Cleanup:

1. مطمئن شوید Claude عادی اجرا می‌شود.
2. Verify Security State را اجرا کنید.
3. پوشه Clone/Extract شده این Repository را حذف کنید.

## 13) نکته امنیتی

این پروژه به‌دلیل معماری Claude Desktop عملیات privileged و تغییر باینری انجام می‌دهد.
«Hardened» به معنی بدون‌ریسک بودن نیست؛ به معنی محدود کردن سطح تغییرات، Fail-closed شدن و
داشتن مسیر قابل بررسی برای Restore/Audit است.
