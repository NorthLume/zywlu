import { describe, expect, it } from 'vitest';

import { site } from '../src/config/site';

describe('site metadata', () => {
  it('defines the public site identity', () => {
    expect(site.name).toBe('ZYWLU');
    expect(site.locale).toBe('zh-CN');
    expect(site.description.trim().length).toBeGreaterThan(0);
  });
});
