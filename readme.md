# My blog

[![Netlify Status](https://api.netlify.com/api/v1/badges/3e5e1592-f32d-4243-9705-4bce7636ce80/deploy-status)](https://app.netlify.com/sites/objective-borg-f6eb56/deploys)

# Local dev
Install [hugo](https://gohugo.io/). Then:

```sh
# run local dev server
hugo server -D
# or, run local dev server, accessible on the local network
hugo server -D --bind 0.0.0.0
```

# Publish to the web

```sh
# build content & put in public/
hugo
# publish to web - simples!
git push
```
