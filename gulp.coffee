#
# gulp任務配置
#

gulp = require 'gulp'
coffeelint = require 'gulp-coffeelint'
cache = require 'gulp-cached'
plumber = require 'gulp-plumber'
shell = require 'gulp-shell'
{argv} = require 'yargs'

env = if argv.P then 'production' else 'development'

paths =
  coffee: [
    '**/*.coffee'
    '!**/node_modules/**/*.coffee'
  ]

# coffee script語法檢查
gulp.task 'lint', ->
  gulp.src paths.coffee
  .pipe plumber()
  .pipe cache 'lint'
  .pipe coffeelint()
  .pipe coffeelint.reporter()

# 起動服務，文件有改動就會自動重啟
gulp.task 'worker', ->
  do shell.task "NODE_ENV=#{env} node-dev index.js"
  false

# 監測文件，每次改動都會進行語法檢查
gulp.task 'watch', ['worker'], ->
  gulp.watch paths.coffee, ['lint']

# 默認任務
gulp.task 'default', ['watch']