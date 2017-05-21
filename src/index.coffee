do ()->
	Router = import './parts/router'
	helpers = import './parts/helpers'
	
	Routing = new ()->
		changeCallbacks = []
		routers = []
		basePaths = []
		listening = false
		currentID = 0

		dispatchChange = (firstTime)->
			# callback(firstTime is true) for callback in changeCallbacks
			path = helpers.cleanPath(window.location.hash)
			applicableCallbacks = changeCallbacks
			
			if path and basePaths.length
				for basePath in basePaths when basePath.test(path)

					applicableCallbacks = []
					for callback in changeCallbacks
						routerBasePath = callback.router._basePath
						applicableCallbacks.push(callback) if routerBasePath is basePath
					
					break

			callback(path, firstTime is true) for callback in applicableCallbacks
			return

		@_onChange = (router, callback)->
			callback.router = router
			changeCallbacks.push(callback)

			unless listening
				listening = true
				### istanbul ignore next ###
				if window.onhashchange isnt undefined and (not document.documentMode or document.documentMode >= 8)
					window.addEventListener 'hashchange', dispatchChange
				else
					setInterval dispatchChange, 100

			callback(helpers.cleanPath(window.location.hash), true)


		@_registerBasePath = (path)->
			basePaths.push(path)

		@killAll = ()->
			routersToKill = routers.slice()
			for router in routersToKill
				router.kill()
				helpers.removeItem(routers, router)
				helpers.removeItem(changeCallbacks, router._listenCallback)
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