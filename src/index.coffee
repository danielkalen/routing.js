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
			if matchingRoute
				if matchingRoute.constructor is Array
					matchingRoutes.push(matchingRoute...)
				else
					matchingRoutes.push(matchingRoute)

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
			
			if not matchingRoute and defaultPath
				matchingRoute = router._matchPath(defaultPath)
				path = defaultPath
			
			matchingRoute ?= router._fallbackRoute

			if matchingRoute
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


	@version = import '../package.json $ version'
	return @



module.exports = Routing

