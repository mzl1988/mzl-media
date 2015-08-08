
config = require 'config'
request = require 'superagent'
require('superagent-proxy')(request)

exports.findPage = (option) ->
	request
    .get option.url
    .timeout 1000 * config.timeout
    .proxy config.proxy
    .endAsync()