Route = import './route'
helpers = import './helpers'

module.exports = class Router
	constructor: (@timeout, @ID)->
		@timeout = 2500 if isNaN(@timeout)
		@listening = false
		@routes = []
		@_priority = 1
		@_routesMap = {}
		@_cache = {}
		@_history = []
		@_future = []
		@_globalBefore = @_globalAfter = helpers.noop
		@_pendingRoute = Promise.resolve()
		@current = @prev = {route:null, path:null}



	_addRoute: (route)->
		@routes.push(route)
		@routes.sort (a,b)->
			segmentsDiff = b.segments.length - a.segments.length
			if not segmentsDiff
				aLength = a.segments.dynamic?.length or 0
				bLength = b.segments.dynamic?.length or 0
				segmentsDiff = bLength - aLength

			return segmentsDiff

		return route


	_removeRoute: (route)->
		cacheKeys = Object.keys(@_cache)
		mapKeys = Object.keys(@_routesMap)
		matchingCacheKey = cacheKeys.filter((key)=> @_cache[key] is route)[0]
		matchingMapKey = cacheKeys.filter((key)=> @_routesMap[key] is route)[0]

		helpers.removeItem(@routes, route)
		delete @_cache[matchingCacheKey]
		delete @_routesMap[matchingMapKey]



	_matchPath: (path)->
		matchingRoute = @_routesMap[path] or @_cache[path]

		if not matchingRoute			
			for route in @routes
				if route.path.test(path)
					matchingRoute = route
					
					if not route.segments.dynamic or not route._dynamicFilters
						break
					else
						matchingSoFar = true
						segments = path.split('/') if not segments
						
						for segment,index in segments
							if segment isnt route.segments[index]
								dynamicSegment = route.segments.dynamic[index]
								
								if matchingSoFar=dynamicSegment?
									if route._dynamicFilters[dynamicSegment]
										matchingSoFar = route._dynamicFilters[dynamicSegment](segment)

							break if not matchingSoFar

						if not matchingSoFar
							matchingRoute = false
							continue
						break

		
		return @_cache[path] = matchingRoute if matchingRoute



	_go: (route, path, storeChange, navDirection)->
		path = helpers.applyBase(path, @_basePath)
		if storeChange
			window.location.hash = path
			
			if navDirection is 'redirect'
				@current = @prev
				@_history.pop()
			
			@_history.push(@current) if @current.route and navDirection isnt 'back'
			@_future.length = 0 if not navDirection
			
			@prev = helpers.copyObject(@current)
			@current = {route, path}
		

		@_pendingRoute = @_pendingRoute.then ()=> new Promise (resolve, reject)=>			
			setTimeout ()=>
				reject(new Error "TimeoutError: '#{path}' failed to load within #{@timeout}ms (Router ##{@ID})")
			, @timeout

			Promise.resolve()
				.then @_globalBefore
				.then ()=> @prev.route?._leave(@current.route, @current.path)
				.then ()=> route._run(path, @prev.route, @prev.path)
				.then @_globalAfter
				.then resolve
				.catch reject


		@_pendingRoute.catch (err)=>
			helpers.logError(err)
			@_pendingRoute = Promise.resolve()
			
			if @_fallbackRoute
				@_go(@_fallbackRoute, @current.path)
			else
				@_go(@prev.route, @prev.path, true, 'back')




	go: (pathGiven, isRedirect)->
		if typeof pathGiven is 'string'
			path = helpers.cleanPath(pathGiven)
			path = helpers.removeBase(path, @_basePath)
			matchingRoute = @_matchPath(path)
			matchingRoute = @_fallbackRoute if not matchingRoute

			if matchingRoute and path isnt @current.path
				@_go(matchingRoute, path, true, isRedirect)
		
		return @_pendingRoute


	map: (path)->
		path = helpers.cleanPath(path)
		segments = helpers.parsePath(path)
		matchingRoute = @_routesMap[path]

		if not matchingRoute
			pathRegex = helpers.segmentsToRegex(segments)
			matchingRoute = @_routesMap[path] = new Route(pathRegex, segments, @)
			@_addRoute(matchingRoute)

		return matchingRoute


	listen: (initOnStart=true)->
		@listening = true
		Routing._registerRouter(@, initOnStart)
		# (import '../')._registerRouter(@, initOnStart)

		return @


	beforeAll: (fn)->
		@_globalBefore = fn
		return @

	afterAll: (fn)->
		@_globalAfter = fn
		return @

	base: (path)->
		@_basePath = helpers.pathToRegex(helpers.cleanPath(path), true)
		return @

	priority: (priority)->
		@_priority = priority if priority and typeof priority is 'number'
		return @

	fallback: (fn)->
		@_fallbackRoute = new Route('*FALLBACK*', [], @)
		@_fallbackRoute.to(fn)
		return @

	back: ()->
		@_future.unshift(@current) if @current.route

		prev = @_history.pop()
		if prev
			@_go(prev.route, prev.path, true, 'back')
		else
			Promise.resolve()

	forward: ()->
		next = @_future.shift()
		if next
			@_go(next.route, next.path, true, 'forward')
		else
			Promise.resolve()

	refresh: ()->
		if @current.route
			@prev.path = @current.path
			@prev.route = @current.route
			@_go(@current.route, @current.path)
		return @_pendingRoute

	kill: ()->
		@_routesMap = {}
		@_cache = {}
		@routes.length = @_history.length = @_future.length = 0
		@_globalBefore = @_globalAfter = helpers.noop
		@_fallbackRoute = null
		@current.route = @current.path = @prev.route = @prev.path = null
		return
















