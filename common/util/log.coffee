moment = require 'moment'

module.exports = (message) ->
  console.log "#{moment().format('YYYY-MM-DD HH:mm:ss')} - #{message}"