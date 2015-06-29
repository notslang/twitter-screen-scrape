# see http://r.va.gg/2014/06/why-i-dont-use-nodes-core-stream-module.html for
# why we use readable-stream
Readable = require('readable-stream').Readable
cheerio = require 'cheerio'
request = require 'request-promise'

ACTIONS = ['reply', 'retweet', 'favorite']

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
      'max_position': startingId
  )

###*
 * Stream that scrapes as many tweets as possible for a given user.
 * @param {String} options.username
 * @param {Boolean} options.retweets Whether to include retweets.
 * @return {Stream} A stream of tweet objects.
###
class TwitterPosts extends Readable
  _lock: false
  _minPostId: undefined

  constructor: ({@username, @retweets}) ->
    @retweets ?= true
    # remove the explicit HWM setting when github.com/nodejs/node/commit/e1fec22
    # is merged into readable-stream
    super(highWaterMark: 16, objectMode: true)

  _read: =>
    # prevent additional requests from being made while one is already running
    if @_lock then return
    @_lock = true
    hasMorePosts = undefined

    # we hold one post in a buffer because we need something to send directly
    # after we turn off the lock
    lastPost = undefined

    getPostElements(@username, @_minPostId).then((response) ->
      response = JSON.parse(response)
      html = response['items_html']
      hasMorePosts = response['has_more_items']
      cheerio.load(html)
    ).then(($) =>
      # query to get all the tweets out of the DOM
      for element in $('.original-tweet')
        # we get the id & set it as _minPostId before skipping retweets because
        # the lowest id might be a retweet, or all the tweets in this page might
        # be retweets
        id = $(element).attr('data-item-id')
        @_minPostId = id # only the last one really matters

        isRetweet = $(element).find('.js-retweet-text').length isnt 0
        if not @retweets and isRetweet
          continue # skip retweet

        post = {
          id: id
          isRetweet: isRetweet
          username: @username
          text: $(element).find('.tweet-text').first().text()
          time: +$(element).find('.js-short-timestamp').first().attr('data-time')
          images: []
        }

        for action in ACTIONS
          wrapper = $(element).find(
            ".ProfileTweet-action--#{action} .ProfileTweet-actionCount"
          )
          post[action] = (
            if wrapper.length isnt 0
              +$(wrapper).first().attr('data-tweet-stat-count')
            else
              undefined
          )

        pics = $(element).find(
          '.multi-photos .multi-photo[data-url],
          [data-card-type=photo] [data-url]'
        )
        for pic in pics
          post.images.push $(pic).attr('data-url')

        if lastPost? then @push(lastPost)
        lastPost = post

      if hasMorePosts then @_lock = false
      @push(lastPost)
      if not hasMorePosts then @push(null)
    )

module.exports = TwitterPosts
