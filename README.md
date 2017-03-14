## Barium-Ion

A controlled experiment for Google Image Search. [Barium ion is the smallest particle you can actually "see".](http://physics.stackexchange.com/questions/104523/which-is-the-smallest-known-particle-that-scientists-have-actually-seen-with-th)

### Rename Image Files for a Single Sitemap

We experiment with [sitemap-images-1-2016-02-01.xml](https://www.artsy.net/sitemap-images-1-2016-02-01.xml). Beginning indexing state 160/4996 images indexed.

![](sitemaps/sitemap-images-1-2016-02-01/2017-03-13.png)

The control group is [sitemap-images-1-2016-04-01.xml](https://www.artsy.net/sitemap-images-1-2016-04-01.xml)

![](sitemaps/sitemap-images-1-2016-04-01/2017-03-13.png)

#### Generate Slugged Files

```
AWS_ID=... AWS_SECRET=... rake sitemap:copy[sitemaps/sitemap-images-1-2016-02-01/sitemap-images-1-2016-02-01.xml]
```

This copies files from their generic name (eg. `u56wVaBVFOMFQrtf1tGOhw/larger.jpg`) to their sluggled name (eg. `u56wVaBVFOMFQrtf1tGOhw/christian-de-laubadere-lu-mi-the-murmur-of-pines-number-7.jpg`).

#### Add Slugged URLs

```
AWS_ID=... AWS_SECRET=... rake ow:config:from_env[production] sitemap:update[sitemaps/sitemap-images-1-2016-02-01/sitemap-images-1-2016-02-01.xml]
```

#### Render Slugged URLs

In [force#1006](https://github.com/artsy/force/pull/1006) we prefer slugged images on www.artsy.net.
