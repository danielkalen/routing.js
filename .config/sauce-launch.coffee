request = require 'request'

request
	.post
		url: "https://saucelabs.com/rest/v1/routingjs/js-tests",
		json:
			name: "QuickDom Test Suite"
			build: require('../package.json').version
			framework: "mocha"
			url: "http://routingjs.dev:9201/test/testrunner.html?purgeCache=#{Math.random()*100000000}"
			platforms: [
				["OS X 10.11", "chrome", "53"]
				["OS X 10.11", "chrome", "40"]
				["OS X 10.11", "firefox", "48"]
				["OS X 10.11", "firefox", "38"]
				["OS X 10.11", "safari", "9"]
				["OS X 10.10", "safari", "8"]
				["OS X 10.9", "safari", "7"]
				["OS X 10.8", "safari", "6"]
				["Windows 10", "microsoftedge", "14"]
				["Windows 10", "microsoftedge", "13"]
				["Windows 7", "internet explorer", "11"]
				["Windows 7", "internet explorer", "10"]
				["Windows 7", "internet explorer", "9"]
				["iOS", "iphone", "10"]
				["iOS", "iphone", "9.3"]
				["iOS", "iphone", "9.0"]
				["iOS", "iphone", "8.1"]
				["Linux", "android", "5.1"]
				# ["Linux", "android", "4.3"]
			]
	
	.auth "routingjs", "9321bba9-2293-4e66-8fb5-06e255fbaa51"
