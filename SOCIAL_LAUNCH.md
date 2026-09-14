# Launch kit — Claude Desktop Persian RTL

This file contains ready-to-use launch copy and a simple promotion plan for the project.

Repository: https://github.com/farhadzandi/claude-desktop-rtl-patch-fa

Release: https://github.com/farhadzandi/claude-desktop-rtl-patch-fa/releases/tag/v1.3.2

---

## پیام اصلی پروژه

**Claude Desktop روی Windows برای فارسی، راست‌چینِ هوشمند و امن‌تر.**

این پروژه یک Patch متن‌باز برای Claude Desktop است که متن فارسی را RTL می‌کند، در عین حال Code، متن انگلیسی، نام فایل‌ها، جدول‌ها و بخش‌های فنی را تا حد ممکن LTR و خوانا نگه می‌دارد.

نسخه فعلی علاوه بر RTL فارسی، روی Restore، Audit، ACL restoration و بررسی وضعیت امنیتی نیز تمرکز دارد.

> اگر پروژه برایتان مفید بود، یک ⭐ در GitHub کمک می‌کند فارسی‌زبان‌های بیشتری آن را پیدا کنند.

---

## LinkedIn — نسخه فارسی

Claude Desktop بالاخره می‌تواند فارسی را مرتب‌تر و راست‌چین نمایش دهد.

مدتی بود روی یک نسخه فارسی و Security-Hardened از RTL Patch برای Claude Desktop روی Windows کار می‌کردم. نسخه عمومی v1.3.2 الان روی GitHub منتشر شده است.

ویژگی‌ها:

- تشخیص هوشمند فارسی و RTL
- حفظ LTR برای Code، متن انگلیسی و بخش‌های فنی
- پشتیبانی بهتر از متن ترکیبی فارسی/English، جدول‌ها، اعداد و فرمول‌ها
- امکان انتخاب فونت فارسی نصب‌شده روی Windows
- Restore فایل‌های اصلی Claude
- Security Audit و Verify Security State
- ACL snapshot / restore / verification
- بدون Scheduled Auto-Repatch و Remote Self-Updater در نسخه Hardened

این پروژه بر پایه پروژه متن‌باز `shraga100/claude-desktop-rtl-patch` ساخته و برای فارسی و امنیت عملیاتی بیشتر سفارشی شده است. Attribution و مجوز MIT اصلی هم در Repository حفظ شده‌اند.

GitHub:
https://github.com/farhadzandi/claude-desktop-rtl-patch-fa

اگر Claude Desktop استفاده می‌کنید، تستش کنید و اگر مفید بود ⭐ بدهید. گزارش نسخه Claude و تجربه‌تان هم برای سازگاری نسخه‌های بعدی خیلی کمک می‌کند.

#Claude #ClaudeDesktop #Persian #Farsi #RTL #OpenSource #Windows #AI #PowerShell

---

## Telegram / Bale — نسخه کوتاه

🔹 **پچ فارسی RTL برای Claude Desktop ویندوز منتشر شد**

اگر در Claude Desktop با نمایش فارسی، راست‌چین نبودن پاسخ‌ها یا به‌هم‌ریختگی متن فارسی/انگلیسی مشکل دارید، نسخه Open Source این Patch را منتشر کردم.

✅ RTL هوشمند فارسی
✅ Code و متن انگلیسی همچنان LTR
✅ پشتیبانی بهتر از جدول، اعداد و متن ترکیبی
✅ Restore فایل اصلی
✅ Security Audit و Verify
✅ نسخه Hardened بدون updater و Scheduled Auto-Repatch

پروژه بر پایه کار متن‌باز `shraga100` توسعه داده شده و Attribution و MIT License اصلی حفظ شده است.

🔗 GitHub:
https://github.com/farhadzandi/claude-desktop-rtl-patch-fa

اگر به دردتان خورد، ⭐ Star بزنید تا فارسی‌زبان‌های بیشتری پیدایش کنند.

---

## X / Twitter — نسخه کوتاه

Claude Desktop + Persian RTL 🇮🇷

