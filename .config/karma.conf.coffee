LIB_FILE = if process.env.minified then 'dist/routing.js' else 'dist/routing.debug.js'

module.exports = (config)-> config.set
	basePath: '../'
	client: captureConsole: true
	browserConsoleLogOptions: level:'log', terminal:true
	frameworks: ['mocha', 'chai']
	files: [
		LIB_FILE
		'node_modules/bluebird/js/browser/bluebird.js'
		'node_modules/jquery/dist/jquery.min.js'
		'test/test.js'
	]
	exclude: [
		'**/*.git'
	]

	preprocessors: {"#{LIB_FILE}":'coverage'} if process.env.coverage
	reporters: ['progress', 'coverage'] if process.env.coverage

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