# Claude Desktop Persian RTL Patch — Secure Hardened v1.3.2


پشتیبانی هوشمند **راست‌به‌چپ فارسی (RTL)** برای **Claude Desktop روی Windows** همراه با
بازیابی فایل‌های اصلی، کنترل ACL، ابزار Audit و بررسی وضعیت امنیتی.

[English README](README.md) · [راهنمای نصب کامل فارسی](docs/INSTALLATION.fa.md) · [رفع اشکال](docs/TROUBLESHOOTING.fa.md)

> [!IMPORTANT]
> این پروژه یک **نسخه سفارشی‌شده و مشتق‌شده** از
> [`shraga100/claude-desktop-rtl-patch`](https://github.com/shraga100/claude-desktop-rtl-patch)
> است. ایده و پیاده‌سازی اصلی RTL برای Claude Desktop توسط **shraga100** ایجاد شده است.
> پروژه اصلی تحت **MIT License** منتشر شده و متن Copyright و مجوز اصلی در `LICENSE`
> حفظ شده است.
>
> این پروژه مستقل است و **محصول رسمی Anthropic نیست**.

## چه کاری انجام می‌دهد؟

- تشخیص خودکار متن فارسی/عربی/عبری و تنظیم جهت RTL در پاسخ‌ها.
- حفظ جهت LTR برای متن انگلیسی، Code blockها، نام فایل‌ها و بخش‌های فنی.
- رفتار بهتر برای متن ترکیبی فارسی/انگلیسی.
- پشتیبانی بهتر از جدول‌ها، اعداد فارسی و فرمول‌های ریاضی.
- اصلاح مشکل Window Chrome روی Windowsهای RTL بدون RTL کردن کل رابط.
- امکان استفاده از فونت نصب‌شده روی Windows مانند `Vazirmatn`.
- Backup از فایل‌های اصلی Claude قبل از تغییر.
- Rollback خودکار در صورت شکست عملیات.
- Restore فایل‌های اصلی از داخل منو.
- Audit، بررسی Hash پکیج، Verify Security State و ابزار Repair/Cleanup برای نسخه‌های قدیمی.

## چه چیزی عمداً وجود ندارد؟

نسخه Secure Hardened برای کاهش سطح حمله این موارد را **عمداً نصب نمی‌کند**:

- Scheduled Task برای Auto Re-Patch
- Background watcher
- Remote self-updater
- Quick-update persistence
- Electron integrity fuse disable fallback
- RSA-1024 signing fallback

بعد از Update شدن Claude Desktop، Patch را **دستی** دوباره اجرا کنید.

## تفاوت این نسخه با پروژه اصلی

| بخش | Upstream اصلی | نسخه فارسی Secure Hardened |
| --- | --- | --- |
| تمرکز زبانی | Hebrew / Arabic | Persian-first |
| موتور RTL | پایه اصلی | حفظ/تطبیق + تست‌های فارسی |
| UI/Docs عبری | دارد | از توزیع فارسی حذف شده |
| دسترسی WindowsApps | در نسخه‌های قدیمی می‌تواند گسترده باشد | Exact-scope، موقت، Snapshot/Restore/Verify |
| Backup | رویکرد upstream | Backup محافظت‌شده خارج از WindowsApps |
| Auto re-patch | اختیاری | حذف شده |
| Remote updater | اختیاری | حذف شده |
| Electron fuse fallback | قابل استفاده در upstream | Fail-closed؛ غیرفعال‌سازی fuse انجام نمی‌شود |
| Certificate subject | رویکرد upstream | `Claude RTL Local Patch` شفاف |
| Private signing key | موقت | حذف آن باید Verify شود؛ در غیر این صورت Rollback |
| RSA-1024 | ممکن در مسیرهای قدیمی | رد می‌شود؛ RSA-2048 و ECDSA P-256 |
| ابزار امنیتی | ابزارهای upstream | Audit + Verify + Cleanup + ACL Repair |

جزئیات بیشتر: [`ATTRIBUTION.md`](ATTRIBUTION.md) و [`SECURITY.md`](SECURITY.md).

---

## پیش‌نیازها

- Windows 10 یا Windows 11، نسخه 64-bit
- Claude Desktop نصب‌شده
- **Windows PowerShell 5.1** (`powershell.exe`)
- Node.js **22.12.0 یا جدیدتر**
- `npx` در PATH
- دسترسی Administrator
- اینترنت در اولین اجرا ممکن است برای دریافت نسخه Pin شده `@electron/asar@4.2.0` لازم باشد

بررسی Node:

```powershell
node --version
npx --version
```

---

## نصب سریع

### روش پیشنهادی: Git clone

```powershell
git clone https://github.com/farhadzandi/claude-desktop-rtl-patch-fa.git
cd claude-desktop-rtl-patch-fa
powershell -ExecutionPolicy Bypass -File .\Verify-Package.ps1
.\run-patch.bat
```

در منو گزینه:

```text
1. Install / Re-Apply Persian RTL Patch
```

را انتخاب کنید.

### روش ZIP

1. از بخش **Releases** فایل ZIP آخرین نسخه را دانلود کنید.
2. ZIP را **کامل Extract** کنید؛ اسکریپت را داخل ZIP اجرا نکنید.
3. وارد پوشه Extract شده شوید.
4. بهتر است ابتدا این دستور را اجرا کنید:

```powershell
powershell -ExecutionPolicy Bypass -File .\Verify-Package.ps1
```

5. سپس:

```text
run-patch.bat
```

را اجرا کنید و گزینه `1` را بزنید.

> [!WARNING]
> این پروژه برای نصب، Administrator می‌خواهد و فایل‌های محلی Claude Desktop را تغییر می‌دهد.
> قبل از اجرا کد و `SECURITY.md` را بررسی کنید. این نسخه عمداً `irm | iex` را پشتیبانی نمی‌کند.

---

## منوی برنامه

```text
1. Install / Re-Apply Persian RTL Patch
2. Restore Original Claude Files & Remove Patch
3. Set Persian / Custom Text Font
4. Security & Maintenance
5. About / Attribution
6. Exit
```

### Security & Maintenance

```text
1. Verify downloaded package hashes
2. Full security audit
3. Verify current patched security state
4. Legacy ACL repair — DRY-RUN
5. Legacy ACL repair — APPLY
6. Legacy residue cleanup — DRY-RUN
7. Legacy residue cleanup — APPLY
8. Back
```

گزینه‌های Repair/Cleanup عمدتاً برای سیستم‌هایی هستند که نسخه‌های قدیمی Patch روی آنها اجرا شده است.

---

## اگر قبلاً Patch قدیمی نصب کرده‌اید

ابتدا Audit بگیرید:

```powershell
powershell -ExecutionPolicy Bypass -File .\ClaudeRtlPatch-Audit.ps1 -ExportReport
```

اگر `ACL modification evidence` مشاهده شد:

```powershell
powershell -ExecutionPolicy Bypass -File .\ClaudeRtlPatch-ACL-Repair.ps1
```

این دستور **Dry Run** است. فقط بعد از بررسی خروجی، در صورت نیاز:

```powershell
powershell -ExecutionPolicy Bypass -File .\ClaudeRtlPatch-ACL-Repair.ps1 -Apply
```

سپس Audit را دوباره اجرا کنید.

---

## بررسی امنیتی بعد از نصب

پس از Patch:

```powershell
powershell -ExecutionPolicy Bypass -File .\Verify-Security-State.ps1 -ExportReport
```

در حالت Patched انتظار می‌رود:

- فایل‌های Claude لازم برای RTL تغییر کرده باشند.
- Root certificate عمومی با Subject مربوط به `Claude RTL Local Patch` وجود داشته باشد.
- Private key باقی نمانده باشد.
- Scheduled Task مربوط به Patch وجود نداشته باشد.
- updater/watcher وجود نداشته باشد.
- ACL/Owner موقت روی Claude باقی نمانده باشد.
- فایل `.bak` کنار فایل‌های WindowsApps باقی نمانده باشد.

وجود Root certificate عمومی **در حالت Patched بخشی از سازوکار این Patch است**. گزینه Restore آن را حذف می‌کند.

---

## Restore / حذف Patch

`run-patch.bat` را اجرا کنید و گزینه:

```text
2. Restore Original Claude Files & Remove Patch
```

را انتخاب کنید.

این مرحله فایل‌های Vendor backup شده را برمی‌گرداند و certificate محلی Patch را حذف می‌کند.

برای پاک‌سازی residue نسخه‌های قدیمی می‌توانید ابتدا Dry Run بگیرید:

```powershell
powershell -ExecutionPolicy Bypass -File .\ClaudeRtlPatch-Cleanup.ps1
```

و فقط در صورت صحیح بودن خروجی:

```powershell
powershell -ExecutionPolicy Bypass -File .\ClaudeRtlPatch-Cleanup.ps1 -Apply
```

بعد از Restore موفق می‌توانید پوشه Repository/ZIP Extract شده را هم حذف کنید.

---

## فونت فارسی

از منو:

```text
3. Set Persian / Custom Text Font
```

را انتخاب کنید.

مثال فونت:

```text
Vazirmatn
```

فونت باید از قبل روی Windows نصب شده باشد. Patch فایل فونت دانلود یا Bundle نمی‌کند؛ فقط از
`local()` در CSS استفاده می‌کند.

اجرای مستقیم:

```powershell
powershell -ExecutionPolicy Bypass -File .\patch.ps1 -CustomFont "Vazirmatn" -CustomFontScope persian
```

---

## پس از Update شدن Claude Desktop

این نسخه Auto-Repatch ندارد. پس از Update:

```text
run-patch.bat
→ 1. Install / Re-Apply Persian RTL Patch
```

Patch نسخه جدید Claude را دوباره شناسایی می‌کند. اگر ساختار نسخه جدید ناسازگار باشد، باید
**Fail closed** کند و از تغییر نامطمئن خودداری کند.

---

## Codex / ChatGPT Desktop

**در v1.3.2 پشتیبانی نمی‌شود.**

بررسی انجام‌شده روی نسخه Windows موجود نشان داد که اگرچه `resources\app.asar` وجود دارد،
مکانیزم Integrity آن با Claude یکسان فرض‌کردنی نیست. برای جلوگیری از Patch حدسی روی
OpenAI/Codex، این قابلیت به نسخه فعلی اضافه نشده است.

وضعیت آینده در [`ROADMAP.md`](ROADMAP.md) دنبال می‌شود.

---

## گزارش خطا

هنگام گزارش Bug این موارد را ارسال کنید:

- Windows version
- Claude Desktop version
- Node version (`node --version`)
- شرح دقیق مشکل
- بخش مرتبط از `%ProgramData%\ClaudeRtlPatch\patch.log`
- خروجی `Verify-Security-State.ps1` در صورت ارتباط

**اطلاعات حساس، نام کاربری سازمانی، مسیرهای محرمانه یا داده‌های گفتگو را قبل از انتشار عمومی حذف کنید.**

---

## مجوز و اعتبار

- Upstream: [`shraga100/claude-desktop-rtl-patch`](https://github.com/shraga100/claude-desktop-rtl-patch)
- Original author/copyright holder: **shraga100**
- License: **MIT**

فایل‌های [`LICENSE`](LICENSE)، [`NOTICE`](NOTICE) و [`ATTRIBUTION.md`](ATTRIBUTION.md) را ببینید.

