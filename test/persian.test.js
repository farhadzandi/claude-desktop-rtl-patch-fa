// Persian (Farsi) specific behaviour of the detection core.
//
// The generic Arabic block was already covered by RTL_RANGES, so plain Persian
// prose always worked. What did NOT work, and is pinned here, is everything that
// makes Persian different from Hebrew in practice: Persian digits, the ZWNJ
// (nim-fasele), Persian punctuation, and arithmetic written in Persian numerals.
'use strict';
const test = require('node:test');
const assert = require('node:assert');
const core = require('../src/rtl-core.js');

const cp = s => s.codePointAt(0);

// --- letters ---------------------------------------------------------------

test('Persian-only letters are strong RTL', () => {
    // The four letters Persian adds to the Arabic alphabet, plus the Persian
    // heh/yeh/kaf variants that differ from their Arabic counterparts.
    for (const ch of ['پ', 'چ', 'ژ', 'گ', 'ک', 'ی', 'ه']) {
        assert.ok(core.isRTL(cp(ch)), 'strong RTL: ' + ch);
    }
    assert.strictEqual(core.firstStrong('پژوهش'), 'rtl');
    assert.ok(core.hasRTL('گزارش'));
});

test('Persian paragraph beats a leading Latin filename', () => {
    assert.strictEqual(core.firstStrong('config.json فایل پیکربندی است'), 'ltr');
    assert.strictEqual(
        core.firstStrong(core.stripLeadingLTR('config.json فایل پیکربندی است')), 'rtl');
});

test('English sentence quoting one Persian word stays LTR', () => {
    assert.ok(!core.rtlMajority('The Persian word for hello is سلام'));
});

test('Persian sentence with an embedded Latin term flips RTL', () => {
    assert.ok(core.rtlMajority('من یک رشته string را داخل جمله نوشتم'));
});

// --- ZWNJ (U+200C, nim-fasele) ---------------------------------------------

test('ZWNJ is neutral, not strong, and never breaks detection', () => {
    assert.ok(!core.isRTL(0x200C), 'ZWNJ is not strong RTL');
    // "mi-shavad" written with a nim-fasele must still read as one RTL run.
    assert.strictEqual(core.firstStrong('می‌شود'), 'rtl');
    assert.ok(core.hasRTL('نمی‌توان'));
    assert.strictEqual(core.cellDir('برنامه‌ریزی'), 'rtl');
});

// --- digits: weak, not strong ----------------------------------------------

test('Persian and Arabic-Indic digits are NOT strong RTL', () => {
    assert.ok(core.isWeakArabic(0x06F1), 'Persian one');
    assert.ok(core.isWeakArabic(0x0661), 'Arabic-Indic one');
    for (const ch of ['۰', '۵', '۹', '٠', '٩']) {
        assert.ok(!core.isRTL(cp(ch)), 'weak: ' + ch);
    }
    assert.ok(!core.hasRTL('۱۲۳۴۵'));
    assert.strictEqual(core.firstStrong('۱۲۳'), null);
});

test('a numeric-only cell stays neutral so it cannot flip a table', () => {
    assert.strictEqual(core.cellDir('۱۲۳'), null);
    assert.strictEqual(core.cellDir('۱٬۲۳۴٫۵۶'), null); // Arabic thousands + decimal
    assert.strictEqual(core.cellDir('۱۴۰۴/۰۶/۲۲'), null);
    // ...while a Persian label still does.
    assert.strictEqual(core.cellDir('ردیف'), 'rtl');
});

test('a Persian table is detected from its labels, not its numbers', () => {
    const headers = ['شناسه', 'نام', 'تعداد'].map(core.cellDir);
    const firstCol = ['۱', '۲', '۳'].map(core.cellDir);
    assert.strictEqual(core.tableDirFromCells(headers, firstCol), 'rtl');
});

test('Latin-first header on a Persian table still flips via majority', () => {
    const headers = ['ID', 'نام کالا', 'قیمت واحد'].map(core.cellDir);
    assert.strictEqual(core.tableDirFromCells(headers, [null, null]), 'rtl');
});

test('a purely numeric Persian table is left LTR', () => {
    const headers = ['۱۳۹۹', '۱۴۰۰', '۱۴۰۱'].map(core.cellDir);
    assert.strictEqual(core.tableDirFromCells(headers, ['۱۲', '۳۴'].map(core.cellDir)), null);
});

// --- arithmetic in Persian digits ------------------------------------------

test('arithmetic in Persian digits is isolated as math', () => {
    const segs = core.segmentText('جمع ۲ + ۳ = ۵ می‌شود');
    const math = segs.filter(s => s.type === 'math');
    assert.strictEqual(math.length, 1);
    assert.strictEqual(math[0].value, '۲ + ۳ = ۵');
});

test('Arabic-Indic digits work the same', () => {
    const segs = core.segmentText('الحساب ٢ + ٣ = ٥ هنا');
    assert.strictEqual(segs.filter(s => s.type === 'math').length, 1);
});

test('mixed ASCII/Persian arithmetic is still one run', () => {
    const r = core.findMathRanges('نرخ ۱۰ * 2 = ۲۰ تومان');
    assert.strictEqual(r.length, 1);
});

test('a lone Persian number is not math', () => {
    assert.deepStrictEqual(core.findMathRanges('قیمت ۵۰۰۰ تومان'), []);
    assert.deepStrictEqual(core.findMathRanges('سال ۱۴۰۴'), []);
});

test('a Persian numbered list marker is not math', () => {
    assert.deepStrictEqual(core.findMathRanges('۱. مقدمه'), []);
});

test('Persian punctuation is trimmed off a math island', () => {
    // The Persian comma / full stop must stay OUTSIDE the LTR isolate, or it is
    // pulled to the wrong side of the expression.
    const segs = core.segmentText('نتیجه ۲ + ۲ = ۴، سپس ادامه');
    const math = segs.filter(s => s.type === 'math');
    assert.strictEqual(math.length, 1);
    assert.strictEqual(math[0].value, '۲ + ۲ = ۴');
    const segs2 = core.segmentText('حاصل 10 / 2 = 5؛ تمام');
    assert.strictEqual(segs2.filter(s => s.type === 'math')[0].value, '10 / 2 = 5');
});

test('Persian currency text is not mistaken for LaTeX', () => {
    assert.deepStrictEqual(core.findLatexRanges('قیمت $5.99 است'), []);
});

test('LaTeX inside a Persian sentence is isolated', () => {
    const segs = core.segmentText('فرمول $x^2$ در متن فارسی');
    assert.strictEqual(segs.filter(s => s.type === 'math').length, 1);
});

// --- Persian punctuation as text -------------------------------------------

test('Persian question mark and semicolon remain strong RTL letters', () => {
    // Unicode gives U+061B and U+061F bidi class AL, so they belong with the text.
    assert.ok(core.isRTL(cp('؟')));
    assert.ok(core.isRTL(cp('؛')));
    // The Arabic comma is class CS and must not, on its own, claim a cell.
    assert.ok(!core.isRTL(cp('،')));
});

// --- regression: Hebrew must not be harmed ---------------------------------

test('Hebrew behaviour is unchanged', () => {
    assert.strictEqual(core.firstStrong('سلام world'), 'rtl');
    assert.ok(core.rtlMajority('فقط فارسی'));
    assert.strictEqual(core.cellDir('فایل'), 'rtl');
});
