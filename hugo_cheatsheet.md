# Hugo cheatsheet

## Links, references
- Create a heading with a custom id:     `# Appendix: chess notation {#notation}`
    - todo: try this: https://sam.hooke.me/note/2022/09/hugo-anchors-next-to-headers/
- Link to that heading in the same page: `[notation]({{< ref "#notation" >}})`
- Link to another post:                  `[this post]({{< ref "20210613_mouse" >}})`
- TOC:                                   `{{< toc >}}`
- Footnotes / reference-style links:
    - Write some stuff in your post, with an inline reference: [^1]
    - Define the reference somewhere, eg. at the end of the post, like this (no dot points):
    [^1] any text can be here, including external links eg. google.com

## Images
- put images in static/blog/<post>
- generate figure links by running `./utils/print_image_html.sh "static/blog/<post>/*"`
- copy paste output to post

## Quotes
A little highlighted section/quote:

> Side note: some thoughts
>
> I think stuff
