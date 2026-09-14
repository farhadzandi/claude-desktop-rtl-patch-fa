# رفع اشکال

## `node` یا `npx` شناخته نمی‌شود

```powershell
node --version
npx --version
```

Node.js جدید نصب کنید و Terminal را ببندید و دوباره باز کنید.

## Node قدیمی است

نسخه حداقل:

```text
22.12.0
```

است.

## `Claude installation not found`

Claude Desktop را نصب و یک‌بار اجرا کنید. اگر Store/AppX registration خراب است، ابتدا نصب رسمی Claude را Repair/Reinstall کنید.

## `Baseline ACL is dirty` یا `ACL modification evidence`

اگر قبلاً Patch قدیمی اجرا شده:

```powershell
powershell -ExecutionPolicy Bypass -File .\ClaudeRtlPatch-Audit.ps1 -ExportReport
powershell -ExecutionPolicy Bypass -File .\ClaudeRtlPatch-ACL-Repair.ps1
```

ابتدا Dry Run را بررسی کنید؛ سپس در صورت صحیح بودن `-Apply`.

## `HASH MISMATCH` در Verify-Package

Patch را اجرا نکنید. فایل را دوباره از GitHub Release معتبر بگیرید و ZIP را کامل Extract کنید.

## ASAR extract/pack failure

- Node و `npx` را بررسی کنید.
- اتصال اینترنت را در اولین اجرا بررسی کنید.
- Log را ببینید:

```text
%ProgramData%\ClaudeRtlPatch\patch.log
```

## Certificate generation/signing failure

نسخه Secure فقط RSA-2048 و ECDSA P-256 را می‌پذیرد. اگر certificate در slot موردنیاز Claude جا نشود یا signing شکست بخورد، Patch باید متوقف/Rollback شود. RSA-1024 عمداً استفاده نمی‌شود.

## `ACL restoration was not fully verified`

Claude را در آن وضعیت رها نکنید. ابتدا Restore را امتحان کنید، سپس Audit/ACL Repair را اجرا کنید. اگر مشکل باقی ماند، Claude Desktop را از منبع رسمی reinstall کنید.

## Claude بعد از Patch اجرا نمی‌شود

1. Patch را دوباره باز کنید.
2. گزینه Restore را اجرا کنید.
3. Verify Security State را اجرا کنید.
4. اگر Restore معتبر در دسترس نبود، Claude Desktop را reinstall کنید.

## بعد از Update، RTL از بین رفت

طبیعی است. Auto-Repatch حذف شده است:

```text
run-patch.bat
→ Install / Re-Apply
```

## SmartScreen / هشدار Windows

کد را از Release معتبر بگیرید، `Verify-Package.ps1` را اجرا کنید و فقط بعد از بررسی فایل‌ها ادامه دهید. اسکریپت unsigned PowerShell ممکن است هشدار ایجاد کند.

## PowerShell 7

برای این پروژه `powershell.exe` کلاسیک Windows PowerShell 5.1 توصیه و توسط launcher استفاده می‌شود. از `pwsh.exe` استفاده نکنید.

## گزارش Bug

حداقل این موارد را ضمیمه کنید:

- Windows version
- Claude Desktop version
- Node version
- مراحل بازتولید
- پیام خطا
- بخش مرتبط `patch.log`
- خروجی Verify Security State

اطلاعات حساس را قبل از ارسال عمومی حذف کنید.
