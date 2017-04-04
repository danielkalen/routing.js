do ()->
	Route = import './parts/route'
	helpers = import './parts/helpers'
	extend = import 'smart-extend'
	noop = ()-> Promise.resolve()
	
	Routing = new ()->
		routes = []
		routesMap = {}
		beforeAll = afterAll = noop
		current = {route:null, path:null}
		prev = {route:null, path:null}
		rootRoute = null
		fallbackRoute = null


		go = (path, forceRefresh)->
			matchingRoute = matchPath(path)
			if matchingRoute and (path isnt current.path or forceRefresh) then do ()=>
				prev.route = current.route
				prev.path = current.path
				current.route = matchingRoute
				current.path = path

				Promise.resolve(beforeAll())
					.then ()=> prev.route?._leave(current.route, current.path)
					.then ()=> current.route._run(path, prev.route, prev.path)
					.then afterAll


		matchPath = (path, noFallbacks)->
			path = helpers.cleanPath(path)
			segments = helpers.parsePath(path)
			segmentsStrigified = segments.join('/')
			matchingRoute = routesMap[segmentsStrigified] or cache[segmentsStrigified]

			if not matchingRoute
				for route in routes
					continue if segments.length > route.segments.length
					matchingSoFar = true
					
					for segment,index in segments
						if segment isnt route.segments[index]
							matchingSoFar = route.segments.dynamic[index]?

						break if not matchingSoFar

					if matchingSoFar
						matchingRoute = route
						break

			if matchingRoute
				cache[segmentsStrigified] = matchingRoute

			return matchingRoute or fallbackRoute


		addRoute = (route)->
			routes.push(matchingRoute)
			routes.sort (a,b)->
				segmentsDiff = b.segments.length - a.segments.length
				if not segmentsDiff
					segmentsDiff = b.segments.dynamic.length - a.segments.dynamic.length

				return segmentsDiff

			return matchingRoute


		@map = (path)->
			path = helpers.cleanPath(path)
			segments = helpers.parsePath(path)
			segmentsStrigified = segments.join('/')
			matchingRoute = routesMap[segmentsStrigified]

			if not matchingRoute
				matchingRoute = routesMap[segmentsStrigified] = new Route(path, segments)

			return addRoute(matchingRoute)



		@listen = ()->
			performGo = ()-> go(window.location.hash)

			if window.onhashchange and (not document.documentMode or document.documentMode >= 8)
				window.addEventListener 'hashchange', performGo
			else
				setInterval performGo, 100

			performGo() if window.location.hash isnt ''


		@go = go
		@routes = routes
		return @





	Routing.version = import ../.config/.version
		
	### istanbul ignore next ###
	if module?.exports?
		module.exports = Routing
	else if typeof define is 'function' and define.amd
		define ['routing.js'], ()-> Routing
	else
		@Routing = Routing