Context = import './context'
helpers = import './helpers'

module.exports = class Route
	constructor: (@path, @segments, @router)->
		@enterAction = @leaveAction = helpers.noop
		@actions = []
		@context = new Context(@)


	entering: (fn)->
		@enterAction = fn
		return @

	leaving: (fn)->
		@leaveAction = fn
		return @

	to: (fn)->
		@actions.push fn
		return @

	filters: (filters)->
		@_dynamicFilters = filters
		return @

	remove: ()->
		@router._removeRoute(@)

	_invokeAction: (action, relatedPath, relatedRoute)->
		result = action.call(@context, relatedPath, relatedRoute)
		if result is @router._pendingRoute
			return null
		else
			return result

	_run: (path, prevRoute, prevPath)->
		@_resolveParams(path)
		Promise.resolve(@_invokeAction(@enterAction, prevPath, prevRoute))
			.then ()=> Promise.all @actions.map (action)=> @_invokeAction(action, prevPath, prevRoute)

	_leave: (newRoute, newPath)->
		@_invokeAction(@leaveAction, newPath, newRoute)

	_resolveParams: (path)-> if @segments.dynamic
		path = helpers.removeBase(path, @router._basePath)
		segments = path.split('/')
		
		for dynamicIndex,segmentName of @segments.dynamic when dynamicIndex isnt 'length'
			@context.params[segmentName] = segments[dynamicIndex] or ''

		return

	Object.defineProperty @::, 'map', get: -> @router.map.bind(@router)
	Object.defineProperty @::, 'listen', get: -> @router.listen.bind(@router)































