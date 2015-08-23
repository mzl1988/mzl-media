#
# 採集文章
#
moment = require 'moment'
_ = require 'underscore'
Promise = require 'bluebird'
cheerio = require 'cheerio'
_url = require 'url'
request = require 'superagent'

config = require 'config'
log = require __base + '/common/util/log'
superagentUtil = require __base + '/common/util/superagent-util'
WechatDB = require __base + '/common/helpers/wechat'
KeyDB = require __base + '/common/helpers/key'
ArticleDB = require __base + '/common/helpers/article'
{fork} = require 'child_process'

module.exports = ->
  if config.collector.weixin.start
    interval()

interval = ->
  Promise.resolve()
  .then ->
    findCollectorGzh()
  .catch (error) ->
    log ' [wechat-collector.coffee] [Function] [interval] ' + error
  .delay 1000 * 60 * 10
  .then interval

findCollectorGzh = ->
  Promise.resolve()
  .then ->
    WechatDB.findCollectorGzh(config.collector.weixin.offset, config.collector.weixin.limit)
  .then (gzhs) ->
    log "找到要採集的公眾號 [#{gzhs.length}] 個"
    fetchCollectorGzh(gzhs)
  .catch (error) ->
    log ' [wechat-collector.coffee] [Function] [findCollectorGzh] ' + error

fetchCollectorGzh = (gzhs) ->
  Promise.resolve()
  .then ->
    _.reduce gzhs, (promise, gzh, i) ->
      promise.then ->
        log "#{i}: [#{gzh.wechat_name}] [#{gzh.wechat_id}]"
        collectorArticles(gzh)
      .delay(1000 * 5)
    , Promise.resolve()
  .catch (error) ->
    log ' [wechat-collector.coffee] [Function] [fetchCollectorGzh] ' + error


collectorArticles = (gzh) ->
  Promise.resolve()
  .then ->
    KeyDB.findNewKey()
  .then (key) ->
    # url = "http://mp.weixin.qq.com/mp/getmasssendmsg?__biz=#{gzh.__biz}&key=#{key.key}&uin=#{key.uin}&f=json&count=10"
    msgUrl = "http://mp.weixin.qq.com/mp/getmasssendmsg?__biz=#{gzh.__biz}&uin=#{key.uin}&key=#{key.key}&devicetype=Windows+10&version=61020020&lang=zh_CN&pass_ticket=#{key.pass_ticket}#wechat_webview_type=1"
    # console.log msgUrl
    superagentUtil.findPage({url: msgUrl})
  .then (res) ->
    # body = JSON.parse res.text
    # general_msg_list = JSON.parse body.general_msg_list
    # lists = general_msg_list.list
    # console.log res.text
    body = res.text
    msgList = body.match(/msgList\s*=\s*'(.*)';/)[1]
    lists = JSON.parse(escapeHtml(msgList)).list
    articles = []
    _.each lists, (list) ->
      if list.app_msg_ext_info
        datetime = moment(list.comm_msg_info.datetime  * 1000).format('YYYY-MM-DD HH:mm:ss')
        info = list.app_msg_ext_info
        if info.multi_app_msg_item_list.length is 0
          info.datetime = datetime
          info.sequence_number = 1
          articles.push info
        else
          item_one = _.omit(info, 'multi_app_msg_item_list')
          item_one.sequence_number = 1
          item_one.datetime = datetime
          articles.push item_one
          _.each info.multi_app_msg_item_list, (item, i) ->
            item.sequence_number = (i + 1 + 1)
            item.datetime = datetime
            articles.push item
    fetchArticles(articles, gzh)
  .catch (error) ->
    log ' [wechat-collector.coffee] [Function] [collectorArticles] ' + error

fetchArticles = (articles, gzh) ->
  Promise.resolve()
  .then ->
   _.reduce articles, (promise, article, i) ->
      promise.then ->
        findContent(article, gzh)
      # .then (articleObj) ->
      #   findReadNum(articleObj)
      .delay(1000 * config.collector.weixin.delay)
    , Promise.resolve()
  .catch (error) ->
    log ' [wechat-collector.coffee] [Function] [fetchArticles] ' + error

