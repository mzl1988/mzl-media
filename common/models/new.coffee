#
# news
#

mongoose = require 'mongoose'

db = require '../connections/mongo'

ObjectId = mongoose.Schema.Types.ObjectId

schema = new mongoose.Schema
  new_name: String
  new_type: String
  article_title: String
  article_url: String
  article_source: String
  article_datestr: String
  article_date: Date
  article_cover_image: String
  article_abstract: String
  article_content: String
  created_at: 
  	type: Date
  	default: Date.now
module.exports = db.model 'news', schema