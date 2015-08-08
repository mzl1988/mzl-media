//
// 初始化環境
//

require('coffee-script/register');

// 確保加載順序
require('./global');
require('require-dir')();
