#
# 採集文章
#
moment = require 'moment'
config = require 'config'
_ = require 'underscore'
Promise = require 'bluebird'
cheerio = require 'cheerio'

log = require __base + '/common/util/log'
superagentUtil = require __base + '/common/util/superagent-util'
NewDB = require __base + '/common/helpers/new'

new_name = '南方快报'
new_type = '新闻'

new_urls = [
    'http://kb.southcn.com/default.htm'
  ,
    'http://kb.southcn.com/default_2.htm'
  ,
    'http://kb.southcn.com/default_3.htm'
  ,
    'http://kb.southcn.com/default_4.htm'
  ,
    'http://kb.southcn.com/default_5.htm'
  ,
    'http://kb.southcn.com/default_6.htm'
  ,
    'http://kb.southcn.com/default_7.htm'
  ,
    'http://kb.southcn.com/default_8.htm'
  ,
    'http://kb.southcn.com/default_9.htm'
  ,
    'http://kb.southcn.com/default_10.htm'
]


module.exports = ->
  interval()

interval = ->
  Promise.resolve()
  .then ->
    _.reduce new_urls, (promise, new_url, i) ->
      promise.then ->
        findNews(new_url)
      .delay(1000 * 2)
    , Promise.resolve()
  .catch (error) ->
    log ' [news.coffee] [Function] [interval] ' + error
  .delay 1000 * 60 * 1
  .then interval

findNews = (new_url) ->

  Promise.resolve()
  .then ->
    option = 
      url: new_url
    superagentUtil.findPage(option)
  .then (res) ->
    $ = cheerio.load(res.text,
      normalizeWhitespace: false
      xmlMode: false,
      decodeEntities: false
    )
    newObjs = [] 
    _.each $('ul.list li'), (el) ->
      option =
        article_title: $(el).find('a h3').text().trim()
        article_url: $(el).find('a').eq(0).attr('href')
        article_cover_image: $(el).find('a').eq(0).find('img').attr('data-src')
        article_abstract: $(el).find('a p.abstract').text().trim()
      newObjs.push option
    newObjs
  .then (newObjs) ->
    eachNews(newObjs)
  .catch (error) ->
    log ' [news.coffee] [Function] [finNews] ' + error

eachNews = (newObjs) ->

  Promise.resolve()
  .then ->
    _.reduce newObjs, (promise, newObj, i) ->
      promise.then ->
        findContent(newObj)
      .delay(1000 * 2)
    , Promise.resolve()
  .catch (error) ->
    log ' [news.coffee] [Function] [finNews] ' + error

findContent = (newObj) ->
  Promise.resolve()
  .then ->
    option = 
      url: newObj.article_url
    superagentUtil.findPage(option)
  .then (res) ->
    $ = cheerio.load(res.text,
      normalizeWhitespace: false
      xmlMode: false,
      decodeEntities: false
    )
    newObj.new_name = new_name
    newObj.new_type = new_type
    newObj.article_datestr = $('.pub_time').eq(0).text().trim()
    newObj.article_date = moment(newObj.article_datestr).format('YYYY-MM-DD HH:mm:ss')
    newObj.article_source = $('#source_baidu a').text().trim()
    newObj.article_content = $('.content').html()

    NewDB.create(newObj)
  .catch (error) -> 
    log ' [news.coffee] [Function] [finNews] ' + error

