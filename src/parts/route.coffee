Context = import './context'
helpers = import './helpers'

module.exports = class Route
	constructor: (@path, @segments, @router)->
		@_context = new Context(@)
		@_enterAction = @_leaveAction = helpers.noop
		@_actions = []


	entering: (fn)->
		@_enterAction = fn
		return @

	leaving: (fn)->
		@_leaveAction = fn
		return @

	to: (fn)->
		@_actions.push fn
		return @

	filters: (filters)->
		@_dynamicFilters = filters
		return @

	passive: ()->
		@_passive = @router._hasPassives = true
		return @

	remove: ()->
		@router._removeRoute(@)

	_invokeAction: (action, relatedPath, relatedRoute)->
		result = action.call(@_context, relatedPath, relatedRoute)
		if result is @router._pendingRoute
			return null
		else
			return result

	_run: (path, prevRoute, prevPath)->
		@_isActive = true
		@_resolveParams(path)
		Promise.resolve(@_invokeAction(@_enterAction, prevPath, prevRoute))
			.then ()=> Promise.all @_actions.map (action)=> @_invokeAction(action, prevPath, prevRoute)

	_leave: (newRoute, newPath)-> if @_isActive
		@_isActive = false
		@_invokeAction(@_leaveAction, newPath, newRoute)

	_resolveParams: (path)-> if @segments.dynamic
		path = helpers.removeBase(path, @router._basePath)
		segments = path.split('/')
		
		for dynamicIndex,segmentName of @segments.dynamic when dynamicIndex isnt 'length'
			@_context.params[segmentName] = segments[dynamicIndex] or ''

		return

	matchesPath: (target)->
		isMatching = false
		
		if isMatching=@path.test(target)
			if @segments.dynamic and @_dynamicFilters
				segments = target.split('/') if not segments
				
				for segment,index in segments
					if segment isnt @segments[index]
						dynamicSegment = @segments.dynamic[index]
						
						if isMatching=dynamicSegment?
							if @_dynamicFilters[dynamicSegment]
								isMatching = @_dynamicFilters[dynamicSegment](segment)

					break if not isMatching
		
		return isMatching


	Object.defineProperties @::,
		'map': get: -> @router.map.bind(@router)
		'mapOnce': get: -> @router.mapOnce.bind(@router)
		'listen': get: -> @router.listen.bind(@router)































