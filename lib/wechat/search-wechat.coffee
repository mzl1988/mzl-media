moment = require 'moment'
_ = require 'underscore'
Promise = require 'bluebird'
cheerio = require 'cheerio'

config = require 'config'
log = require __base + '/common/util/log'
superagentUtil = require __base + '/common/util/superagent-util'
WechatDB = require __base + '/common/helpers/wechat'

module.exports = ->
  if config.search.start
    search()

search = ->
  Promise.resolve()
  .then ->
    _.reduce config.search.keywords, (promise, keyword, i) ->
      promise.then ->
        log "#{++i} [#{keyword}]"
        createUrls(keyword)
      .delay 1000 * 5
    , Promise.resolve()
  .catch (error) ->
    log ' [search-wechat.coffee] [Function] [search] ' + error

createUrls = (keyword) ->
  Promise.resolve()
  .then ->
    urls = [
        "http://weixin.sogou.com/weixin?type=1&query=#{keyword}&fr=sgsearch&ie=utf8&_ast=1427717504&_asf=null&w=01029901&cid=null"
      ,
        "http://weixin.sogou.com/weixin?type=1&query=#{keyword}&fr=sgsearch&ie=utf8&_ast=1427717504&_asf=null&w=01029901&cid=null&page=2"
      ,
        "http://weixin.sogou.com/weixin?type=1&query=#{keyword}&fr=sgsearch&ie=utf8&_ast=1427717504&_asf=null&w=01029901&cid=null&page=3"
      ,
        "http://weixin.sogou.com/weixin?type=1&query=#{keyword}&fr=sgsearch&ie=utf8&_ast=1427717504&_asf=null&w=01029901&cid=null&page=4"
      ,
        "http://weixin.sogou.com/weixin?type=1&query=#{keyword}&fr=sgsearch&ie=utf8&_ast=1427717504&_asf=null&w=01029901&cid=null&page=5"
    ]
  .then (urls) ->
    _.reduce urls, (promise, url, i) ->
      promise.then ->
        findWechats(url)
      .delay 1000 * 3
    , Promise.resolve()
  .catch (error) ->
    log ' [search-wechat.coffee] [Function] [createUrls] ' + error


findWechats = (url) ->
 
  Promise.resolve()
  .then ->
    superagentUtil.findPage({url: url})
  .then (res) ->
    $ = cheerio.load(res.text,
      normalizeWhitespace: false
      xmlMode: false,
      decodeEntities: false
    )
    
    _.each $('div.wx-rb.bg-blue.wx-rb_v1._item'), (el) ->
      
      if $(el).find('.txt-box p.s-p3').length is 3
        authenticate_num = Number $(el).find('.txt-box p.s-p3').eq(1).find('span.sp-tit').text().split("authnamewrite('")[1].split("')")[0]
      
        authenticate = ''
        if authenticate_num is 1
          authenticate = '腾讯认证'
        else if authenticate_num is 2
          authenticate = '微信认证'
        else if authenticate_num is 4
          authenticate = '新浪认证'
         
        wechat = 
          wechat_name: $(el).find('.txt-box h3').text().trim()
          wechat_id: $(el).find('.txt-box h4 span').text().split('微信号：')[1].trim()     
          features: $(el).find('.txt-box p.s-p3').eq(0).find('.sp-txt').text().trim() # 功能介绍   
          authenticate: authenticate  # 认证
          authfull: $(el).find('.txt-box p.s-p3').eq(1).find('.sp-txt').text().trim()
          logo_url: $(el).find('.img-box img').attr('src')
          two_dimensional_code: $(el).find('div.pos-box img').eq(1).attr('src')
          openid: $(el).attr('href').split('openid=')[1]
          __biz: $(el).find('.txt-box p.s-p3').eq(2).find('.sp-txt a').attr('href').split('__biz=')[1].split('&')[0]
        
        WechatDB.create(wechat)
        
  .catch (error) ->
    log ' [search-wechat.coffee] [Function] [findWechats] ' + error



