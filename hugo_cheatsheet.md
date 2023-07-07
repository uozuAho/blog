# Hugo cheatsheet

## Links, references
Create a heading with a custom id:     `# Appendix: chess notation {#notation}`
    - todo: try this: https://sam.hooke.me/note/2022/09/hugo-anchors-next-to-headers/
Link to that heading in the same page: `[notation]({{< ref "#notation" >}})`
Link to another post:                  `[this post]({{< ref "20210613_mouse" >}})`
TOC:                                   `{{< toc >}}`
Reference-style links:
    Write some stuff [^1]
    [^1] any text can be here, including external links eg. google.com

## Stuff
A little highlighted section:

> Side note: some thoughts
>
> I think stuff