findContent = (article, gzh) ->
  url = escapeHtml(article.content_url).replace(/\\/g, '')
  title = escapeHtml(article.title.trim())
  img_cover = escapeHtml(article.cover.trim()).replace(/\\/g, '')
  Promise.resolve()
  .then ->
    superagentUtil.findPage({url: url})
  .then (res) ->
    $ = cheerio.load(res.text,
      normalizeWhitespace: false
      xmlMode: false,
      decodeEntities: false
    )

    is_original = false
    original = $('span.rich_media_meta.meta_original_tag').text()
    if original
      if original.indexOf("原创") > -1
        is_original = true

    $('div#page-content').find('script,div#js_toobar,div#js_iframetest,link').remove()
    
    content_text =  $('div#page-content').text().replace(new RegExp(' ', 'g'), '')
  
    options =
      wechat_name: gzh.wechat_name
      wechat_id: gzh.wechat_id
      title: title
      is_original: is_original
      content_url: url
      sequence_number: article.sequence_number
      digest: article.digest.trim()
      content: $('div#page-content').html()
      content_text: content_text
      cover: img_cover
      datetime: article.datetime
      read_num: 0
      like_num: 0
    # 入库和词频统计
    #ArticleDB.create options
    doWordfreq(options)
  .catch (error) ->
    log ' [wechat-collector.coffee] [Function] [findContent] ' + error

# 入库和词频统计
doWordfreq = (options) ->
  freq = {}
  Promise.resolve()
  .then ->
    new Promise (resolve) ->
      worker = fork __base + '/common/util/wordfreq-worker.coffee'
      worker.send
        content: options.content_text
        minimumCount: 3
      worker.on 'message', (message) ->
        #console.log message
        {words} = message
        # console.log words
        #words = [ [ '公司', 7 ], [ '公司', 10 ], [ '消防', 7 ], [ '銀行', 7 ], [ '濱州', 6 ], [ '股份', 6 ] ]
        _.reduce words, (memo, data) ->
          memo[data[0]] or= 0
          memo[data[0]] += data[1]
          memo
        , freq
        worker.kill()
        resolve()
  .then ->
    #console.log freq
    limit = 100
    wordfreqs = _.chain freq
      .map (value, key) ->
        name: key
        value: value
      .sortBy (d) ->
        -d.value
      .first limit
      .value()
  .then (wordfreqs) ->
    options.wordfreqs = wordfreqs
    ArticleDB.create options

findReadNum = (articleObj) ->
  Promise.resolve()
  .then ->
    KeyDB.findNewKey()
  .then (key) ->
    args = _url.parse(articleObj.content_url, true).query
    str = "__biz=#{args.__biz}&mid=#{args.mid}=&idx=#{args.idx}&sn=#{args.sn}&scene=#{args.scene}"
    ascene = '1'
    uin = key.uin
    pass_ticket = key.pass_ticket
    user_key = key.key
    href = "http://mp.weixin.qq.com/mp/getappmsgext?#{str}&key=#{user_key}&ascene=#{ascene}&uin=#{uin}&pass_ticket=#{pass_ticket}&ie=utf-8"
    request
    .get href
    .set
      'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 7_0 like Mac OS X; en-us) AppleWebKit/537.51.1 (KHTML, like Gecko) Version/7.0 Mobile/11A465 Safari/9537.53/10B329 MicroMessenger/5.0.1'
    .timeout 1000 * config.timeout
    .proxy config.proxy
    .endAsync()
    .then (body) ->
      console.log body.text
      if body.text
        if body.text.indexOf("read_num") > -1
          data = JSON.parse body.text
          appmsgstat = data.appmsgstat

          articleObj.read_num = appmsgstat.read_num
          articleObj.like_num = appmsgstat.like_num

          console.log articleObj.title + "    "  + articleObj.datetime + "   "+ articleObj.is_original
  .catch (error) ->
    log ' [wechat-collector.coffee] [Function] [findReadNum] ' + error
  
escapeHtml = (str) ->
  arrEntities =
    'lt': '<'
    'gt': '>'
    'nbsp': ' '
    'amp': '&'
    'quot': '"'
  str.replace /&(lt|gt|nbsp|amp|quot);/ig, (all, t) ->
    arrEntities[t]



