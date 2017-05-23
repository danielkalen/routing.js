do ()->
	Router = import './parts/router'
	helpers = import './parts/helpers'
	
	Routing = new ()->
		routers = []
		listeningRouters = []
		listening = false
		currentID = 0

		handleHashChange = (e)->
			path = helpers.currentPath()
			matchingRoutes = []
			
			for router in listeningRouters
				continue if router._basePath and not router._basePath.test(path)
				targetPath = helpers.removeBase(path, router._basePath)
				matchingRoute = router._matchPath(targetPath)
				matchingRoutes.push(matchingRoute) if matchingRoute

			if not matchingRoutes.length
				for router in listeningRouters when router._fallbackRoute
					matchingRoutes.push(router._fallbackRoute) unless router._basePath and not router._basePath.test(path)

			
			highestPriority = Math.max (matchingRoutes.map (route)-> route.router._priority)...
			matchingRoutes = matchingRoutes.filter (route)-> route.router._priority is highestPriority
			
			for route in matchingRoutes
				route.router._go(route, path, true) unless route.router.current.path is path

			return


		@_registerRouter = (router, initOnStart)->
			listeningRouters.push(router)

			unless listening
				listening = true
				### istanbul ignore next ###
				if window.onhashchange isnt undefined and (not document.documentMode or document.documentMode >= 8)
					window.addEventListener 'hashchange', handleHashChange
				else
					setInterval handleHashChange, 100

			if initOnStart
				path = helpers.currentPath()
				defaultPath = helpers.cleanPath(initOnStart) if typeof initOnStart is 'string'
				return if router._basePath and not router._basePath.test(path) and not defaultPath
				matchingRoute = router._matchPath(helpers.removeBase(path, router._basePath))
				matchingRoute ?= router._matchPath(defaultPath) if defaultPath
				matchingRoute ?= router._fallbackRoute

				if matchingRoute
					path = defaultPath if defaultPath and (matchingRoute is router._fallbackRoute or not matchingRoute.path.test(path))
					router._go(matchingRoute, path, true)


		@killAll = ()->
			routersToKill = routers.slice()
			router.kill() for router in routersToKill
			routers.length = 0
			listeningRouters.length = 0
			return
		

		@Router = (timeout)->
			routers.push routerInstance = new Router(timeout, ++currentID)
			return routerInstance

		@version = import '../.config/.version'
		return @





	### istanbul ignore next ###
	if module?.exports?
		module.exports = Routing
	else if typeof define is 'function' and define.amd
		define ['routing.js'], ()-> Routing
	else
		@Routing = Routing