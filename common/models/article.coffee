#
# 公眾號文章
#

mongoose = require 'mongoose'

db = require '../connections/mongo'

ObjectId = mongoose.Schema.Types.ObjectId

schema = new mongoose.Schema
  wechat_name: String
  # 微信号
  wechat_id: String

  # 文章标题
  title: String

  #是否原创
  is_original:
    type: Boolean
    default: false

  # 文章路径
  content_url: String

  # 文摘
  digest: String

  # 文章内容
  content: String

  content_text: String

  # 文章封面图片路径
  cover: String

  # 发布日期
  datetime:
    type: Date
    index: true

  # 入库时间
  created_at:
    type: Date
    default: Date.now

  sequence_number: Number

  # 阅读数
  read_num: Number

  # 点赞数
  like_num: Number
  
  # 词频统计
  wordfreqs:
    type: Array
    default: []

  updated_at:
    type: Date
    default: Date.now

module.exports = db.model 'weixin_gzh_articles', schema
