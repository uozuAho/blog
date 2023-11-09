# My blog

[![Netlify Status](https://api.netlify.com/api/v1/badges/3e5e1592-f32d-4243-9705-4bce7636ce80/deploy-status)](https://app.netlify.com/sites/objective-borg-f6eb56/deploys)

This is the source of my site: https://iamwoz.com

# Local dev
Install:
- [Hugo](https://gohugo.io/)
- node 12 (this is the version netlify uses)
- (optional) [Spell Right VS Code plugin](https://github.com/bartosz-antosik/vscode-spellright)

```sh
# start a new post
./newpost.sh my_super_duper_post
# run local dev server (-D to show drafts)
hugo server -D
# or, run local dev server, accessible on the local network
hugo server -D --bind 0.0.0.0
# if using Netlify functions
ntl dev -c "hugo server -D"
```


# Publish to the web
```sh
# build content & put in public/
# publish.sh lists more steps like proof reading, lighthouse etc.
./publish.sh
# publish to web - simples!
git push
```


# todo
- remove netlify functions, make this site totally static
    - removes netlify build & node dependencies
- include only links in rss
- make inline code like `this` prettier
- display tags
  - in post
  - in post list
  - page of all tags?
- light syntax highlighting for light mode
- how to find links to my posts?
- find dead links
- any SEO I should be doing?
- hello
