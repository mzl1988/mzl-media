#
# Mongodb connection對象
#

mongoose = require 'mongoose'
moment = require 'moment'
config = require 'config'

mongoUri = config.mongo.uri or "mongodb://#{config.mongo.host}:#{config.mongo.port}/#{config.mongo.database}"

connection = module.exports = mongoose.createConnection mongoUri,
  server:
    poolSize: config.mongo.poolSize or 5
    keepAlive: 1
  user: config.mongo.user
  pass: config.mongo.password
  mongos: config.mongo.mongos

connection.on 'error', (err) ->
  console.error ''
  console.error "[ERROR] #{moment().format('YYYY-MM-DD HH:mm:ss')} Handled error"
  console.error err.stack
