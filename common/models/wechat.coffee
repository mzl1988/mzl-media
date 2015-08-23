#
# 公眾號
#

mongoose = require 'mongoose'

db = require '../connections/mongo'

ObjectId = mongoose.Schema.Types.ObjectId

schema = new mongoose.Schema

  wechat_name: String

  wechat_id: String

  __biz: String

  openid: String

  # 功能介绍
  features: String

  # 认证
  authenticate: String
  
  authfull: String

  logo_url: String

  two_dimensional_code: String

  created_at:
    type: Date
    default: Date.now

  area: String
  

  types: Array

  is_collector:
    type: Boolean
    default: false

  collector_priority:
    type: Number
    default: 5

module.exports = db.model 'wechats', schema


