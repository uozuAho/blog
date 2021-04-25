---
title: "How this site is built"
date: 2021-04-24T14:48:00+11:00
draft: false
summary: "How this site is built, using Hugo, GitHub and Netlify"
---

I currently use [Hugo](https://gohugo.io/) to generate the site content from
markdown. The content is hosted by [Netlify](https://www.netlify.com). The
source for this site is on [GitHub](https://github.com/uozuAho/blog).


-------------------------------------------------------------------------
# Generating site content
I want a simple tool that allows full control over the content I publish, and
isn't too difficult to maintain. Below are some more specifics, and how
[Hugo](https://gohugo.io/) provides.

## Must have
- easy to write (markdown)
- server generated syntax highlighting. See below for details.
- minimal (no) JavaScript. Small HTML + CSS.
  - this depends on the [Hugo theme](https://themes.gohugo.io/) you use - there
    are tiny themes out there, like [xmin](https://github.com/yihui/hugo-xmin).
    I copied this into my repo to make my own tweaks.
- no invasive trackers like google analytics
- doesn't look like a Wix/Squarespace site :)
  - published content is fully customisable with [Hugo themes](https://themes.gohugo.io/)
- An easy-to-navigate 'current' and 'archives' view
  - again, this depends on the theme. My [blog base page](..) is simply a list
    of all my posts. That works for now!
- URLs that don't need to change
  - posts follow directory structure. I timestamp my posts, so the URLs
    shouldn't ever need to change.
- RSS, or however news readers work
  - Hugo automatically generates an RSS index.xml by default
  - [Hugo docs: RSS](https://gohugo.io/templates/rss/)
  - this actually took some work to get right, see details below
- easy to read on a phone, tablet and PC
## Nice to have
- dark theme
  - I use [dark reader](https://darkreader.org) and [Feedly](https://feedly.com)
    to read most sites, so pretty colours & formatting don't bother me that much
- embedded search feature
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

### RSS
This took more effort than I expected. By default, Hugo generates an RSS feed
for your home page, and each 'section' of your site, such as ~/blog, ~/about.
I couldn't figure out how to disable this, so I ended up deleting these files
after generation in my 'publish' script. See
[this site's source](https://github.com/uozuAho/blog) for more information.

Also, Hugo's default RSS template only shows a summary of each article in the
feed, which I find annoying when reading articles via my RSS aggregator. See
[RSS: Summary or full text?](https://gretchenlouise.com/wordpress-rss-feeds-summary-full-custom)
for more information about choosing between a summary or full text in your RSS
feed.


### Would it be easier to just write the HTML & CSS myself?
Probably not. Markdown is easier to read & edit, and Hugo generates HTML that I
don't need to tweak afterwards.

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
# Hosting
I chose [Netlify](https://docs.netlify.com/) due to its easy management of
everything I could think of, and more. I could learn a lot by building my own
infrastructure on AWS or another cloud provider, but that's not the intention of
this site.

Here's what I want from hosting, and how [Netlify](https://docs.netlify.com/)
provides.

## Must have
- custom domain with automatic renewal
- HTTPS with automatic certificate renewal
- easy deployment process
  - push to main, that's it :)
- no invasive trackers like google analytics
## Nice to have
- view/review before deployment
  - Netlify has a feature that allows deploying branches to subdomains. See
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


# Other hosting options considered
## Hugo-aware
All of these have HTTPS, deploy on push, and custom domain options. The drawback
is that you rely on their support of Hugo. For a simple blog, pushing the
rendered HTML + CSS from my dev machine seems good enough.

- [AWS amplify](https://gohugo.io/hosting-and-deployment/hosting-on-aws-amplify/)
- [Render](https://gohugo.io/hosting-and-deployment/hosting-on-render/)
  - deploy via GitHub, fully managed
- [Netlify](https://gohugo.io/hosting-and-deployment/hosting-on-netlify/)
  - deploy via GitHub, fully managed

## Others
- [DigitalOcean app platform](https://www.digitalocean.com/community/tutorials/how-to-deploy-a-static-website-to-the-cloud-with-digitalocean-app-platform)
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


# References and further reading
- [Creating a static home page in Hugo](https://timhilliard.com/blog/static-home-page-in-hugo)
- [Do I need a CDN?](https://blr.design/blog/cdn-for-fast-static-website)
  - faster load times around the world
- [Feedly: optimise your RSS feed](https://blog.feedly.com/10-ways-to-optimize-your-feed-for-feedly)
- [RSS: Summary or full text?](https://gretchenlouise.com/wordpress-rss-feeds-summary-full-custom)
