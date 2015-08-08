#
# 配置
#

module.exports =

  mongo:
    mongos: false
    poolSize: 5
    uri: null
    host: ''
    port: 27017
    database: ''
    user: ""
    password: ""

  # HTTP請求過時秒數
  timeout: 30

  # 代理地址，支持 `http/https/socket`
  proxy: null#'http://172.17.0.26:3128'