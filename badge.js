'use strict';

var browsers = {
        googlechrome: 'chrome',
        iexplore: 'explorer',
        firefox: 0,
        safari: 0,
        iphone: 0,
        ipad: 0
    },
    REQ = require('request'),
    lodash = require('lodash');

REQ({url: 'https://saucelabs.com/rest/v1/zordius_jpp/jobs?full=:get_full_info', json: true}, function (err, response, body) {
    var badge = {};

    lodash.map(browsers, function (V, K) {
        badge[V || K] = {};
    });
 
    lodash.map(body, function (D) {
        if (D.build !== process.env.TRAVIS_JOB_ID) {
            return;
        }
        badge[browsers[D.browser] || D.browser][D.browser_version] = D.passed;
    });

    require('fs').writeFileSync('badge.png', require('browser-badge')(badge), 'binary');
});
