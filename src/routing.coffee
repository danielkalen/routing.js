do ()->
	Router = import './parts/router'
	helpers = import './parts/helpers'
	
	Routing = new ()->
		changeCallbacks = []
		routers = []
		listening = false
		currentID = 0

		dispatchChange = (firstTime)->
			callback(firstTime is true) for callback in changeCallbacks
			return

		@_onChange = (callback)->
			changeCallbacks.push(callback)

			if listening
				callback(true)
			else
				listening = true
				### istanbul ignore next ###
				if window.onhashchange isnt undefined and (not document.documentMode or document.documentMode >= 8)
					window.addEventListener 'hashchange', dispatchChange
				else
					setInterval dispatchChange, 100

				dispatchChange(true)

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