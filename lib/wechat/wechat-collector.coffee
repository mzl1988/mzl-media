#
# 採集文章
#
moment = require 'moment'
_ = require 'underscore'
Promise = require 'bluebird'
cheerio = require 'cheerio'
_url = require 'url'
request = require 'superagent'
Segment = require 'segment'

config = require 'config'
log = require __base + '/common/util/log'
superagentUtil = require __base + '/common/util/superagent-util'
WechatDB = require __base + '/common/helpers/wechat'
KeyDB = require __base + '/common/helpers/key'
ArticleDB = require __base + '/common/helpers/article'

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
    url = "http://mp.weixin.qq.com/mp/getmasssendmsg?__biz=#{gzh.__biz}&key=#{key.key}&uin=#{key.uin}&f=json&count=#{gzh.latest_collection_times}"
    superagentUtil.findPage({url: url})
  .then (res) ->
    body = JSON.parse res.text
    general_msg_list = JSON.parse body.general_msg_list
    lists = general_msg_list.list
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
  url = escapeHtml(article.content_url)
  title = escapeHtml(article.title.trim())
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
    segment = new Segment()
    segment
      # 分词模块
      # 强制分割类单词识别
      .use('URLTokenizer')            # URL识别
      .use('WildcardTokenizer')       # 通配符，必须在标点符号识别之前
      .use('PunctuationTokenizer')    # 标点符号识别
      .use('ForeignTokenizer')        ## 外文字符、数字识别，必须在标点符号识别之后
      # 中文单词识别
      .use('DictTokenizer')           # 词典识别
      .use('ChsNameTokenizer')        # 人名识别，建议在词典识别之后

      # 优化模块
      .use('EmailOptimizer')          # 邮箱地址识别
      .use('ChsNameOptimizer')        # 人名识别优化
      .use('DictOptimizer')           # 词典识别优化
      .use('DatetimeOptimizer')       # 日期时间识别优化

      # 字典文件
      .loadDict('dict.txt')           # 盘古词典
      .loadDict('dict2.txt')          # 扩展词典（用于调整原盘古词典）
      .loadDict('names.txt')          # 常见名词、人名
      .loadDict('wildcard.txt', 'WILDCARD', true)   # 通配符
    content_text =  $('div#page-content').text().replace(new RegExp(' ', 'g'), '')
    word_cloud = segment.doSegment content_text.replace(/[\ |\~|\`|\!|\@|\#|\$|\%|\^|\&|\*|\(|\)|\-|\_|\+|\=|\||\\|\[|\]|\{|\}|\;|\:|\"|\'|\,|\<|\.|\>|\/|\?|\。|\，|\、|\；|\：|\？|\！|\…|\―|\ˉ|\ˇ|\〃|\‘|\'|\“|\”|\々|\～|\‖|\∶|\＂|\＇|\｀|\｜|\〔|\〕|\〈|\〉|\《|\》|\「|\」|\『|\』|\．|\〖|\〗|\【|\】|\（|\）|\［|\］|\｛|\｝|\↑|\↓|\→|\←|\↘|\↙|\♀|\♂|\*|\^|\_|\＋|\－|\×|\÷|\±|\／|\＝|\∫|\∮|\∝|\∞|\∧|\∨|\⊙|\●|\○|\①|\|\◎|\Θ|\⊙|\¤|\㊣|\★|\☆]/g,"")
   
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
      cover: article.cover
      datetime: article.datetime
      read_num: 0
      like_num: 0
      word_cloud: word_cloud
    # 入库
    ArticleDB.create options
  
  .catch (error) ->
    log ' [wechat-collector.coffee] [Function] [findContent] ' + error

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



