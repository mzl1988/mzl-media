moment = require 'moment'
config = require 'config'
_ = require 'underscore'
Promise = require 'bluebird'

log = require __base + '/common/util/log'
ArticleDB = require __base + '/common/models/article'

exports.create = (article) ->
  ArticleDB.find()
  .lean()
  .where('wechat_id').equals article.wechat_id
  .where('title').equals article.title
  .execAsync()
  .then (results) ->
    if results.length is 0
      ArticleDB.createAsync article
      log "[insert] [#{article.wechat_name}] [#{article.wechat_id}] [title: #{article.title}]"
    else
      conditions = {"wechat_id": article.wechat_id, "title": article.title}
      ArticleDB.updateAsync conditions, article, {}
      log "[update] [#{article.wechat_name}] [#{article.wechat_id}] [title: #{article.title}]"
    
  