---
title: "Adding dynamic content to a Hugo site with Netlify Functions"
date: 2022-01-26T12:55:48+11:00
draft: false
summary: "A guide on how to add Netlify Functions to an existing Hugo site"
tags:
- serverless
- Netlify
---

So far this site has just been static, pre-built pages (built by
[Hugo](https://gohugo.io/)). I now want to load and display information from
other sites & services. I settled on using [Netlify
Functions](https://www.netlify.com/products/functions/) to create endpoints that
I could use to load data into this site's pages.

This post's a tutorial for my future self and others :)


## Options
[Netlify Functions](https://www.netlify.com/products/functions/) allows you to
write web API endpoints just as easily as the rest of your static site content:
Write a function in the netlify/functions directory, push it to GitHub, done!

Being a little wary of 'vendor lock-in', I had a quick look to see if there were
any services that would let me run containers as easily as Netlify functions.
[AWS Fargate](https://aws.amazon.com/fargate/) came close, but it still can't
compete with the simplicity of Netlify functions. There's really not much being
locked in anyway - no infrastructure code, scaling configuration, etc. It will
be easy to move to a more powerful platform in the future, if I need to.


## Let's do it
These steps assume you've got a Hugo site up and running on Netlify. I've got
some details about how to do  that in my first post - [how this site is
built]({{< ref "20210424_how_this_site_is_built" >}}). That post doesn't really
clearly tell you how the site is built, but it's a start :)

```sh
# install the netlify cli
npm i -g netlify-cli
# link your project to your netlify site
ntl link
# create an example function
ntl functions:create
```

This creates a function in your site that you can call from your site pages.
Here's the default TypeScript code that gets created:

```ts
import { Handler } from '@netlify/functions'

export const handler: Handler = async (event, context) => {
  const { name = 'stranger' } = event.queryStringParameters

  return {
    statusCode: 200,
    body: JSON.stringify({
      message: `Hello, ${name}!`,
    }),
  }
}
```

By default, functions are placed under `./netlify/functions` directory in your
site. Once there, they can be called from within your page content. For example,
let's replace some text with the response from the function when a button is
pressed:

```html
<p id="static_text">static text</p>
<button onclick="replaceText()">Replace static text</button>

<script>
  async function replaceText() {
    const response = await fetch('/.netlify/functions/hello-world?name=stinky')
      .then(response => response.json());

    document.getElementById('static_text').innerText = response.message;
  }
</script>
```

You can run the site locally with `ntl dev` (`ntl dev -c "hugo server -D"` to
show draft content). The Netlify CLI detects Hugo and runs that too, so site
content and functions are updated whenever you change them.

Here's the above code in action:

--------------------------------

<p id="some_id">static text</p>
<button onclick="replaceText()">Replace static text</button>

<script>
  async function replaceText() {
    const response = await fetch('/.netlify/functions/hello-world?name=stinky')
      .then(response => response.json());

    document.getElementById('some_id').innerText = response.message;
  }
</script>

--------------------------------

If you open your browser dev tools and click the button, you'll see the text
is being loaded via a network call to the hello-world API!


## Deployment
Deployment 'just works'. There's no need to build containers, publish artifacts,
provision any infrastructure - your functions are useable as endpoints simply by
deploying your site as usual!

The 'hello world' endpoint used above is accessible here:
https://iamwoz.com/.netlify/functions/hello-world


## Hiding secrets with environment variables
The example above is trivial, and doesn't really need a web API - it could all
be done with JavaScript within the page. Here's a more realistic use case.

Say you want to use a 3rd party API that needs an API key. You could directly
call the API from the frontend, but that would mean exposing your API key for
all to see.

A way around this is to create your own API that hides the 3rd party API key
value. This can be done using Netlify's environment variables:

```sh
ntl env:set EXAMPLE_SECRET my-secret-value
```

I'll create a separate API that loads and returns the secret, using `ntl
functions:create`. I called the function `get-secret`. I modified the function
to this:

```ts
import { Handler } from '@netlify/functions'

export const handler: Handler = async (event, context) => {
  const secret = process.env.EXAMPLE_SECRET;

  return {
    statusCode: 200,
    body: `my secret value is: ${secret}`
  }
}
```

Here's the same 'click a button to replace text' example as before, but using
the environment variable:

```html
<p id="secret_p">Shhh....</p>
<button onclick="showSecretValue()">Show the secret!</button>

<script>
  async function showSecretValue() {
    const response = await fetch('/.netlify/functions/get-secret')
      .then(response => response.text());

    document.getElementById('secret_p').innerText = response;
  }
</script>
```

<p id="secret_p">Shhh....</p>
<button onclick="showSecretValue()">Show the secret!</button>

<script>
  async function showSecretValue() {
    const response = await fetch('/.netlify/functions/get-secret')
      .then(response => response.text());

    document.getElementById('secret_p').innerText = response;
  }
</script>


## Further reading
I got most of the information for this post from [this Netlify
tutorial](https://explorers.netlify.com/learn/up-and-running-with-serverless-functions/)
There's plenty more tutorials here: https://functions.netlify.com/tutorials/
