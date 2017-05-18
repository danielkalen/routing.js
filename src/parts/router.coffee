Route = import './route'
helpers = import './helpers'
FALLBACK_ROUTE = '*FALLBACK*'

module.exports = class Router
	constructor: (@timeout, @ID)->
		@timeout = 2500 if isNaN(@timeout)
		@listening = false
		@routes = []
		@_specialRoutes = {}
		@_routesMap = {}
		@_cache = {}
		@_history = []
		@_future = []
		@_globalBefore = @_globalAfter = helpers.noop
		@current = {route:null, path:null}
		@prev = {route:null, path:null}
		@_pendingRoute = Promise.resolve()


	_applyBase: (path)->
		path = path.slice(1) if path[0] is '/'
		if @_specialRoutes.basePath
			if path.indexOf(@_specialRoutes.basePath) isnt 0
				return "#{@_specialRoutes.basePath}/#{path}"

		return path


	_matchPath: (path, firstTime)->
		return @_specialRoutes.fallback if path is FALLBACK_ROUTE
		path = helpers.cleanPath(path)
		segments = helpers.parsePath(path, @_specialRoutes.basePath)
		segmentsStrigified = segments.join('/')
		matchingRoute = @_routesMap[segmentsStrigified] or @_cache[segmentsStrigified]

		return if @_specialRoutes.basePath and
				  path.indexOf(@_specialRoutes.basePath) isnt 0

		if not matchingRoute
			for route in @routes
				matchingSoFar = true
				
				for segment,index in segments
					if segment isnt route.segments[index]
						dynamicSegment = route.segments.dynamic[index]
						
						if matchingSoFar=dynamicSegment?
							if route._dynamicFilters[dynamicSegment]
								matchingSoFar = route._dynamicFilters[dynamicSegment](segment)

					break if not matchingSoFar

				if matchingSoFar
					matchingRoute = route
					break

		if matchingRoute
			@_cache[segmentsStrigified] = matchingRoute
			matchingRoute.path = path
		
		else if firstTime and @_specialRoutes.rootPath
			matchingRoute = @_matchPath(@_specialRoutes.rootPath)
		
		return matchingRoute or @_specialRoutes.fallback



	_addRoute: (route)->
		@routes.push(route)
		@routes.sort (a,b)->
			segmentsDiff = b.segments.length - a.segments.length
			if not segmentsDiff
				segmentsDiff = b.segments.dynamic.length - a.segments.dynamic.length

			return segmentsDiff

		return route



	listen: ()->
		@listening = true
		Routing._onChange @_listenCallback = (firstTime)=>
			@go(window.location.hash, false, firstTime, null, true)

		return @


	refresh: ()->
		@prev.path = @current.path
		@prev.route = @current.route
		@go(@current.path, true)


	go: (path, forceRefresh, firstTime, navDirection, fromHashChange)-> if typeof path isnt 'string' then @_pendingRoute else
		path = @_applyBase(path) unless fromHashChange
		matchingRoute = @_matchPath(path, firstTime)
		path = matchingRoute?.path or path

		if matchingRoute and (path isnt @current.path or forceRefresh) then do ()=>
			unless forceRefresh or path is @current.path or path is FALLBACK_ROUTE
				window.location.hash = path
				@_history.push(@current.path) if @current.path and navDirection isnt 'back'
				@_future.length = 0 if not navDirection
			
				@prev.route = @current.route
				@prev.path = @current.path
				@current.route = matchingRoute
				@current.path = path
			

			@_pendingRoute = @_pendingRoute.then ()=> new Promise (resolve, reject)=>
				@_pendingPath = path
				
				setTimeout ()=>
					reject(new Error "TimeoutError: '#{path}' failed to load within #{@timeout}ms (Router ##{@ID})")
				, @timeout

				Promise.resolve()
					.then @_globalBefore
					.then ()=> @prev.route?._leave(@current.route, @current.path)
					.then ()=> matchingRoute._run(path, @prev.route, @prev.path)
					.then @_globalAfter
					.then resolve
					.catch reject


			@_pendingRoute.catch (err)=>
				helpers.logError(err)
				@_pendingRoute = Promise.resolve()
				@go(if @_specialRoutes.fallback then FALLBACK_ROUTE else @prev.path)
		
		return @_pendingRoute


	map: (path)->
		path = helpers.cleanPath(path)
		segments = helpers.parsePath(path)
		segmentsStrigified = segments.join('/')
		matchingRoute = @_routesMap[segmentsStrigified]

		if not matchingRoute
			matchingRoute = @_routesMap[segmentsStrigified] = new Route(path, segments, @)

		return @_addRoute(matchingRoute)


	beforeAll: (fn)->
		@_globalBefore = fn
		return @

	afterAll: (fn)->
		@_globalAfter = fn
		return @

	base: (path)->
		@_specialRoutes.basePath = helpers.cleanPath(path)
		return @

	root: (path)->
		@_specialRoutes.rootPath = helpers.cleanPath(path)
		return @

	fallback: (fn)->
		@_specialRoutes.fallback = new Route(FALLBACK_ROUTE, [], @)
		@_specialRoutes.fallback.to(fn)
		return @

	back: ()->
		@_future.unshift(@current.path) if @current.path
		@go @_history.pop(), false, false, 'back'

	forward: ()->
		@go @_future.shift(), false, false, 'forward'

	kill: ()->
		@_routesMap = {}
		@_specialRoutes = {}
		@_cache = {}
		@routes.length = @_history.length = @_future.length = 0
		@_globalBefore = @_globalAfter = helpers.noop
		@current.route = @current.path = @prev.route = @prev.path = null
		return













