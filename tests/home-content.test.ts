import { describe, expect, it } from 'vitest';

import { firstGuides, topics, writingPrinciples } from '../src/data/home';

describe('homepage content', () => {
  it('keeps topic identifiers unique', () => {
    const identifiers = topics.map((topic) => topic.index);

    expect(new Set(identifiers).size).toBe(identifiers.length);
    expect(topics).toHaveLength(4);
  });

  it('publishes a concrete first guide roadmap', () => {
    expect(firstGuides).toHaveLength(3);
    expect(firstGuides.every((guide) => guide.title.length > 10)).toBe(true);
  });

  it('defines the writing principles used on the homepage', () => {
    expect(writingPrinciples).toHaveLength(4);
    expect(writingPrinciples.map((principle) => principle.index)).toEqual(['01', '02', '03', '04']);
  });
});
