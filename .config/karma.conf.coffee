DIR = if process.env.CI then 'dist' else 'build'
LIB_FILE = if process.env.minified then "#{DIR}/routing.js" else "#{DIR}/routing.debug.js"

module.exports = (config)-> config.set
	basePath: '../'
	client: captureConsole: true unless process.env.sauce
	browserConsoleLogOptions: level:'log', terminal:true
	frameworks: ['mocha']
	files: [
		LIB_FILE
		'test/test.js'
	]
	exclude: [
		'**/*.git'
	]

	preprocessors: {"#{LIB_FILE}":'coverage'} if process.env.coverage
	reporters: do ()->
		reporters = ['progress']
		reporters.push('coverage') if process.env.coverage
		reporters.push('saucelabs') if process.env.sauce
		return reporters

	coverageReporter:
		type: 'lcov'
		dir: './coverage/'
		subdir: '.'
	
	electronOpts:
		show: false

	port: 9876
	colors: true
	logLevel: config.LOG_INFO
	# autoWatch: if process.env.sauce then false else true
	# autoWatchBatchDelay: 1000
	# restartOnFileChange: true
	singleRun: true
	concurrency: if process.env.sauce then 2 else 5
	captureTimeout: 1.8e5 if process.env.sauce
	browserNoActivityTimeout: 1.8e5 if process.env.sauce
	browserDisconnectTimeout: 1e4 if process.env.sauce
	browserDisconnectTolerance: 3 if process.env.sauce
	browsers: if process.env.sauce then Object.keys(require('./sauceTargets')) else ['Chrome', 'Firefox', 'Opera', 'Safari']
	customLaunchers: require('./sauceTargets')
	sauceLabs: 
		testName: 'RoutingJS Test Suite'
		recordVideo: false
		recordScreenshots: false
		build: require('../package.json').version+'-'+Math.round(Math.random()*1e6).toString(16)
		username: 'routingjs'
		accessKey: '21925ef8-2b2c-47fe-834e-0e1cdb69a3b5'