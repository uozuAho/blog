---
title: "How this blog is built"
date: 2021-03-20T14:48:00+11:00
draft: true
---

# How this blog is built
I currently use [hugo](https://gohugo.io/), a static site generator. I write
posts in markdown, and hugo publishes as HTML.

# Tooling requirements
Here's what I want in a blogging tool, and how hugo provides.

## must have
- [x] easy to write (markdown)
- [x] server generated syntax highlighting. Just works.
- [x] minimal (no) js. Small HTML + CSS.
  - depends on theme - there are tiny themes out there, like
    [xmin](https://github.com/yihui/hugo-xmin). I forked this to make my own
    tweaks.
- [x] no kitchen sink trackers like google analytics etc.
- [x] non-goofy home page
  - depends on theme
- [x] good 'current' and 'archives' view
  - depends on theme. List of all posts works for now!
- [x] urls that don't need to change
  - Posts follow directory structure. I timestamp my posts, so the URLs
    shouldn't ever need to change.
- [x] rss, or however news readers work
  - [hugo docs: rss](https://gohugo.io/templates/rss/)
  - index.xml auto-generated
- [x] easy to read on phone
## nice to have
- article search
  - don't need it for now. Looks easy enough:
    [embedded search options](https://gohugo.io/tools/search/)


# Hosting requirements
## must have
- custom domain
- HTTPS with automated cert renewal
- easy deployment process
- no kitchen sink trackers like google analytics etc.
## nice to have
- view/review before deployment


# Some more details

## Syntax highlighting
Syntax highlighting works out of the box with hugo, and is done at build time,
resulting in smaller page sizes than bundling a js syntax highlighter like
[highlight.js](https://highlightjs.org/). For example, writing the following
markdown results in the syntax snippet below:

````
```js
const main = () => { console.log("Hello world!"); }
```
````

```js
const main = () => { console.log("Hello world!"); }
```


# Would it be easier to just write the HTML & CSS myself?
Maybe. Markdown is easier to read & edit, and hugo generates HTML that I don't
need to tweak afterwards.


# Other static site generators considered
- [gatsby](https://www.gatsbyjs.com/)
- [nextjs](https://nextjs.org/)

Both of these are based on React, which put me off for a simple blog that could
be hand-written in HTML. I also assumed hugo would be faster, being written in
go.

I've also briefly used [Jekyll](https://jekyllrb.com/) with
[GitHub Pages](https://pages.github.com/). It was a bit slow, and getting it
working on GitHub took more effort than I had patience for. Also being a Windows
user, the Ruby usage put me off.


# hosting options
## hugo-aware
All of these have https, deploy on push, custom domain options. The drawback is
that you rely on their support of hugo. For a simple blog, pushing the rendered
html + css from my dev machine seems good enough.

- [amplify](https://gohugo.io/hosting-and-deployment/hosting-on-aws-amplify/)
- [render](https://gohugo.io/hosting-and-deployment/hosting-on-render/)
  - deploy via github, fully managed
- [netlify](https://gohugo.io/hosting-and-deployment/hosting-on-netlify/)
  - deploy via github, fully managed
  - limited by netlify hugo support, eg. themes

## others
- [netlify](https://docs.netlify.com/)
  - pro
    - auto CDN, HTTPS, manged custom domain renewals
    - hides personal details in domain registration
- [digital ocean app platform](https://www.digitalocean.com/community/tutorials/how-to-deploy-a-static-website-to-the-cloud-with-digitalocean-app-platform)
  - pro
    - auto CDN, HTTPS
    - deploy static content from github
  - con
    - manual configuration for custom domains
- [aws s3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)
  - lots of manual steps for HTTPS, CDN, DNS
- https://www.nearlyfreespeech.net/
  - pro
    - hides personal details in domain registration
- https://developers.cloudflare.com/pages/getting-started
- [aws amplify](https://aws.amazon.com/getting-started/hands-on/host-static-website/)


# To do
- hosting
- favicon
- top bar: home, about
- check: rss reader can read site?


# References
- [do I need a CDN?](https://blr.design/blog/cdn-for-fast-static-website/)
  - faster load times around the world
- [Creating a static home page in Hugo](https://timhilliard.com/blog/static-home-page-in-hugo/)