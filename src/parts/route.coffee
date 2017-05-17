helpers = import './helpers'

module.exports = class Route
	constructor: (@path, @segments)->
		@originalPath = @path
		@action = @enterAction = @leaveAction = helpers.noop
		@context = {@path, @segments, params:{}}
		@_dynamicFilters = {}


	entering: (fn)->
		@enterAction = fn
		return @

	leaving: (fn)->
		@leaveAction = fn
		return @

	to: (fn)->
		@action = fn
		return @

	filters: (filters)->
		@_dynamicFilters = filters
		return @


	_run: (path, prevRoute, prevPath)->
		@_resolveParams(path)
		Promise.resolve(@enterAction.call(@context, prevPath, prevRoute))
			.then ()=> @action.call(@context, prevPath, prevRoute)

	_leave: (newRoute, newPath)->
		@leaveAction.call(@context, newPath, newRoute)

	_resolveParams: (path)-> if @segments.hasDynamic
		segments = path.split('/')
		
		for dynamicIndex,dynamicSegment of @segments.dynamic
			@context.params[dynamicSegment] = segments[dynamicIndex] or ''

		return































