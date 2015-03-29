should = require 'should'
isStream = require 'isstream'

scrape = require '../lib'

describe 'tweet stream', ->
  before ->
    @stream = scrape(username: 'slang800', retweets: false)
    @tweets = []

  it 'should return a stream', ->
    isStream(@stream).should.be.true

  it 'should stream tweet objects', (done) ->
    @timeout(4000)
    @stream.on('readable', =>
      tweet = @stream.read()
      tweet.should.be.an.instanceOf(Object)
      @tweets.push tweet
    ).on('end', ->
      done()
    )
