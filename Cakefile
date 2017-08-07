process.title = 'simplywatch Routing.js'
global.Promise = require 'bluebird'
fs = require 'fs-jetpack'
path = require 'path'
extend = require 'smart-extend'
Listr = require 'listr'
SimplyWatch = require 'simplywatch'
runTaskList = (tasks)-> (new Listr(tasks, concurrent:true)).run()

option '-d', '--debug', 'run in debug mode'
option '-m', '--maps', 'create source maps'

task 'build', ()->
	Promise.resolve()
		.then ()-> invoke 'build:js'
		.then ()-> invoke 'build:test'


task 'build:js', (options)->
	Promise.resolve()
		.then ()-> fs.listAsync "src"
		.filter (file)-> file.endsWith '.coffee'
	
		.map (file)->
			fileBase = path.basename(file,'.coffee')
			{src:"src/#{fileBase}.coffee", dest:"dist/#{fileBase}.js", destDebug:"dist/#{fileBase}.debug.js", base:fileBase}

		.map (file)->
			title: "Compiling #{file.base}.js"
			task: ()-> compileJS(file, options, umd:'Routing')
	
		.then runTaskList


task 'build:test', (options)->
	Promise.resolve()
		.then ()-> fs.listAsync "test"
		.filter (file)-> file.endsWith '.coffee'
	
		.map (file)->
			fileBase = path.basename(file,'.coffee')
			{src:"test/#{fileBase}.coffee", dest:"test/#{fileBase}.js", base:fileBase}

		.map (file)->
			title: "Compiling #{file.base}.js"
			task: ()-> compileJS(file, options)
	
		.then runTaskList





task 'watch', ()->
	invoke 'watch:js'
	invoke 'watch:test'



task 'watch:js', (options)->
	SimplyWatch
		globs: "src/*.coffee"
		command: (file, params)->
			Promise.resolve()
				.then ()->
					fileBase = path.basename(file,'.coffee')
					{src:"src/#{fileBase}.coffee", dest:"dist/#{fileBase}.js", destDebug:"dist/#{fileBase}.debug.js", base:fileBase}

				.then (file)-> compileJS(file, options, umd:'Routing')


task 'watch:test', (options)->
	SimplyWatch
		globs: "test/*.coffee"
		command: (file, params)->
			Promise.resolve()
				.then ()->
					fileBase = path.basename(file,'.coffee')
					{src:"test/#{fileBase}.coffee", dest:"test/#{fileBase}.js", base:fileBase}

				.then (file)-> compileJS(file, options)









compileJS = (file, options, smOpts)->
	MinifyJS = require('uglify-js').minify # MinifyJS = Promise.promisify require('closure-compiler-service').compile, multiArgs:true
	
	Promise.resolve()
		.then ()-> require('simplyimport')(extend {file:file.src}, smOpts)
		.then (result)->
			if options.debug then result else
				minified = MinifyJS(result, compress:{unused:false,keep_fnames:true},mangle:{keep_fnames:true})
				throw minified.error if minified.error
				return minified.code
	
		.then (result)->
			dest = if options.debug and file.destDebug then file.destDebug else file.dest
			fs.writeAsync(dest, result)
		
		.catch (err)->
			console.error(err) if err not instanceof Error
			throw err

