import { defineCollection, z } from 'astro:content';

const articles = defineCollection({
  type: 'content',
  schema: z.object({
    title: z.string(),
    metaDescription: z.string().max(160),
    searchHeadline: z.string(),
    searchHeadlineEm: z.string().optional(),
    searchSubhead: z.string(),
    category: z.string(),
    readTime: z.string(),
    bridgeHeadline: z.string(),
    bridgeHeadlineEm: z.string().optional(),
    bridgeBody: z.string(),
    relatedArticles: z.array(z.object({
      tag: z.string(),
      title: z.string(),
      slug: z.string(),
    })).max(3),
    publishedDate: z.date(),
    cluster: z.enum([
      'reconnection',
      'intimacy',
      'long-term',
      'busy-couples',
      'love-languages',
      'new-relationships',
    ]),
  }),
});

export const collections = { articles };
