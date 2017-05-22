module.exports = class Context
	constructor: (@route)->
		@segments = @route.segments
		@path = @route.path.string
		@params = {}
	
	remove: ()->
		@route.remove()