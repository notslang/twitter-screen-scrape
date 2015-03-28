Readable = require('stream').Readable
jsdom = require 'jsdom'
nodefn = require 'when/node'
request = require 'request-promise'
bigint = require 'bignum'

###*
 * Make a request for a Twitter page, parse the response, and get all the tweet
   elements.
 * @param {String} username
 * @param {String} [startingId] The maximum tweet id query for (the lowest one
   from the last request), or undefined if this is the first request.
 * @return {Array} An array of elements.
###
getPostElements = (username, startingId) ->
  request.get(
    uri: "https://twitter.com/i/profiles/show/#{username}/timeline"
    qs:
      'max_id': startingId
  ).then((response) ->
    html = JSON.parse(response)['items_html']
    nodefn.call(jsdom.env, html)
  ).then((window) ->
    # query to get all the tweets out of the DOM
    window.document.querySelectorAll('.Grid[data-component-term="tweet"]')
  )

###*
 * Given a list of tweet ids, find the lowest one. Tweet ids are just big ints.
   So, although they do get screwed up if manupulated as floats, we can use
   bigint to compare them & find the lowest.
 * @param {Array} ids
 * @return {String} A string representing the lowest id
###
getMinTweetId = (ids) ->
  minId = undefined
  for id in ids
    id = bigint(id)
    minId ?= id
    if id.lt(minId) then minId = id
  return minId.toString()

###*
 * Scrape as many tweets as possible for a given user.
 * @param {String} options.username
 * @param {Boolean} options.retweets Whether to include retweets.
 * @return {Stream} A stream of tweet objects.
###
module.exports = ({username, retweets}) ->
  actions = ['reply', 'retweet', 'favorite']
  output = new Readable(objectMode: true)
  output._read = (->) # prevent "Error: not implemented" with a noop

  scrapeTwitter = (username, startingId) ->
    getPostElements(username, startingId).then((elements) ->
      scrapedIds = []
      for element in elements
        # we get the id & add it to scrapedIds before skipping retweets because
        # the lowest id might be a retweet, or all the tweets in this page might
        # be retweets
        id = element.querySelector('.StreamItem').getAttribute('data-item-id')
        scrapedIds.push id

        isRetweet = element.querySelector('.js-retweet-text') isnt null
        if not retweets and isRetweet
          continue # skip retweet

        post = {
          id: id
          isRetweet: isRetweet
          username: username
          text: element.querySelector('.ProfileTweet-text').textContent
          time: +element.querySelector('.js-short-timestamp').getAttribute('data-time') * 1000
          images: []
        }

        for action in actions
          wrapper = element.querySelector(
            ".ProfileTweet-action--#{action} .ProfileTweet-actionCount"
          )
          post[action] = (
            if wrapper isnt null
              +wrapper.getAttribute('data-tweet-stat-count')
            else
              0
          )

        pics = element.querySelectorAll(
          '.TwitterMultiPhoto-image img, .TwitterPhoto-mediaSource'
        )
        for pic in pics
          post.images.push pic.getAttribute('src')

        output.push post

      return scrapedIds
    ).then((scrapedIds) ->
      if scrapedIds.length isnt 0
        return scrapeTwitter(username, getMinTweetId(scrapedIds))
      else
        output.push(null)
        return
    )

  scrapeTwitter(username)
  return output
