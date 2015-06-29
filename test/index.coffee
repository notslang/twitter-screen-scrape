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
    @stream.on('data', (tweet) =>
      tweet.should.be.an.instanceOf(Object)
      @tweets.push tweet
    ).on('end', =>
      @tweets.length.should.be.above(0)
      done()
    )

  it 'should include a valid time for each tweet', ->
    # unix time values
    year2000 = 946702800
    year3000 = 32503698000

    for tweet in @tweets
      tweet.time.should.be.an.instanceOf(Number)
      (tweet.time > year2000).should.be.true
      (tweet.time < year3000).should.be.true # twitter should be dead by then
