#
# 分詞工作進程
#

WordFreq = require 'wordfreq'
_s = require 'underscore.string'

process.on 'message', (message, minimumCount) ->
  {content, stopWords, minimumCount} = message

  content = _s.stripTags content
  stopWords or= []
  stopWords = stopWords.concat [
    'nbsp'
    'gt'
  ]

  process.send
    words: do ->
      WordFreq
        stopWords: stopWords
        minimumCount: minimumCount#2
      .process content

process.on 'SIGHUP', ->
  process.exit()
