//
// 運行服務
//

var time = process.hrtime();

require('./init');

var moment = require('moment');
var numeral = require('numeral');

require('./lib/worker');

// southernExpressNews = require('./lib/southern-express/news');
// southernExpressNews();

searchWechat = require('./lib/wechat/search-wechat');
searchWechat();

searchSogou = require('./lib/wechat/search-sogou');
searchSogou();

wechatCollector = require('./lib/wechat/wechat-collector');
wechatCollector();


var diff = process.hrtime(time);
var second = (diff[0] * 1e9 + diff[1]) / 1e9;
console.log("%s worker is running in %s mode used %s seconds",
  moment().format('YYYY-MM-DD HH:mm:ss'), process.env.NODE_ENV, numeral(second).format('0.00'));




