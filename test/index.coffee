isStream = require 'isstream'
should = require 'should'
{validate} = require 'json-schema'

TwitterPosts = require '../lib'
postSchema = require '../lib/post.schema'

describe 'tweet stream', ->
  before ->
    @stream = new TwitterPosts(username: 'slang800', retweets: false)
    @tweets = []

  it 'should return a stream', ->
    isStream(@stream).should.be.true

  it 'should stream tweet objects', (done) ->
    @timeout(4000)
    @stream.on('data', (tweet) =>
      validate(tweet, postSchema).errors.should.eql([])
      @tweets.push tweet
    ).on('end', =>
      @tweets.length.should.be.above(0)
      done()
    ).on('error', done)

  it 'should include a valid time for each tweet', ->
    # unix time values
    year2000 = 946702800
    year3000 = 32503698000

    for tweet in @tweets
      tweet.time.should.be.an.instanceOf(Number)
      (tweet.time > year2000).should.be.true
      (tweet.time < year3000).should.be.true # twitter should be dead by then

  it 'should grab photo url(s) for a tweet if it has a photo', ->
    # we know a tweet has a photo if a tweet's text contains 'pic.twitter.com'
    # unfortunately this test will fail if a video is present in a tweet
    for tweet in @tweets
      tweet.images.length.should.be.above(0) if tweet.text.indexOf('pic.twitter.com') > -1
