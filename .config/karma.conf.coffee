module.exports = (config)-> config.set
	basePath: '../'
	client: captureConsole: true
	browserConsoleLogOptions: level:'log', terminal:true
	frameworks: ['mocha', 'chai']
	files: [
		'dist/routing.debug.js'
		'node_modules/bluebird/js/browser/bluebird.js'
		'node_modules/jquery/dist/jquery.min.js'
		'test/test.js'
	]
	exclude: [
		'**/*.git'
	]

	preprocessors: 'dist/routing.debug.js': 'coverage' if process.env.converage
	reporters: ['coverage'] if process.env.coverage

	coverageReporter:
		type: 'lcov'
		dir: './coverage/'
		subdir: '.'
	
	electronOpts:
		show: false
	
	port: 9876
	colors: true
	logLevel: config.LOG_INFO
	autoWatch: true
	autoWatchBatchDelay: 1000
	restartOnFileChange: true
	singleRun: true
	concurrency: Infinity
	browsers: ['Chrome', 'Firefox', 'Opera', 'Safari']