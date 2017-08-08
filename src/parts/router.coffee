Route = import './route'
helpers = import './helpers'
debug = (import 'debug')('routing:router')

class Router
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
		@_activeRoutes = []
		@current = @prev = {route:null, path:null}



	_addRoute: (route)->
		@routes.push(route)
		@routes.sort (a,b)->
			segmentsDiff = a.segments.length - b.segments.length
			if not segmentsDiff
				aLength = a.segments.dynamic?.length or 0
				bLength = b.segments.dynamic?.length or 0
				segmentsDiff = aLength - bLength

			return segmentsDiff

		debug "added route #{route.path.original}"
		return route


	_removeRoute: (route)->
		cacheKeys = Object.keys(@_cache)
		mapKeys = Object.keys(@_routesMap)
		matchingCacheKey = cacheKeys.filter((key)=> @_cache[key] is route)[0]
		matchingMapKey = cacheKeys.filter((key)=> @_routesMap[key] is route)[0]

		helpers.removeItem(@routes, route)
		delete @_cache[matchingCacheKey]
		delete @_routesMap[matchingMapKey]
		debug "removed route #{route.path.original}"



	_matchPath: (path)->
		path = helpers.removeQuery(path)
		matchingRoute = @_cache[path]

		if not matchingRoute
			for route in @routes
				continue if not route.matchesPath(path)

				if @_hasPassives
					if route._passiveVersion
						passiveRoutes = [] if not passiveRoutes
						passiveRoutes.push route._passiveVersion
						continue if route._actions.length is 0

					matchingRoute = route if not matchingRoute
				else
					matchingRoute = route
					break

		if passiveRoutes
			passiveRoutes.push(matchingRoute) if matchingRoute
			matchingRoute = passiveRoutes
			debug "matched #{path} with [#{passiveRoutes.map((r)->r.path.original).join(', ')}]"
		else
			debug "matched #{path} with #{matchingRoute.path?.original or matchingRoute.path}" if matchingRoute
		
		return @_cache[path] = matchingRoute if matchingRoute



	_go: (route, path, storeChange, navDirection, activeRoutes)->
		if not activeRoutes
			activeRoutes = @_activeRoutes.slice()
			@_activeRoutes.length = 0

		if route.constructor is Array
			return Promise.all route.map (route_)=> @_go(route_, path, storeChange, navDirection, activeRoutes)
		
		path = helpers.applyBase(path, @_basePath)
		
		if storeChange and not route._isPassive
			debug "storing hash change #{route.path.original}"
			window.location.hash = path unless path is helpers.currentPath()
			
			if navDirection is 'redirect'
				@current = @prev
				@_history.pop()
			
			@_history.push(@current) if @current.route and navDirection isnt 'back'
			@_future.length = 0 if not navDirection
			
			@prev = helpers.copyObject(@current)
			@current = {route, path}


		@_pendingRoute = @_pendingRoute.then ()=> new Promise (resolve, reject)=>
			@_activeRoutes.push(route) unless route is @_fallbackRoute or helpers.includes(@_activeRoutes, route)
			setTimeout ()=>
				reject(new Error "TimeoutError: '#{path}' failed to load within #{@timeout}ms (Router ##{@ID})")
			, @timeout

			debug "starting route transition"

			Promise.resolve()
				.then @_globalBefore
				.then ()=> Promise.all(activeRoutes.map (route)=> route._leave(@current.route, @current.path))
				.then ()=> route._run(path, @prev.route, @prev.path)
				.then @_globalAfter
				.then resolve
				.catch reject


		@_pendingRoute.catch (err)=>
			debug "error occured during route transition"
			helpers.logError(err)
			@_pendingRoute = Promise.resolve()
			
			if @_fallbackRoute
				@_go(@_fallbackRoute, @current.path)
			else
				@_go(@prev.route, @prev.path, true, 'back')




	go: (pathGiven, isRedirect)->
		if typeof pathGiven is 'string'
			debug "starting manual route transition to #{pathGiven}"
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


	mapOnce: (path)->
		@map(path).to ()-> @remove()


	listen: (initOnStart=true)->
		@listening = true
		(import '../')._registerRouter(@, initOnStart)
		
		debug "router #{@ID} listening"
		
		return @


	beforeAll: (fn)->
		@_globalBefore = fn
		return @

	afterAll: (fn)->
		@_globalAfter = fn
		return @

	base: (path)->
		@_basePath = helpers.pathToRegex(helpers.cleanPath(path), true, path)
		return @

	priority: (priority)->
		@_priority = priority if priority and typeof priority is 'number'
		return @

	fallback: (fn)->
		@_fallbackRoute = new Route('*FALLBACK*', [], @)
		@_fallbackRoute.to(fn)
		debug "added fallback route"
		return @

	back: ()->
		debug "history - back"
		@_future.unshift(@current) if @current.route

		prev = @_history.pop()
		if prev
			@_go(prev.route, prev.path, true, 'back')
		else
			Promise.resolve()

	forward: ()->
		debug "history - forward"
		next = @_future.shift()
		if next
			@_go(next.route, next.path, true, 'forward')
		else
			Promise.resolve()

	refresh: ()->
		debug "history - refresh"
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
		debug "router #{@ID} killed"
		return
















module.exports = Router