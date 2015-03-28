# Twitter Screen Scraper
A tool for scraping public data from Twitter, without needing to get permission from Twitter. It can (theoretically) scrape anything that a non-logged-in user can see. But, right now it only supports getting tweets for a given username.

## Example

## Why?
The fact that Twitter requires an app to be registered just to access the data that is publicly available on their site is excessively controlling. Scripts should be able to consume the same data as people, and with the same level of authentication. Sadly, Twitter doesn't provide an open, structured, and machine readable API. They shut off their RSS & Atom feeds, and (since API v1.1) require authentication at _every_ endpoint. We've even seen Twitter decide to shut down archiving services like [TwapperKeeper](https://twapperkeeper.wordpress.com/2011/02/22/removal-of-export-and-download-api-capabilities/).

So, we're forced to use a method that Twitter cannot effectively shut down without harming themselves: scraping their user-facing site.

## Caveats
- This is probably against the Twitter TOS, so don't use it if that sort of thing worries you.
- Whenever Twitter updates certain parts of their front-end this scraper will need to be updated to support the new markup.
- You cannot get the full history in a single pass. The feed usually bottoms out around 800 tweets, so you need to scrape early and scrape often on accounts that tweet a lot, otherwise you can end up with gaps in your history. The tweets that it can't get are pretty much publicly inaccessible unless you have the ID of the tweet (which can be used to construct a URL directly to the tweet), or you are able to get the tweets using search queries.
- You can't scrape protected accounts or get engagement rates / impression counts (cause it's not public - duh).
