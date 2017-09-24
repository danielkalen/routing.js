Context = import './context'
helpers = import './helpers'
debug = (import 'debug')('routing:route')

module.exports = class Route
	constructor: (@path, @segments, @router, @_isPassive)->
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
		if @_isPassive
			return @

		else if not @_passiveVersion
			debug "added passive version '#{@path.original}'"
			@_passiveVersion = new Route(@path, @segments, @router, true)
			@router._hasPassives = true
		
		return @_passiveVersion

	remove: ()->
		@router._removeRoute(@)

	_invokeAction: (action, relatedPath, relatedRoute)->
		debug "entering '#{@path.original}' from '#{relatedPath}'" if action is @_enterAction
		result = action.call(@_context, relatedPath, relatedRoute)
		if result is @router._pendingRoute
			return null
		else
			return result

	_run: (path, prevRoute, prevPath, navDirection)->
		debug "running '#{@path.original}'"
		@_isActive = true
		@_context.params = @_resolveParams(path)
		@_context.query = helpers.parseQuery(path, @router.settings.queryParser)

		Promise.resolve(@_invokeAction(@_enterAction, prevPath, prevRoute, navDirection))
			.then ()=> Promise.all @_actions.map (action)=> @_invokeAction(action, prevPath, prevRoute, navDirection)

	
	_leave: (newRoute, newPath, navDirection)-> if @_isActive
		debug "leaving '#{@path.original}' to '#{newRoute?.path.original}'"
		@_isActive = false
		@_invokeAction(@_leaveAction, newPath, newRoute, navDirection)


	_resolveParams: (path)->
		return helpers.noopObj if not @segments.dynamic
		path = helpers.removeQuery helpers.removeBase(path, @router._basePath)
		segments = path.split('/')
		params = {}
		
		for dynamicIndex,segmentName of @segments.dynamic when dynamicIndex isnt 'length'
			params[segmentName] = segments[dynamicIndex] or ''

		return params


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































