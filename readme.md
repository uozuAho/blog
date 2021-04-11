# My blog

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
