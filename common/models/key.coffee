#
# key
#

mongoose = require 'mongoose'

db = require '../connections/mongo'

ObjectId = mongoose.Schema.Types.ObjectId

schema = new mongoose.Schema
  uin: String
  pass_ticket: String
  key: String
  # 入库时间
  created_at:
    type: Date
    default: Date.now
  updated_at:
    type: Date
    default: Date.now

module.exports = db.model 'keys', schema