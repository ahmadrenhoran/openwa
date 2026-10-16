// Fivebyte branding (fork-only). The sign-in copy lives outside the locale catalogues, so the i18n parity
// check does not see it: this file holds it to the same bar for every language the picker offers, and holds
// the restyled login stylesheet to the logical-sides rule the other page stylesheets follow.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

import { BRAND_COPY, brandCopy } from './branding.ts';
import { languageOptions } from './i18n/index.ts';

test('every language in the picker has complete Fivebyte sign-in copy', () => {
  for (const { value } of languageOptions) {
    const copy = BRAND_COPY[value];
    assert.ok(copy, `no Fivebyte copy for ${value}`);
    const strings = [copy.title, copy.subtitle, copy.headline, copy.poweredBy, ...copy.points];
    assert.equal(copy.points.length, 3, value);
    for (const text of strings) assert.ok(text.trim().length > 0, `empty Fivebyte string for ${value}`);
  }
});

test('non-English Fivebyte copy is translated, not English left in place', () => {
  for (const { value } of languageOptions) {
    if (value === 'en') continue;
    assert.notEqual(BRAND_COPY[value].headline, BRAND_COPY.en.headline, value);
    assert.notEqual(BRAND_COPY[value].title, BRAND_COPY.en.title, value);
  }
});

test('brandCopy falls back to English for a language without copy', () => {
  assert.equal(brandCopy('xx' as never), BRAND_COPY.en);
  assert.equal(brandCopy('id').title, 'Masuk ke dashboard');
});

test('the login stylesheet uses logical sides only', () => {
  const css = readFileSync(new URL('./pages/Login.css', import.meta.url), 'utf8').replace(/\/\*[\s\S]*?\*\//g, '');
  const physical =
    /(?:margin|padding|border)-(?:left|right)\b|border-(?:top|bottom)-(?:left|right)-radius|text-align:\s*(?:left|right)|(?:^|[\s;{])(?:left|right):/m;
  assert.doesNotMatch(css, physical);
});
