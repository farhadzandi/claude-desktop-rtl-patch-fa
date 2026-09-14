# Changelog

## v1.3.2 — Public release candidate

- منوی اصلی بازطراحی شد و شماره نسخه در Header نمایش داده می‌شود.
- منوی `Security & Maintenance` اضافه شد.
- Package Hash Verification، Security Audit و Security State Verification از داخل منو قابل اجرا شد.
- Legacy ACL Repair و Legacy Cleanup با تفکیک Dry-Run/Apply به منو اضافه شدند.
- بخش `About / Attribution` با اعتبار صریح `shraga100` و MIT اضافه شد.
- باگ `Verify-Package.ps1` اصلاح شد؛ نسخه قبلی Manifest بدون `*` را parse نمی‌کرد.
- README فارسی و انگلیسی به راهنمای کامل انتشار عمومی تبدیل شدند.
- راهنمای کامل Installation و Troubleshooting فارسی/انگلیسی اضافه شد.
- Codex/ChatGPT Desktop از Release فعلی حذف و به `ROADMAP.md` منتقل شد؛ پشتیبانی عمومی آن فعلاً ادعا نمی‌شود.
- سیاست امنیتی و توضیح certificate/private-key/ACL شفاف‌تر شد.
- همچنان RSA-1024، Auto-Repatch، Scheduled Task، remote updater و Electron-fuse fallback غیرفعال/حذف هستند.

## v1.3.2 — GitHub/Public hardening

- افزودن Attribution صریح به پروژه اصلی `shraga100/claude-desktop-rtl-patch`.
- حفظ مجوز MIT و Copyright اصلی.
- افزودن `ATTRIBUTION.md` و `NOTICE`.
- اصلاح نام الگوریتم ECDSA به `ECDSA_nistP256` مطابق Windows PowerShell.
- حذف کامل fallback ضعیف RSA-1024؛ فقط RSA-2048 و ECDSA P-256.
- افزودن GitHub Actions برای تست Node و parse کردن PowerShell.
- افزودن Inspector فقط-خواندنی برای Codex / Unified ChatGPT Desktop.
- Codex patch هنوز فعال نشده؛ مسیر binary/certificate مخصوص Claude عمداً روی Codex استفاده نمی‌شود.

فارسی

## v1.3.2 — Secure Hardened Final

- حذف کامل Auto Re-Patch، Scheduled Task، updater و Quick Re-Apply از مسیر اجرایی.
- حذف fuse bypass؛ نسخه ناسازگار Claude به‌جای تضعیف کنترل Electron با خطای امن متوقف می‌شود.
- جایگزینی `takeown /R` و `icacls /T` با دسترسی موقت دقیق به پنج هدف ضروری.
- snapshot و verify کردن Owner/DACL و بازگردانی بعد از install/restore/rollback.
- overwrite درجا برای `app.asar` جهت حفظ ACL فایل.
- انتقال Backup از WindowsApps به ProgramData محافظت‌شده.
- اولویت RSA-2048 و fail-closed در صورت حذف‌نشدن private key.
- گواهی محلی دیگر نام Anthropic را جعل نمی‌کند.
- ابزار Verify Security State اضافه شد.
- 56 تست RTL/فارسی پاس می‌شوند.
