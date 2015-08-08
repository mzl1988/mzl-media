moment = require 'moment'
config = require 'config'
_ = require 'underscore'
Promise = require 'bluebird'

log = require __base + '/common/util/log'
NewDB = require __base + '/common/models/new'


exports.create = (newObj) ->
  NewDB.find()
    .lean()
    .where('new_name').equals newObj.new_name
    .where('new_area').equals newObj.new_area
    .where('new_type').equals newObj.new_type
    .where('article_title').equals newObj.article_title
    .where('article_datestr').equals newObj.article_datestr
    .execAsync()
    .then (results) ->
      if results.length is 0
        NewDB.createAsync newObj
        console.log "[insert] [#{newObj.new_name}] [#{newObj.new_type}] [#{newObj.article_datestr}] [#{newObj.article_title}] "
    