نسخه v1.3.2 پچ متن‌باز فارسی برای Claude Desktop روی Windows منتشر شد:

• Smart Persian RTL
• mixed FA/EN handling
• code stays LTR
• tables/math fixes
• restore + security audit
• hardened ACL handling

⭐ https://github.com/farhadzandi/claude-desktop-rtl-patch-fa

#Claude #Persian #RTL #OpenSource

---

## Reddit / English launch

### Suggested title

**Open-source Persian RTL patch for Claude Desktop on Windows — smart mixed-direction handling + hardened rollback/audit**

### Post

I’ve published a Persian-first RTL patch for Claude Desktop on Windows.

It is based on the open-source `shraga100/claude-desktop-rtl-patch` project and keeps the original MIT attribution, while adding Persian-focused behavior and a more security-conscious operational model.

Main features include smart Persian/Arabic/Hebrew RTL detection, keeping code and technical English LTR, mixed Persian/English handling, table/digit/math improvements, optional local Persian fonts, restore support, ACL snapshot/restore verification, security auditing, and post-install state verification.

The hardened build intentionally avoids scheduled auto-repatch, background watchers, and remote self-updaters.

Repository:
https://github.com/farhadzandi/claude-desktop-rtl-patch-fa

I’d especially appreciate compatibility reports from users on different Claude Desktop versions and Windows builds.

---

## Hacker News / Show HN

### Suggested title

**Show HN: Persian RTL support for Claude Desktop on Windows**

### Suggested text

I built a Persian-first RTL patch for Claude Desktop on Windows, based on an existing MIT-licensed RTL project by shraga100.

The main challenge is mixed-direction content: Persian prose should be RTL, while code, filenames, technical English, math, and many table cells should remain LTR. The project also adds explicit rollback, ACL restoration checks, package hashing, and security-state verification because patching an Electron/MSIX desktop app is inherently invasive.

Repo: https://github.com/farhadzandi/claude-desktop-rtl-patch-fa

Feedback on the RTL heuristics and Windows compatibility is welcome.

---

## Demo video storyboard — 25 to 35 seconds

1. Show an unpatched Claude Desktop response containing Persian + English + code/table content.
2. Zoom briefly on misaligned/mixed-direction areas.
3. Show `run-patch.bat` and the Install/Re-Apply menu option.
4. Cut to the same/similar Claude response after patching.
5. Show Persian paragraph RTL, code LTR, and a mixed-language table.
6. End card: `Claude Desktop Persian RTL — Open Source` + GitHub repository address + `⭐ Star if useful`.

Do not show passwords, private chats, corporate paths, usernames, tokens, or internal documents in the recording.

---

## Suggested GitHub topics

`persian` `farsi` `rtl` `claude` `claude-desktop` `windows` `electron` `powershell` `open-source` `persian-language`

These topics need to be added from the repository GitHub UI if repository-settings API access is unavailable.

---

## 48-hour launch sequence

**Hour 0:** LinkedIn + Telegram/Bale + X post with the same short demo clip.

**Hour 2–6:** Ask a small number of real Claude Desktop users to test the release and report Windows/Claude versions. Do not buy stars or use star-exchange services.

**Day 1:** Post the English launch to relevant Reddit communities where self-promotion is permitted. Tailor the post to each community’s rules instead of cross-posting identical spam.

**Day 1–2:** Publish a short Persian write-up on a Persian developer platform/blog explaining the mixed RTL/LTR problem and how the project approaches it, then link the repository as the implementation.

**Day 2:** Share early compatibility feedback or a bug-fix update. Real technical progress is a stronger reason to reshare than asking repeatedly for stars.

---

## What helps GitHub stars organically

- A clear 20–35 second before/after demo.
- A screenshot/GIF visible near the top of the README in a future release.
- Fast responses to Issues.
- Small, frequent compatibility fixes after Claude Desktop updates.
- Accurate attribution and security documentation.
- Asking users for a Star only after showing the concrete benefit.

Avoid purchased stars, automated stars, mass unsolicited DMs, or star-for-star campaigns. They reduce trust and do not create useful users or contributors.
