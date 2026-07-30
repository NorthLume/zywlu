import { readFileSync } from 'node:fs';

import { describe, expect, it } from 'vitest';

import { site } from '../src/config/site';

const robots = readFileSync(new URL('../public/robots.txt', import.meta.url), 'utf8');
const sitemap = readFileSync(new URL('../public/sitemap.xml', import.meta.url), 'utf8');

describe('public search metadata', () => {
  it('points robots to the production sitemap', () => {
    expect(robots).toContain(`Sitemap: ${site.url}/sitemap.xml`);
  });

  it('publishes the production homepage URL', () => {
    expect(sitemap).toContain(`<loc>${site.url}/</loc>`);
  });
});
