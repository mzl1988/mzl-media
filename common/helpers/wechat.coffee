moment = require 'moment'
config = require 'config'
_ = require 'underscore'
Promise = require 'bluebird'

log = require __base + '/common/util/log'
WechatDB = require __base + '/common/models/wechat'


exports.create = (wechat) ->
  WechatDB.find()
    .lean()
    .where('wechat_id').equals wechat.wechat_id
    .execAsync()
    .then (results) ->
      if results.length is 0
        WechatDB.createAsync wechat
        console.log "[insert] [#{wechat.wechat_name}] [#{wechat.wechat_id}] [#{wechat.authenticate}] [#{wechat.__biz}]"
      else
        WechatDB.updateAsync({wechat_id: wechat.wechat_id},{$set: wechat}, false, true)
        console.log "[update] [#{wechat.wechat_name}] [#{wechat.wechat_id}] [#{wechat.authenticate}] [#{wechat.__biz}]"

exports.findCollectorGzh = (offset, limit) ->
  WechatDB.find()
  .lean()
  .where('is_collector').equals true
  .select 'wechat_name wechat_id __biz latest_collection_times'
  .sort 'collector_priority'
  .limit limit or 10
  .skip offset or 0
  .execAsync()

exports.findGzh = (offset, limit) ->
  WechatDB.find()
  .lean()
  .select 'wechat_name'
  .sort 'created_at'
  .limit limit or 10
  .skip offset or 0
  .execAsync()


