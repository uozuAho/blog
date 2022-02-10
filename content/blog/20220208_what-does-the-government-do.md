---
title: "What does the government do?"
date: 2022-02-08T21:00:33+11:00
draft: false
summary: "I made a site that quickly shows party's stances on policy issues"
tags:
- government
- netlify
---

For the upcoming Australian federal election, I want a quick summary view of
what politicians have been doing in their time in office, so I can decide if I
want to vote for them or not. I am physically incapable of listening to
politicians speak, and watching the news is a pretty inefficient way of finding
this information.

Thankfully, [They Vote For You](theyvoteforyou.org.au/) does a lot of hard work
to summarise what politicians are voting for in parliament. They get their data
from the [Australian parliament](https://www.aph.gov.au/), which, also
thankfully, publishes a lot of information about what is going on.

They Vote For You makes it easy to see what your representatives are voting for,
but doesn't make it easy to see each party's stance on an issue. This is where
[my site](https://what-does-the-government-do.netlify.app/) comes in. It uses
data provided by They Vote For You to show voting records at a party level.

Have a go! https://what-does-the-government-do.netlify.app/

<figure>
  <img src="/blog/20220208_what-does-the-government-do/20220208_votes_for_coal.png"
  alt=""
  width="1027"
  loading="lazy" />
  <figcaption>The Greens are the only sane party, right?</figcaption>
</figure>

It's not perfect - the votes recorded are from
[divisions](https://theyvoteforyou.org.au/help/faq#division), which only make up
a small minority of all the votes happening parliament. There is plenty more
information published by the Australian parliament, but it's nowhere near as
concise as the information here.


## Technical details
I used Netlify Functions to access the They Vote For You APIs. See [my post on
Netlify Functions]({{< ref "20220126_netlify-functions" >}}).

I ended up writing the HTML myself. Hugo & other static site generators all seem
to be most easily used to create blogs. I got frustrated trying to create a
custom site with Hugo. I kinda regret this choice, as there's already a lot of
duplication between pages, but at least it was simple-ish to put together.

I intended to write all the CSS myself, but quickly gave up and went with
[Bootstrap](https://getbootstrap.com/). My initial version had no styling, and
my first "hallway usability test" failed dismally with my partner asking "Is it
supposed to look like this? It looks broken." :P
