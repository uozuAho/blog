# My blog

[![Netlify Status](https://api.netlify.com/api/v1/badges/3e5e1592-f32d-4243-9705-4bce7636ce80/deploy-status)](https://app.netlify.com/sites/objective-borg-f6eb56/deploys)

This is the source of my site: https://iamwoz.com

# Local dev
Install:
- [Hugo](https://gohugo.io/)
- (optional) [Spell Right VS Code plugin](https://github.com/bartosz-antosik/vscode-spellright)
- start a new post `./newpost.sh my_super_duper_post`

```sh
# run local dev server (-D to show drafts)
hugo server -D
# or, run local dev server, accessible on the local network
hugo server -D --bind 0.0.0.0
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
- light syntax highlighting for light mode
- percy: how to compare branch vs main?
- how to find links to my posts?
- any SEO I should be doing?
- site/blog info missing on feedly
