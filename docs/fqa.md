# Pleroma Frequently Questioned Answers


## What is Pleroma?

Pleroma is an implementation of
[ActivityPub](https://www.w3.org/tr/activitypub), providing a simple and usable
homeserver for interactions with the
[fediverse](https://en.wikipedia.org/wiki/Fediverse).  Pleroma has rich support
for different types of ActivityStreams objects, and this flexibility, coupled
with a low resource footprint, makes it a system suitable for a variety of
usecases.

For most people, though, it's just a place to shitpost.


### Pleroma is not Mastodon

It's true, Pleroma is not Mastodon.

And if you come to the project expecting it to work the same way as Mastodon,
you might find yourself getting frustrated when something seems "broken" or
"missing".  Usually this is just because the feature you're looking for has
been implemented in a different way.  It may take some getting used to, but if
you're open to viewing Pleroma as a system in its own right, and not just as a
"Mastodon clone", you may find that there's some logic to all this nonsense.

Despite these differences, Pleroma developers have chosen to support the
majority of the Mastodon 2.6 API and some of the upcoming 2.7 APIs as well.
This allows us to leverage the existing rich mobile app ecosystem, which
includes things like [Tusky](https://tuskyapp.github.io/) and
[Mastalab](https://mastalab.app/).  In addition, for the convenience of new
users (or those who simply prefer it), the Mastodon Web Client is available
bundled alongside the default front end. You can find it at
`<website-name.tld>/web` (in the same place where Mastodon puts it).


### Pleroma is not GNU Social

While Pleroma doesn't aim to copy Mastodon, it's also not a GNU Social clone.  At
present, the GNU Social API *is* supported via an emulation layer.  However,
this API has been deprecated and will eventually be removed, once all
clients have been ported to either the Mastodon or ActivityPub C2S APIs.

Some confusion over the relationship between Pleroma and GNU Social also comes
from a historical relationship between the two, as the first Pleroma FE client
prototypes communicated with GNU Social as a backend.  This was done to avoid a
chicken-and-egg situation, where a nice backend server is no fun to write if it
doesn't have a frontend, but a frontend can't connect to anyone without a
backend.

Because GNU Social development has since stagnated, and because scripts exist
for migrating GNU Social servers over to Pleroma, many GNU Social instances
have decided to switch.


### Someone told me Pleroma was developed by Nazis!

![Go away.](data/go-away.jpg)

Pleroma is not developed by nazis.  In fact, the Pleroma development team has
widely been recognized as being one of the most diverse and LGBT-inclusive in
FOSS today.

An unfortunate side effect of making accessible technologies is that anyone at
all can use them. Even people with unpopular political views.


### So if it's not nazis, what is the Pleroma community in a nutshell?

We provide a short infomercial, encoded as a ROM for the  Super Nintendo
Entertainment System, which we hope will answer that question for you clearly
and succinctly.

To view it:

1. download [this file](data/badapple.sfc)
2. flash it to a Super Everdrive developer cartridge
3. insert it into an NTSC Super Nintendo Entertainment System
4. plug an SNES RGB cable (by [@amic@nulled.red](https://nulled.red/@amic)) into your television, and
5. turn the NTSC Super Nintendo Entertainment System on.

You will quickly find out everything you need to know.

(Note: If your Super Everdrive is a clone, or if you don't happen to be  in the
habit of collecting decades-old game consoles, it's also possible to use an
emulator like [RetroArch](https://www.retroarch.com/) or
[higan](https://byuu.org/emulation/higan/) instead)


## Why should I use Pleroma?

Because you can install it on a Raspberry Pi and host an instance over your
mom's DSL connection.

Because the message filtering tools actually work.

Because post deletions are actually somewhat deniable.

Because you think [Lain](https://blog.soykaf.com/) is a bretty cool guy
(girl?).

Because you like having to learn how to admin PostgreSQL in order to fix your
instance without losing all its data.

Because you want to make friends.

If you're still not convinced then check out this [informative blog post about
it](https://blog.soykaf.com/post/what-is-pleroma/)!

Whatever your reasons, just give it a try!  And may your memes remain forever
dank (^_^).


## Why did you call it "Pleroma"?

There's quite a lot to unpack here, so we'll stick with the shortened version.

In his writings, Carl Jung uses the term Pleroma to refer to the concept of
"nothing and everything."  We've taken this as being a pre-cognisant reference
to Pleroma's design: it's only backend server, and so is nothing on its own.
To make any use of it, you also need to have a client (like [Pleroma
FE](https://git.pleroma.social/pleroma/pleroma-fe), which is usually included).

Alone, Pleroma is powerless.  But in context it's the vital piece that holds
the network together.

Behind this (maybe self-aggrandising) Jungian reference is another
(self-aggrandising) reference to Gnosticism.  For Gnostics, Pleroma is defined
as "the totality of divine powers."  How this reflects on our views toward the
fediverse at large is completely open to interpretation.

### How do you spell "Pleroma"?
*** this section is non-normative ***

Recurring joke which probably comes from misspells of pleroma,
for example: plemora.

The current ways to write theses is:
- in regex form: ``/(pleb|[bp][lrm])([aeo][lrm]){3}[lrm]?/i``
- in shell brace-expansion form: ``{pleb,{b,p}{{l,r,m},}{a,e,o}}{l,r,m}{a,e,o}{l,r,m}{a,e,o}{l,r,m,}``


## Administrative Concerns

### How can I find out who runs a Pleroma instance?

You can retrieve a full list of instance staff by requesting the instance's
[NodeInfo](https://nodeinfo.diaspora.software/), which can be usually found
somewhere like `/nodeinfo/2.0.json`.

You can also search through NodeInfo data that've been collected by crawlers
such as [fediverse.network](https://fediverse.network/), and this is probably
the easier option for most people.  In fact, since we've plugged
fediverse.network here, it's likely they'll add a staff listing feature based
on the NodeInfo data they already collect (hint hint).

And if all else fails, Pleroma will also be getting an `/about` page very soon,
where instances can show all this information and more.


### How do I find a list of configuration options for Pleroma?

You can view the documentation for config options
[here](https://git.pleroma.social/pleroma/pleroma/blob/develop/docs/config.md).


### How do I block an instance?

Instance blocking is one of the primary functions delegated to MRF (the Message
Rewrite Facility).  MRF is a modular system which decides how incoming and
outgoing posts should be filtered, changed, or otherwise processed.  It allows
a lot of flexibility, but can be a little complicated at first.

How to use the built in MRF modules to perform common tasks is a topic covered
in the [Pleroma wiki][mrf].

   [mrf]: https://git.pleroma.social/pleroma/pleroma/wikis/Message%20rewrite%20facility%20configuration%20(how%20to%20block%20instances)


### How do I federate with the "Dark Web"?

![Dark web](data/dark-web.jpg)

(pictured: a super scary Dark Web hackerman)

Federation with Tor .onion nodes and I2P .i2p nodes is fully supported.

A tutorial on how to configure Pleroma to federate with them (through built-in
SOCKS proxies) is available in the [Pleroma wiki][dark-web].

   [dark-web]: https://git.pleroma.social/pleroma/pleroma/wikis/I2p%20federation


### An instance I blocked is still getting messages from my instance!

This problem is, unfortunately, due to a security flaw in ActivityPub's design.
At present, ActivityPub's object fetching is completely unauthenticated,
meaning that blocks can't be enforced because your instance has no idea who it
is who's actually fetching the objects.

Various solutions have been suggested, and this might be one of the few (out of
*many*) ActivityPub leaks to actually get plugged, so please stay tuned.