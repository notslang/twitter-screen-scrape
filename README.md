# Twitter Screen Scrape
[![Build Status](http://img.shields.io/travis/slang800/twitter-screen-scrape/master.svg?style=flat-square)](https://travis-ci.org/slang800/twitter-screen-scrape) [![NPM version](http://img.shields.io/npm/v/twitter-screen-scrape.svg?style=flat-square)](https://www.npmjs.org/package/twitter-screen-scrape) [![NPM license](http://img.shields.io/npm/l/twitter-screen-scrape.svg?style=flat-square)](https://www.npmjs.org/package/twitter-screen-scrape)

A tool for scraping public data from Twitter, without needing to get permission from Twitter. It can (theoretically) scrape anything that a non-logged-in user can see. But, right now it only supports getting tweets for a given username. See `lib/post.schema.json` for details on the format of the response.

## Example
### CLI
The CLI operates entirely over STDOUT, and will output tweets as it scrapes them. The following example is truncated because the output of the real command is obviously very long... it will end with a closing bracket (making it valid JSON) if you see the full output.

```bash
$ twitter-screen-scrape --username carrot --no-retweets
[{"id":"581270694773829632","isRetweet":false,"username":"carrot","text":"Our CTO, @kylemac, speaking on the #LetsTalkCulture panel tonight @paperlesspost. pic.twitter.com/BvKrfXYhCs","time":1427420707,"images":["https://pbs.twimg.com/media/CBEWmtoVAAA5Xib.jpg:large"],"reply":0,"retweet":0,"favorite":6},
{"id":"581108534751940608","isRetweet":false,"username":"carrot","text":"For us @Carrot, @AppMeerkat is just one of many possible ways to execute a larger creative vision: http://carrot.is/blogging/industry/meerkat … via @calebkramer","time":1427382045,"images":[],"reply":0,"retweet":2,"favorite":3},
{"id":"577968951952556032","isRetweet":false,"username":"carrot","text":"T-shirts speak louder than words. Come see us @sxsw. pic.twitter.com/vvl22nvfDa","time":1426633510,"images":["https://pbs.twimg.com/media/CAVbsxIWQAAyY3R.jpg:large"],"reply":0,"retweet":0,"favorite":3},
{"id":"577885980918677504","isRetweet":false,"username":"carrot","text":"That's a lot O'Beer. Betcha can't Guinness what we're doing later...#BlackandTans pic.twitter.com/BuRyKoE9Bn","time":1426613729,"images":["https://pbs.twimg.com/media/CAUQPODWAAELrU5.jpg:large"],"reply":0,"retweet":0,"favorite":4},
```

By default, there is 1 line per tweet, making it easy to pipe into other tools. The following example uses `wc -l` to count how many tweets are returned. As you can see, I don't tweet much.

```bash
$ twitter-screen-scrape -u slang800 --no-retweets | wc -l
17
```

### JavaScript Module
The following example is in CoffeeScript.

```coffee
TwitterPosts = require 'twitter-screen-scrape'

# create the stream
streamOfTweets = new TwitterPosts(username: 'slang800', retweets: false)

# do something interesting with the stream
streamOfTweets.on('readable', ->
  # since it's an object-mode stream, we get objects from it and don't need to
  # parse JSON or anything.
  tweet = streamOfTweets.read()

  # the time field is represented in UNIX time
  time = new Date(tweet.time * 1000)

  # output something like "slang800's tweet from 8/3/2013 got 0 favorites, 0
  # replies, and 0 retweets"
  console.log "slang800's tweet from #{time.toLocaleDateString()} got
  #{tweet.favorite} favorites, #{tweet.reply} replies, and #{tweet.retweet}
  retweets"
)
```

The following example is the same as the last one, but in JavaScript.

```js
var TwitterPosts, streamOfTweets;
TwitterPosts = require('twitter-screen-scrape');

streamOfTweets = new TwitterPosts({
  username: 'slang800',
  retweets: false
});

streamOfTweets.on('readable', function() {
  var time, tweet;
  tweet = streamOfTweets.read();
  time = new Date(tweet.time * 1000);
  console.log([
    "slang800's tweet from ",
    time.toLocaleDateString(),
    " got ",
    tweet.favorite,
    " favorites, ",
    tweet.reply,
    " replies, and ",
    tweet.retweet,
    " retweets"
  ].join(''));
});
```

## Why?
The fact that Twitter requires an app to be registered just to access the data that is publicly available on their site is excessively controlling. Scripts should be able to consume the same data as people, and with the same level of authentication. Sadly, Twitter doesn't provide an open, structured, and machine readable API. They shut off their RSS & Atom feeds, and (since API v1.1) require authentication at _every_ endpoint. We've even seen Twitter decide to shut down archiving services like [TwapperKeeper](https://twapperkeeper.wordpress.com/2011/02/22/removal-of-export-and-download-api-capabilities/).

So, we're forced to use a method that Twitter cannot effectively shut down without harming themselves: scraping their user-facing site.

## Caveats
- This is probably against the Twitter TOS, so don't use it if that sort of thing worries you.
- Whenever Twitter updates certain parts of their front-end this scraper will need to be updated to support the new markup.
- You cannot get the full history in a single pass. The feed usually bottoms out around 800 tweets, so you need to scrape early and scrape often on accounts that tweet a lot, otherwise you can end up with gaps in your history. The tweets that it can't get are pretty much publicly inaccessible unless you have the ID of the tweet (which can be used to construct a URL directly to the tweet), or you are able to get the tweets using search queries.
- You can't scrape protected accounts or get engagement rates / impression counts (cause it's not public duh).
