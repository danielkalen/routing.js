module.exports = class Context
	constructor: (@route)->
		@segments = @route.segments
		@path = @route.path.string
		@params = {}
		@query = {}
	
	remove: ()->
		@route.remove()
	
	redirect: (path)->
		@route.router.go(path, 'redirect')
		return Promise.resolve()