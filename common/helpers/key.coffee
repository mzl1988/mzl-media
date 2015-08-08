moment = require 'moment'
config = require 'config'
_ = require 'underscore'
Promise = require 'bluebird'

log = require __base + '/common/util/log'
KeyDB = require __base + '/common/models/key'

exports.findNewKey =  ->
  KeyDB.findOne()
  .lean()
  .sort '-created_at'
  .execAsync()