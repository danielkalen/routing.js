helpers = import './helpers'

module.exports = class Route
	constructor: (@path, @segments, @router)->
		@originalPath = @path
		@context = {@path, @segments, params:{}}
		@_dynamicFilters = {}


	entering: (fn)->
		@enterAction = fn
		return @

	leaving: (fn)->
		@leaveAction = fn
		return @

	to: (fn)->
		return @

	filters: (filters)->
		@_dynamicFilters = filters
		return @

	_invokeAction: (action, relatedPath, relatedRoute)->
		result = action.call(@context, relatedPath, relatedRoute)
		if result is @router._pendingRoute
			return null
		else
			return result

	_run: (path, prevRoute, prevPath)->
		@_resolveParams(path)
			.then ()=> @action.call(@context, prevPath, prevRoute)
		Promise.resolve(@_invokeAction(@enterAction, prevPath, prevRoute))

	_leave: (newRoute, newPath)->
		@_invokeAction(@leaveAction, newPath, newRoute)

	_resolveParams: (path)-> if @segments.hasDynamic
		segments = path.split('/')
		
		for dynamicIndex,dynamicSegment of @segments.dynamic
			@context.params[dynamicSegment] = segments[dynamicIndex] or ''

		return































