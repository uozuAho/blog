# My blog

[![Netlify Status](https://api.netlify.com/api/v1/badges/3e5e1592-f32d-4243-9705-4bce7636ce80/deploy-status)](https://app.netlify.com/sites/objective-borg-f6eb56/deploys)

This is the source of my site: https://iamwoz.com/

# Local dev
Install [hugo](https://gohugo.io/). Then:

```sh
# run local dev server
hugo server -D
# or, run local dev server, accessible on the local network
hugo server -D --bind 0.0.0.0
```

# Spell check
I use [hunspell](https://hunspell.github.io/) via [WSL](https://docs.microsoft.com/en-us/windows/wsl/install-win10).

eg.

```sh
hunspell -d en_GB -p /mnt/c/woz/hugo_test/spelling_dict.md /mnt/c/woz/hugo_test/content/blog/20200320_how_this_blog_is_built.md
```

# Publish to the web
```sh
# build content & put in public/
hugo
# publish to web - simples!
git push
```
