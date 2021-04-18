---
title: "How this site is built"
date: 2021-03-20T14:48:00+11:00
draft: false
---

I currently use [Hugo](https://gohugo.io/) to generate the site content from
markdown. The content is deployed and maintained using
[Netlify](https://www.netlify.com).

# To do
- RSS
  - https://blog.feedly.com/10-ways-to-optimize-your-feed-for-feedly/
  - allow feedly to find RSS feed from base URL
  - Get full article on feedly
- check: lighthouse report
- proof read
- update publish date & filename
- change config baseURL back to main site
- merge to main & publish


-------------------------------------------------------------------------
# Generating the site content with Hugo
Here's what I want in a blogging tool, and how [Hugo](https://gohugo.io/)
provides.

## must have
- easy to write (markdown)
- server generated syntax highlighting. Just works.
- minimal (no) JavaScript. Small HTML + CSS.
  - depends on [theme](https://themes.gohugo.io/) - there are tiny themes out
    there, like [xmin](https://github.com/yihui/hugo-xmin). I copied this into
    my repo to make my own tweaks.
- no invasive trackers like google analytics
- non-goofy home page. I don't want it to look like a Wix/Squarespace site :)
  - fully customisable with [themes](https://themes.gohugo.io/)
- good 'current' and 'archives' view
  - depends on theme. List of all posts works for now!
- URLs that don't need to change
  - Posts follow directory structure. I timestamp my posts, so the URLs
    shouldn't ever need to change.
- RSS, or however news readers work
  - [Hugo docs: RSS](https://gohugo.io/templates/rss/)
  - index.xml auto-generated
- easy to read on phone
## nice to have
- dark theme
  - I use [dark reader](https://darkreader.org) and [feedly](https://feedly.com)
    to read most sites, so pretty colours/formatting doesn't bother me that much
- article search
  - don't need it for now. Looks easy enough:
    [embedded search options](https://gohugo.io/tools/search/)


## Some more details

### Syntax highlighting
Syntax highlighting works out of the box with Hugo, and is done at build time,
resulting in smaller page sizes than bundling a JavaScript syntax highlighter
like [highlight.js](https://highlightjs.org/). For example, writing the
following markdown results in the syntax snippet below:

````
```js
const main = () => { console.log("Hello world!"); }
```
````

```js
const main = () => { console.log("Hello world!"); }
```


### Would it be easier to just write the HTML & CSS myself?
Maybe. Markdown is easier to read & edit, and Hugo generates HTML that I don't
need to tweak afterwards.

## Other static site generators considered
- [Gatsby](https://www.gatsbyjs.com/)
- [Next.js](https://nextjs.org/)

Both of these are based on React, which put me off for a simple blog that could
be hand-written in HTML. I also assumed Hugo would be faster, being written in
go.

I've also briefly used [Jekyll](https://jekyllrb.com/) with
[GitHub Pages](https://pages.github.com/). It was a bit slow, and getting it
working on GitHub took more effort than I had patience for. Also being a Windows
user, the Ruby usage put me off.

-------------------------------------------------------------------------
# Hosting with Netlify
I chose Netlify due to its management of everything I could think of, and more.
I could learn a lot by building my own infrastructure on AWS or another cloud
provider, but that's not the intention of this blog.

Here's what I want from hosting, and how [Netlify](https://docs.netlify.com/)
provides.

## must have
- custom domain with automatic renewal
- HTTPS with automatic certificate renewal
- easy deployment process
  - push to main, that's it :)
- no invasive trackers like google analytics
## nice to have
- view/review before deployment
  - can deploy branches to subdomains. See
  [branch subdomains](https://docs.netlify.com/domains-https/custom-domains/multiple-domains/#branch-subdomains).

Some extra things that Netlify provides, that I hadn't thought about:
- atomic deployments (no errors for users trying to view the page while content
  is being changed/uploaded)
- managed CDN
- domain registrations use Netlify as the WHOIS contact, keeping my personal
  contact details private from spammers. See
  [domain registration](https://docs.netlify.com/domains-https/netlify-dns/domain-registration/).

Pushing updates to this site is as simple as pushing to my
[GitHub repo](https://github.com/uozuAho/blog). Netlify watches my repo for
updates and deploys them.

I configured my Netlify site to not do any build step. I simply build my site
content locally with Hugo, include the published content in my git repo, and
push to GitHub to publish new content. This removes complication from the
publishing process. One complication I ran into was git submodules, which Hugo
uses for themes. Netlify couldn't clone my theme submodule. Instead of trying to
figure that out, I just included my theme as regular files in my repo.


# Hosting options considered
## Hugo-aware
All of these have HTTPS, deploy on push, and custom domain options. The drawback
is that you rely on their support of Hugo. For a simple blog, pushing the
rendered HTML + CSS from my dev machine seems good enough.

- [amplify](https://gohugo.io/hosting-and-deployment/hosting-on-aws-amplify/)
- [render](https://gohugo.io/hosting-and-deployment/hosting-on-render/)
  - deploy via GitHub, fully managed
- [Netlify](https://gohugo.io/hosting-and-deployment/hosting-on-netlify/)
  - deploy via GitHub, fully managed

## others
- [digital ocean app platform](https://www.digitalocean.com/community/tutorials/how-to-deploy-a-static-website-to-the-cloud-with-digitalocean-app-platform)
  - pro
    - auto CDN, HTTPS
    - deploy static content from GitHub
  - con
    - manual configuration for custom domains
- [AWS S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)
  - lots of manual steps for HTTPS, CDN, DNS
- https://www.nearlyfreespeech.net/
- https://developers.cloudflare.com/pages/getting-started
- [AWS amplify](https://aws.amazon.com/getting-started/hands-on/host-static-website/)


# References
- [Do I need a CDN?](https://blr.design/blog/cdn-for-fast-static-website/)
  - faster load times around the world
- [Creating a static home page in Hugo](https://timhilliard.com/blog/static-home-page-in-hugo/)
