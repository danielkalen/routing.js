mocha.setup('tdd')
mocha.slow(700)
# mocha.timeout(12000)
mocha.bail() unless window.location.hostname
# Promise.config longStackTraces:true
chai.use require('chai-spies')
expect = chai.expect
setHash = (targetHash, delay=1)-> new Promise (resolve)->
	targetHash = getHash(targetHash)
	handler = ()->
		window.removeEventListener('hashchange', handler)
		if delay then Promise.delay(delay).then(resolve) else resolve()
	window.addEventListener('hashchange', handler)
	window.location.hash = targetHash

getHash = (hash=window.location.hash)->
	hash.replace /^#?\/?/, ''


suite "Routing.JS", ()->
	teardown ()-> window.location.hash = ''; Routing.killAll()

	test "routing.Router() will return a new router instance", ()->
		routerA = Routing.Router()
		routerB = Routing.Router()
		expect(routerA).not.to.equal(routerB)
		expect(routerA.ID).to.equal(1)
		expect(routerB.ID).to.equal(2)


	test "router.map() should accept a path and return a cachable Route instance", ()->
		Router = Routing.Router()
		routeA = Router.map('/abc')
		routeB = Router.map('/abc')
		expect(routeA).to.equal(routeB)


	test "a route can be specified with or without forward/backward slashes", ()->
		Router = Routing.Router()
		routeA = Router.map('/abc/')
		routeB = Router.map('/abc')
		routeC = Router.map('abc')
		routeD = Router.map('abc/')
		
		expect(routeA).to.equal(routeB)
		expect(routeB).to.equal(routeC)
		expect(routeC).to.equal(routeD)


	test "a route can be mapped to invoke a specific function on hash change", ()->
		Router = Routing.Router()
		invokeCount = 0
		
		Router.map('/another')
		Router.map('/test').to ()-> invokeCount++
		Promise.resolve(Router.listen())
			.then ()->
				expect(invokeCount).to.equal 0
				setHash('/test')
		
			.then ()->
				expect(invokeCount).to.equal 1
				setHash('/another')

			.then ()->
				expect(invokeCount).to.equal 1
				setHash('test')

			.then ()->
				expect(invokeCount).to.equal 2


	test "route functions will be invoked within a dedicated context", ()->
		Router = Routing.Router()
		invokeCount = 0
		prevContext = null

		Promise.resolve()
			.then ()->
				Router.map('/another')
				Router.map('/test/path').to ()->
					invokeCount++
					expect(@constructor).not.to.equal Object
					expect(@params).to.eql {}
					expect(@path).to.equal 'test/path'
					expect(@segments.length).to.equal 2

					if prevContext
						expect(@).to.equal prevContext
						expect(@persistent).to.equal 'yes'

					@persistent = 'yes'
					prevContext = @
		
				Router.listen()
			.delay()
			.then ()->
				expect(invokeCount).to.equal 0
				setHash('/test/path')

			.then ()->
				expect(invokeCount).to.equal 1
				setHash('/another')

			.then ()->
				expect(invokeCount).to.equal 1
				setHash('/test/path')

			.then ()->
				expect(invokeCount).to.equal 2



	test "a route can have dynamic segments which will be available with resolved values in this.params", ()->
		Router = Routing.Router()
		invokeCount = 0
		context = null

		Promise.resolve()
			.then ()->
				Router.map('/user/:ID/:page').to ()-> invokeCount++; context = @
				Router.map('/admin/:ID/:name?/:page?').to ()-> invokeCount++; context = @
				Router.listen()

			.delay()
			.then ()->
				setHash('/user/12/profile')

			.then ()->
				expect(context).not.to.equal null
				expect(context.params.ID).to.equal '12'
				expect(context.params.page).to.equal 'profile'
				expect(invokeCount).to.equal 1
				setHash('/user/12/settings')
			
			.then ()->
				expect(context.params.ID).to.equal '12'
				expect(context.params.page).to.equal 'settings'
				expect(invokeCount).to.equal 2
				setHash('/user/25/settings')

			.then ()->
				expect(context.params.ID).to.equal '25'
				expect(context.params.page).to.equal 'settings'
				expect(invokeCount).to.equal 3
				setHash('/user/29')
			
			.then ()->	
				expect(context.params.ID).to.equal '25'
				expect(context.params.page).to.equal 'settings'
				expect(invokeCount).to.equal 3
				setHash('/admin/29/kevin/profile')

			.then ()->
				expect(context.params.ID).to.equal '29'
				expect(context.params.name).to.equal 'kevin'
				expect(context.params.page).to.equal 'profile'
				expect(invokeCount).to.equal 4
				setHash('/admin/16/arnold')

			.then ()->
				expect(context.params.ID).to.equal '16'
				expect(context.params.name).to.equal 'arnold'
				expect(context.params.page).to.equal ''
				expect(invokeCount).to.equal 5
				setHash('/admin/54')

			.then ()->
				expect(context.params.ID).to.equal '54'
				expect(context.params.name).to.equal ''
				expect(context.params.page).to.equal ''
				expect(invokeCount).to.equal 6
							

	test "a route can start with a dynamic segment", ()->
		Router = Routing.Router()
		invokeCount = 0
		context = null

		Promise.resolve()
			.then ()->
				Router.map('/:page').to ()-> invokeCount++; context = @
				Router.listen()

			.delay()
			.then ()->
				expect(invokeCount).to.equal 0
				expect(context).to.equal null
				setHash('/user/12/profile')
			
			.then ()->
				expect(invokeCount).to.equal 0
				expect(context).to.equal null
				setHash('/user')
			
			.then ()->
				expect(invokeCount).to.equal 1
				expect(context.params.page).to.equal 'user'
				setHash('/settings')
			
			.then ()->
				expect(invokeCount).to.equal 2
				expect(context.params.page).to.equal 'settings'



	test "a route can be mapped to an entering function which will be invoked when entering the route (before regular action)", ()->
		Router = Routing.Router()
		invokeCount = before:0, reg:0

		Promise.resolve()
			.then ()->
				Router.map('/def456')
				Router.map('/abc123')
					.entering ()-> invokeCount.before++; expect(invokeCount.before - invokeCount.reg).to.equal(1)
					.to ()-> invokeCount.reg++

				Router.listen()

			.delay()
			.then ()->
				expect(invokeCount.before).to.equal 0
				expect(invokeCount.reg).to.equal 0
				setHash('/abc123')

			.then ()->
				expect(invokeCount.before).to.equal 1
				expect(invokeCount.reg).to.equal 1
				setHash('/def456')

			.then ()->
				expect(invokeCount.before).to.equal 1
				expect(invokeCount.reg).to.equal 1
				setHash('/abc123')

			.then ()->
				expect(invokeCount.before).to.equal 2



	test "a route can be mapped to a leaving function which will be invoked when leaving the route", ()->
		Router = Routing.Router()
		invokeCount = after:0, reg:0

		Promise.resolve()
			.then ()->
				Router.map('/def456')
				Router.map('/abc123')
					.to ()-> invokeCount.reg++
					.leaving ()-> invokeCount.after++

				Router.listen()

			.delay()
			.then ()->
				expect(invokeCount.reg).to.equal 0
				expect(invokeCount.after).to.equal 0
				setHash('/abc123')

			.then ()->
				expect(invokeCount.reg).to.equal 1
				expect(invokeCount.after).to.equal 0
				setHash('/def456')

			.then ()->
				expect(invokeCount.reg).to.equal 1
				expect(invokeCount.after).to.equal 1
				setHash('/abc123')

			.then ()->
				expect(invokeCount.reg).to.equal 2
				expect(invokeCount.after).to.equal 1


	test "route actions can return a promise which will be waited to be resolved before continuing", ()->
		Router = Routing.Router()
		invokeCount = before:0, after:0, abc123:0, def456:0
		delays = before:null, abc123:null, after:null
		initDelays = ()->
			delays.before = new Promise ()->
			delays.abc123 = new Promise ()->
			delays.after = new Promise ()->
			return null

		Promise.resolve()
			.then ()->
				Router.map('/abc123')
					.entering ()-> invokeCount.before++; delays.before
					.to ()-> invokeCount.abc123++; delays.abc123
		
				Router.map('/def456')
					.to ()-> invokeCount.def456++;
					.leaving ()-> invokeCount.after++; delays.after

				Router.listen()
				initDelays()

			.delay()
			.then ()->
				setHash('/abc123')

			.then ()->
				expect(invokeCount.before).to.equal 1
				expect(invokeCount.abc123).to.equal 0
				expect(invokeCount.def456).to.equal 0
				expect(invokeCount.after).to.equal 0
				delays.before._fulfill()
				delays.before.delay()

			.then ()->
				expect(invokeCount.before).to.equal 1
				expect(invokeCount.abc123).to.equal 1
				expect(invokeCount.def456).to.equal 0
				expect(invokeCount.after).to.equal 0
				setHash('/def456')

			.then ()->
				expect(invokeCount.before).to.equal 1
				expect(invokeCount.abc123).to.equal 1
				expect(invokeCount.def456).to.equal 0
				expect(invokeCount.after).to.equal 0
				delays.abc123._fulfill()
				delays.abc123.delay()

			.then ()->
				expect(invokeCount.before).to.equal 1
				expect(invokeCount.abc123).to.equal 1
				expect(invokeCount.def456).to.equal 1
				expect(invokeCount.after).to.equal 0
				setHash('/abc123')

			.then ()->
				expect(invokeCount.before).to.equal 1
				expect(invokeCount.abc123).to.equal 1
				expect(invokeCount.def456).to.equal 1
				expect(invokeCount.after).to.equal 1
				delays.after._fulfill()
				delays.after.delay()

			.then ()->
				expect(invokeCount.before).to.equal 2
				expect(invokeCount.abc123).to.equal 2
				expect(invokeCount.def456).to.equal 1
				expect(invokeCount.after).to.equal 1


	test "a default route can be specified in Router.listen() which will be defaulted to if there isn't a matching route for the current hash", ()->
		invokeCount = abc:0, def:0
		Router = null
		createRouter = (targetHash='')->
			setHash(targetHash)
			invokeCount.abc = invokeCount.def = 0
			Router?.kill()
			Router = Routing.Router()
			Router.map('/abc').to ()-> invokeCount.abc++
			Router.map('/def').to ()-> invokeCount.def++
			return Router

		Promise.resolve()
			.then ()-> createRouter().listen()
			.delay()
			.then ()->
				expect(getHash()).to.equal ''
				expect(invokeCount.abc).to.equal 0
				expect(invokeCount.def).to.equal 0
			
			.then ()-> createRouter('def').listen('abc')
			.delay()
			.then ()->
				expect(getHash()).to.equal 'def'
				expect(invokeCount.abc).to.equal 0
				expect(invokeCount.def).to.equal 1
			
			.then ()-> createRouter().listen('/abc')
			.delay()
			.then ()->
				expect(getHash()).to.equal 'abc'
				expect(invokeCount.abc).to.equal 1
				expect(invokeCount.def).to.equal 0
			
			.then ()-> createRouter().listen('def')
			.delay()
			.then ()->
				expect(getHash()).to.equal 'def'
				expect(invokeCount.abc).to.equal 0
				expect(invokeCount.def).to.equal 1
			
			.then ()-> createRouter().listen('/akjsdf')
			.delay()
			.then ()->
				expect(getHash()).to.equal ''
				expect(invokeCount.abc).to.equal 0
				expect(invokeCount.def).to.equal 0


	test "if a falsey value is passed to Router.listen() the initial route match will be skipped", ()->
		window.invokeCount = 0
		Router = null
		createRouter = (initialHash)->
			Router?.kill()
			setHash(initialHash)
			Router = Routing.Router()
			Router.map('/abc').to ()-> invokeCount++
			Router.fallback ()-> invokeCount++
			return Router
		
		Promise.resolve()
			.then ()-> createRouter('c')
			.delay()
			.then ()-> Router.listen()
			.delay()
			.then ()-> expect(invokeCount).to.equal 1

			.then ()-> createRouter('abc')
			.delay()
			.then ()-> Router.listen()
			.delay()
			.then ()-> expect(invokeCount).to.equal 2

			.then ()-> createRouter('def')
			.delay()
			.then ()-> Router.listen()
			.delay()
			.then ()-> expect(invokeCount).to.equal 3

			.then ()-> createRouter('')
			.delay()
			.then ()-> Router.listen(false)
			.delay()
			.then ()-> expect(invokeCount).to.equal 3

			.then ()-> createRouter('abc')
			.delay()
			.then ()-> Router.listen('')
			.delay()
			.then ()-> expect(invokeCount).to.equal 3


	test "a fallback route (e.g. 404) can be specified to be defaulted to when the specified hash has no matching routes", ()->
		invokeCount = abc:0, fallback:0
		Router = Routing.Router()

		Promise.resolve()
			.then ()->
				Router.map('abc').to ()-> invokeCount.abc++
				Router.fallback ()-> invokeCount.fallback++
				Router.listen()
			
			.delay()
			.then ()->
				expect(invokeCount.abc).to.equal 0
				expect(invokeCount.fallback).to.equal 1
				expect(getHash()).to.equal ''
				setHash('abc')
			
			.then ()->				
				expect(getHash()).to.equal 'abc'
				expect(invokeCount.abc).to.equal 1
				expect(invokeCount.fallback).to.equal 1
				setHash('def')
			
			.then ()->				
				expect(getHash()).to.equal 'def'
				expect(invokeCount.abc).to.equal 1
				expect(invokeCount.fallback).to.equal 2
				setHash('')
		
			.then ()->				
				expect(getHash()).to.equal ''
				expect(invokeCount.abc).to.equal 1
				expect(invokeCount.fallback).to.equal 3
				Router.fallback ()-> setHash('abc')
				setHash('aksjdfh')

			.then ()->				
				expect(getHash()).to.equal 'abc'


	test "a failed route transition will cause the router to go to the fallback route if exists", ()->
		invokeCount = 0
		consoleError = console.error
		console.error = chai.spy()

		Promise.delay()
			.then ()-> 
				Router = Routing.Router()
				Router.map('abc').to ()-> Promise.delay().then ()-> throw new Error 'rejected'
				Router.fallback ()-> invokeCount++
				Router.listen()
			
			.delay()
			
			.then ()->
				expect(invokeCount).to.equal 1
				expect(getHash()).to.equal ''
				setHash('abc')
		
			.then ()->
				expect(getHash()).to.equal 'abc'
				expect(invokeCount).to.equal 2
			
			.finally ()-> console.error = consoleError


	test "a failed route transition will cause the router to go to the previous route if no fallback exists", ()->
		invokeCount = 0
		consoleError = console.error
		console.error = chai.spy()
		Router = Routing.Router()

		Promise.delay()
			.then ()-> 
				Router.map('abc').to ()-> invokeCount++
				Router.map('def').to ()-> Promise.delay().then ()-> throw new Error 'rejected'
				Router.listen()
			
			.delay()
			.then ()->
				expect(invokeCount).to.equal 0
				expect(getHash()).to.equal ''
				setHash('abc')
		
			.then ()->
				expect(getHash()).to.equal 'abc'
				expect(invokeCount).to.equal 1
				setHash('def')
		
			.then ()->
				expect(getHash()).to.equal 'abc'
				expect(invokeCount).to.equal 2
			
			.finally ()-> console.error = consoleError


	test "router.beforeAll/afterAll() can take a function which will be executed before/after all route changes", ()->
		invokeCount = before:0, after:0, beforeB:0
		delays = before:null, after:null, afterC:null
		Router = Routing.Router()

		Promise.resolve()
			.then ()->
				Router
					.beforeAll ()-> invokeCount.before++
					.afterAll ()-> invokeCount.after++
					.map('a')
					.map('b').entering ()-> invokeCount.beforeB++
					.map('c').leaving ()-> delays.afterC = Promise.delay(20)
					.listen()

			.delay()
			.then ()->
				expect(invokeCount.before).to.equal 0
				expect(invokeCount.after).to.equal 0
				setHash('a')

			.then ()->
				expect(invokeCount.before).to.equal 1
				expect(invokeCount.after).to.equal 1
				expect(invokeCount.beforeB).to.equal 0
				setHash('b')
			
			.then ()->
				expect(invokeCount.before).to.equal 2
				expect(invokeCount.beforeB).to.equal 1
				expect(invokeCount.after).to.equal 2
				Router
					.beforeAll ()-> invokeCount.before++; delays.before=Promise.delay(7)
					.afterAll ()-> invokeCount.after++; delays.after=Promise.delay(5)
				setHash('c')
				
			.then ()->
				expect(invokeCount.before).to.equal 3
				expect(invokeCount.after).to.equal 2
				Promise.delay(10)
				
			.then ()->
				expect(invokeCount.before).to.equal 3
				expect(invokeCount.after).to.equal 3
				setHash('a',5)

			.then ()->
				expect(invokeCount.before).to.equal 4
				expect(invokeCount.after).to.equal 3
				Promise.delay(10)
				
			.then ()->
				expect(invokeCount.before).to.equal 4
				expect(invokeCount.after).to.equal 3
				Promise.delay(20)
			
			.then ()->
				expect(invokeCount.before).to.equal 4
				expect(invokeCount.after).to.equal 4


	test "route actions & enter actions will be passed with 2 arguments - 1st is the previous path and 2nd is the previous route object", ()->
		Router = Routing.Router()
		args = path:false, route:false
		
		userRoute = Router.map('/user/:ID').to (path, route)-> args = {path,route}
		adminRoute = Router.map('/admin/:ID').to (path, route)-> args = {path,route}
		Promise.resolve()
			.then ()-> Router.listen()
			.delay()
			.then ()->
				expect(args.path).to.equal(false)
				expect(args.route).to.equal(false)
				setHash('/user/1/')
				
			.then ()->
				expect(args.path).to.equal(null)
				expect(args.route).to.equal(null)
				setHash('admin/2')
			
			.then ()->
				expect(args.path).to.equal('user/1')
				expect(args.route).to.equal(userRoute)
				setHash('user/3')

			.then ()->
				expect(args.path).to.equal('admin/2')
				expect(args.route).to.equal(adminRoute)
				setHash('user/4')

			.then ()->
				expect(args.path).to.equal('user/3')
				expect(args.route).to.equal(userRoute)



	test "route leave actions will be passed with 2 arguments - 1st is the future path and 2nd is the future route object", ()->
		Router = Routing.Router()
		userArgs = path:false, route:false
		adminArgs = path:false, route:false
		
		userRoute = Router.map('/user/:ID').leaving (path, route)-> userArgs = {path,route}
		adminRoute = Router.map('/admin/:ID').leaving (path, route)-> adminArgs = {path,route}
		Promise.resolve()
			.then ()-> Router.listen()
			.delay()
			.then ()->
				expect(userArgs.path).to.equal(false)
				expect(userArgs.route).to.equal(false)
				expect(adminArgs.path).to.equal(false)
				expect(adminArgs.route).to.equal(false)
				setHash('/user/1/')
				
			.then ()->
				expect(userArgs.path).to.equal(false)
				expect(userArgs.route).to.equal(false)
				expect(adminArgs.path).to.equal(false)
				expect(adminArgs.route).to.equal(false)
				setHash('admin/2')
			
			.then ()->
				expect(userArgs.path).to.equal('admin/2')
				expect(userArgs.route).to.equal(adminRoute)
				expect(adminArgs.path).to.equal(false)
				expect(adminArgs.route).to.equal(false)
				setHash('user/3')

			.then ()->
				expect(userArgs.path).to.equal('admin/2')
				expect(userArgs.route).to.equal(adminRoute)
				expect(adminArgs.path).to.equal('user/3')
				expect(adminArgs.route).to.equal(userRoute)
				setHash('user/4')

			.then ()->
				expect(userArgs.path).to.equal('user/4')
				expect(userArgs.route).to.equal(userRoute)
				expect(adminArgs.path).to.equal('user/3')
				expect(adminArgs.route).to.equal(userRoute)


	test "router.back/forward() can be used to navigate through history", ()->
		invokeCount = {}
		incCount = (prop)-> invokeCount[prop] ?= 0; invokeCount[prop]++
		
		Router = Routing.Router()
		Promise.resolve()
			.then ()->
				Router.map('AAA').to ()-> incCount('AAA')
				Router.map('BBB').to ()-> incCount('BBB')
				Router.map('CCC').to ()-> incCount('CCC')
				Router.map('DDD').to ()-> incCount('DDD')
				Router.listen()

			.delay()
			.then ()->
				Router.fallback ()-> incCount('fallback')
				expect(invokeCount.AAA).to.equal undefined
				expect(invokeCount.BBB).to.equal undefined
				expect(invokeCount.CCC).to.equal undefined
				expect(invokeCount.DDD).to.equal undefined
				expect(invokeCount.fallback).to.equal undefined
				Router.forward()

			.then ()->
				expect(invokeCount.fallback).to.equal undefined
				Router.back()

			.then ()->
				expect(invokeCount.fallback).to.equal undefined

			.then ()-> setHash('AAA')
			.then ()-> setHash('BBB')
			.then ()-> setHash('CCC')
			.then ()-> setHash('DDD')
			.then ()->
				expect(invokeCount.AAA).to.equal 1
				expect(invokeCount.BBB).to.equal 1
				expect(invokeCount.CCC).to.equal 1
				expect(invokeCount.DDD).to.equal 1
				expect(invokeCount.fallback).to.equal undefined
				Router.back()

			.then ()->
				expect(invokeCount.CCC).to.equal 2
				Router.back()
					
			.then ()->
				expect(invokeCount.BBB).to.equal 2
				Router.forward().then ()-> Router.forward()

			.then ()->
				expect(invokeCount.AAA).to.equal 1
				expect(invokeCount.BBB).to.equal 2
				expect(invokeCount.CCC).to.equal 3
				expect(invokeCount.DDD).to.equal 2
				Router.back().then ()-> Router.back()

			.then ()->
				expect(invokeCount.AAA).to.equal 1
				expect(invokeCount.BBB).to.equal 3
				expect(invokeCount.CCC).to.equal 4
				expect(invokeCount.DDD).to.equal 2
				Router.back()

			.then ()->
				expect(invokeCount.AAA).to.equal 2
				expect(invokeCount.BBB).to.equal 3
				expect(invokeCount.CCC).to.equal 4
				expect(invokeCount.DDD).to.equal 2
				expect(getHash()).to.equal 'AAA'
				Router.back()

			.then ()->
				expect(invokeCount.AAA).to.equal 2
				expect(invokeCount.BBB).to.equal 3
				expect(invokeCount.CCC).to.equal 4
				expect(invokeCount.DDD).to.equal 2
				expect(getHash()).to.equal 'AAA'


	test "router.refresh() can be used to create refresh the current route", ()->
		invokeCount = 
			abc: {before:0, reg:0, after:0}
			def: {before:0, reg:0, after:0}
		
		Router = Routing.Router()
		Promise.resolve()
			.then ()->
				Router
					.map('abc')
						.entering ()-> invokeCount.abc.before++
						.to ()-> invokeCount.abc.reg++
						.leaving ()-> invokeCount.abc.after++
				
					.map('def')
						.entering ()-> invokeCount.def.before++
						.to ()-> invokeCount.def.reg++
						.leaving ()-> invokeCount.def.after++

					.listen()

			.delay()
			.then ()->
				setHash('abc')
				
			.then ()->
				expect(invokeCount.abc.before).to.equal 1
				expect(invokeCount.abc.reg).to.equal 1
				expect(invokeCount.abc.after).to.equal 0
				expect(invokeCount.def.before).to.equal 0
				expect(invokeCount.def.reg).to.equal 0
				expect(invokeCount.def.after).to.equal 0
				setHash('def')

			.then ()->
				expect(invokeCount.abc.before).to.equal 1
				expect(invokeCount.abc.reg).to.equal 1
				expect(invokeCount.abc.after).to.equal 1
				expect(invokeCount.def.before).to.equal 1
				expect(invokeCount.def.reg).to.equal 1
				expect(invokeCount.def.after).to.equal 0
				Router.refresh()

			.then ()->
				expect(invokeCount.abc.before).to.equal 1
				expect(invokeCount.abc.reg).to.equal 1
				expect(invokeCount.abc.after).to.equal 1
				expect(invokeCount.def.before).to.equal 2
				expect(invokeCount.def.reg).to.equal 2
				expect(invokeCount.def.after).to.equal 1
				Router.refresh()

			.then ()->
				expect(invokeCount.abc.before).to.equal 1
				expect(invokeCount.abc.reg).to.equal 1
				expect(invokeCount.abc.after).to.equal 1
				expect(invokeCount.def.before).to.equal 3
				expect(invokeCount.def.reg).to.equal 3
				expect(invokeCount.def.after).to.equal 2


	test "route.filters() can accept a param:filterFn object map which will be invoked for each param on route matching and will use the return value to decide the match result", ()->
		invokeCount = route:0, fallback:0
		params = {}
		Router = Routing.Router()
		
		Router.fallback ()-> invokeCount.fallback++
		Router
			.map('/api/:version/:function?/:username?')
				.to ()-> invokeCount.route++; params = @params
				.filters 
					version: (version)-> version.length is 1 and /\d/.test(version)
					username: (username)-> username and /^[^\d]+$/.test(username)

			.map('/api/:version/')
				.to ()-> invokeCount.route++; params = @params
				.filters 
					version: (version)-> version.length is 1 and /\d/.test(version)
					username: (username)-> username and /^[^\d]+$/.test(username)

		Promise.resolve(Router.listen()).delay()
			.then ()->
				expect(invokeCount.route).to.equal 0
				expect(invokeCount.fallback).to.equal 1
				setHash('/api/3/anything/daniel')

			.then ()->
				expect(invokeCount.route).to.equal 1
				expect(invokeCount.fallback).to.equal 1
				expect(params).to.eql {version:'3', function:'anything', username:'daniel'}
				setHash('/api/3/9/daniel')
			
			.then ()->
				expect(invokeCount.route).to.equal 2
				expect(invokeCount.fallback).to.equal 1
				expect(params).to.eql {version:'3', function:'9', username:'daniel'}
				setHash('/api/13/anything/daniel')

			.then ()->
				expect(invokeCount.route).to.equal 2
				expect(invokeCount.fallback).to.equal 2
				setHash('/api/5/anything/dani3el')
	
			.then ()->
				expect(invokeCount.route).to.equal 2
				expect(invokeCount.fallback).to.equal 3
				setHash('/api/5//kevin')

			.then ()->
				expect(invokeCount.route).to.equal 3
				expect(invokeCount.fallback).to.equal 3
				expect(params).to.eql {version:'5', function:'', username:'kevin'}


	test "routing.Router() accpets a number-type argument which will be used as the route loading timeout (ms)", ()->
		consoleError = console.error
		console.error = chai.spy()
		invokeCount = abc:0, def:0, ghi:0
		delay = abc:0, def:0
		Router = Routing.Router(20)
		
		Promise.resolve()
			.then ()->
				Router.map('abc').to ()-> invokeCount.abc++; Promise.delay(delay.abc)
				Router.map('def').to ()-> invokeCount.def++; Promise.delay(delay.def)
				Router.map('ghi').to ()-> invokeCount.ghi++;
				Router.listen()

			.delay()
			.then ()->
				setHash('abc', 5)

			.then ()->
				expect(invokeCount.abc).to.equal 1
				expect(invokeCount.def).to.equal 0
				expect(invokeCount.ghi).to.equal 0
				expect(console.error).to.have.been.called.exactly 0
				expect(Router.current.path).to.equal 'abc'
				expect(getHash()).to.equal 'abc'
				delay.abc = delay.def = 10
				setHash('def', 15)

			.then ()->
				expect(invokeCount.abc).to.equal 1
				expect(invokeCount.def).to.equal 1
				expect(invokeCount.ghi).to.equal 0
				expect(console.error).to.have.been.called.exactly 0
				expect(Router.current.path).to.equal 'def'
				expect(getHash()).to.equal 'def'
				delay.abc = 20
				setHash('abc', 25)

			.then ()->
				expect(invokeCount.abc).to.equal 2
				expect(invokeCount.def).to.equal 2
				expect(invokeCount.ghi).to.equal 0
				expect(console.error).to.have.been.called.exactly 1
				expect(Router.current.path).to.equal 'def'
				expect(getHash()).to.equal 'def'
				delay.def = 20
				setHash('ghi', 10)

			.then ()->
				expect(invokeCount.abc).to.equal 2
				expect(invokeCount.def).to.equal 2
				expect(invokeCount.ghi).to.equal 1
				expect(console.error).to.have.been.called.exactly 1
				expect(Router.current.path).to.equal 'ghi'
				expect(getHash()).to.equal 'ghi'
				setHash('def', 30)

			.then ()->
				expect(invokeCount.abc).to.equal 2
				expect(invokeCount.def).to.equal 3
				expect(invokeCount.ghi).to.equal 2
				expect(console.error).to.have.been.called.exactly 2
				expect(Router.current.path).to.equal 'ghi'
				expect(getHash()).to.equal 'ghi'


	test "a base path can be specified via Routing.base() and will only match routes that begin with the base", ()->
		base = 'theBase/goes/here'
		Router = Routing.Router()
		invokeCount = abc:0, def:0, fallback:0
		
		Promise.resolve()
			.then ()->
				Router
					.base(base)
					.fallback ()-> invokeCount.fallback++
					.map('abc').to ()-> invokeCount.abc++
					.map('def').to ()-> invokeCount.def++
					.listen()
			
			.delay()
			.then ()->
				expect(invokeCount.abc).to.equal 0
				expect(invokeCount.def).to.equal 0
				expect(invokeCount.fallback).to.equal 0
				setHash('abc')

			.then ()->
				expect(invokeCount.abc).to.equal 0
				expect(invokeCount.def).to.equal 0
				expect(invokeCount.fallback).to.equal 0
				expect(Router.current.path).to.equal null
				expect(getHash()).to.equal 'abc'
				setHash("#{base}/abc")

			.then ()->
				expect(invokeCount.abc).to.equal 1
				expect(invokeCount.def).to.equal 0
				expect(invokeCount.fallback).to.equal 0
				expect(Router.current.path).to.equal "#{base}/abc"
				expect(getHash()).to.equal "#{base}/abc"
				setHash('def')

			.then ()->
				expect(invokeCount.abc).to.equal 1
				expect(invokeCount.def).to.equal 0
				expect(invokeCount.fallback).to.equal 0
				expect(Router.current.path).to.equal "#{base}/abc"
				expect(getHash()).to.equal "def"
				setHash("#{base}/def")

			.then ()->
				expect(invokeCount.abc).to.equal 1
				expect(invokeCount.def).to.equal 1
				expect(invokeCount.fallback).to.equal 0
				expect(Router.current.path).to.equal "#{base}/def"
				expect(getHash()).to.equal "#{base}/def"


	test "routers with base paths should have their .go() method auto-prefix paths with the base path if they do not have it", ()->
		base = 'theBase/goes/here'
		invokeCount = abc:0, def:0
		Router = Routing.Router()
		
		Promise.resolve()
			.then ()->
				Router
					.base(base)
					.map('abc').to ()-> invokeCount.abc++
					.map('def').to ()-> invokeCount.def++
					.listen()			

			.delay()
			.then ()->
				expect(invokeCount.abc).to.equal 0
				expect(invokeCount.def).to.equal 0
				Router.go('abc')

			.then ()->
				expect(invokeCount.abc).to.equal 1
				expect(invokeCount.def).to.equal 0
				expect(Router.current.path).to.equal "#{base}/abc"
				expect(getHash()).to.equal "#{base}/abc"
				Router.go('/def')

			.then ()->
				expect(invokeCount.abc).to.equal 1
				expect(invokeCount.def).to.equal 1
				expect(Router.current.path).to.equal "#{base}/def"
				expect(getHash()).to.equal "#{base}/def"
				Router.go("#{base}/abc")

			.then ()->
				expect(invokeCount.abc).to.equal 2
				expect(invokeCount.def).to.equal 1
				expect(Router.current.path).to.equal "#{base}/abc"
				expect(getHash()).to.equal "#{base}/abc"
				Router.go("#{base}/def")

			.then ()->
				expect(invokeCount.abc).to.equal 2
				expect(invokeCount.def).to.equal 2
				expect(Router.current.path).to.equal "#{base}/def"
				expect(getHash()).to.equal "#{base}/def"


	test "default paths will work with routers that have a base path specified", ()->
		base = 'theBase/goes/here'
		Router = Routing.Router()
		invokeCount = abc:0, def:0, fallback:0
		
		Promise.resolve()
			.then ()->
				Router
					.base(base)
					.fallback ()-> invokeCount.fallback++
					.map('abc').to ()-> invokeCount.abc++
					.map('def').to ()-> invokeCount.def++
					.listen('def')
			
			.delay()
			.then ()->
				expect(invokeCount.abc).to.equal 0
				expect(invokeCount.def).to.equal 1
				expect(invokeCount.fallback).to.equal 0
				setHash('abc')
			
			.then ()->
				Router.kill()
				setHash('')
				Router
					.base(base)
					.fallback ()-> invokeCount.fallback++
					.map('abc').to ()-> invokeCount.abc++
					.map('def').to ()-> invokeCount.def++
					.listen('kabugaguba')
			
			.delay()
			.then ()->
				expect(invokeCount.abc).to.equal 0
				expect(invokeCount.def).to.equal 1
				expect(invokeCount.fallback).to.equal 1
				setHash('abc')


	test "a route can be removed by calling its .remove() method or by invoking this.remove() from inside the route", ()->
		invokeCount = {abc:0, def:0}
		Router = Routing.Router()
		abcRoute = Router.map('abc').to ()-> invokeCount.abc++
		defRoute = Router.map('def').to ()-> invokeCount.def++

		Promise.resolve()
			.then ()-> Router.listen()
			.delay()
			.then ()->
				expect(invokeCount.abc).to.equal 0
				expect(invokeCount.def).to.equal 0
				expect(getHash()).to.equal ''
				setHash('abc')
			
			.then ()->
				expect(invokeCount.abc).to.equal 1
				expect(invokeCount.def).to.equal 0
				expect(getHash()).to.equal 'abc'
				setHash('def').then ()-> setHash('abc')
			
			.then ()->
				expect(invokeCount.abc).to.equal 2
				expect(invokeCount.def).to.equal 1
				expect(getHash()).to.equal 'abc'
				abcRoute.remove()
				setHash('def').then ()-> setHash('abc')
			
			.then ()->
				expect(invokeCount.abc).to.equal 2
				expect(invokeCount.def).to.equal 2
				expect(getHash()).to.equal 'abc'
				# abcRoute.remove()
				# setHash('def').then ()-> setHash('abc')


	test "a router's .go() method can only accept strings", ()->
		invokeCount = 0
		router = Routing.Router()

		Promise.resolve()
			.then ()->
				router.map('abc').to ()-> invokeCount++
				router.fallback ()-> invokeCount++
				router.listen()

			.delay()
			.then ()->
				expect(invokeCount).to.equal 1
				router.go 'd'
			
			.then ()->
				expect(invokeCount).to.equal 2
				router.go ''
			
			.then ()->
				expect(invokeCount).to.equal 3
				router.go null
			
			.then ()->
				expect(invokeCount).to.equal 3
				router.go()
			
			.then ()->
				expect(invokeCount).to.equal 3
				router.go(true)
			
			.then ()->
				expect(invokeCount).to.equal 3


	test "invoking router.go() with the same path as the current route will trigger no changes", ()->
		invokeCount = 0
		router = Routing.Router()

		Promise.resolve()
			.then ()->
				router.map('abc').to ()-> invokeCount++
				router.fallback ()-> invokeCount++
				router.listen()

			.delay()
			.then ()->
				expect(invokeCount).to.equal 1
				router.go 'abc'
			
			.then ()->
				expect(invokeCount).to.equal 2
				router.go 'abc'
			
			.then ()->
				expect(invokeCount).to.equal 2


	test "the .go/.refresh/.back/forward methods should always return promises", ()->
		invokeCount = 0
		router = Routing.Router()
		expect(typeof router.go().then).to.equal 'function'
		expect(typeof router.refresh().then).to.equal 'function'
		expect(typeof router.back().then).to.equal 'function'
		expect(typeof router.forward().then).to.equal 'function'


	test "a route can invoke its router's .go() command from its function body", ()->
		invokeCount = {abc:0, def:0}
		router = Routing.Router()

		Promise.resolve()
			.then ()->
				router.map('abc').to ()-> invokeCount.abc++; router.go('def')
				router.map('def').to ()-> invokeCount.def++
				router.listen()

			.delay()
			.then ()->
				expect(invokeCount.abc).to.equal 0
				expect(invokeCount.def).to.equal 0
				router.go 'abc'
			
			.delay()
			.then ()->
				expect(invokeCount.abc).to.equal 1
				expect(invokeCount.def).to.equal 1
				router.go 'def'
			
			.delay()
			.then ()->
				expect(invokeCount.abc).to.equal 1
				expect(invokeCount.def).to.equal 1
				router.go 'abc'
			
			.delay()
			.then ()->
				expect(invokeCount.abc).to.equal 2
				expect(invokeCount.def).to.equal 2
				router.go 'def'


	test "router.priority(number) can be used to define a priority which will be used to decide which router to invoke when multiple routers match a path", ()->
		invokeCount = {a:0,b:0}
		routerA = Routing.Router()
		routerB = Routing.Router()

		Promise.resolve()
			.then ()->
				routerA.map('abc').to ()-> invokeCount.a++
				routerA.map('def').to ()->
				routerB.map('abc').to ()-> invokeCount.b++
				routerB.map('def').to ()->
				routerA.listen()
				routerB.listen()

			.delay()
			.then ()->
				expect(invokeCount.a).to.equal 0
				expect(invokeCount.b).to.equal 0
				setHash('abc')
			
			.then ()->
				expect(invokeCount.a).to.equal 1
				expect(invokeCount.b).to.equal 1
				setHash('def').then ()-> setHash('abc')
			
			.then ()->
				expect(invokeCount.a).to.equal 2
				expect(invokeCount.b).to.equal 2
				routerA.priority(3)
				routerB.priority(2)
				setHash('def').then ()-> setHash('abc')
			
			.then ()->
				expect(invokeCount.a).to.equal 3
				expect(invokeCount.b).to.equal 2
				routerB.priority(5)
				setHash('def').then ()-> setHash('abc')
			
			.then ()->
				expect(invokeCount.a).to.equal 3
				expect(invokeCount.b).to.equal 3
				routerA.priority(10)
				routerB.priority(10)
				setHash('def').then ()-> setHash('abc')
			
			.then ()->
				expect(invokeCount.a).to.equal 4
				expect(invokeCount.b).to.equal 4
				routerA.priority(10)
				routerB.priority(10)
				setHash('def').then ()-> setHash('abc')


	test "router.priority() can only accept number types that are >= 1", ()->
		invokeCount = {a:0,b:0}
		routerA = Routing.Router()
		routerB = Routing.Router()

		Promise.resolve()
			.then ()->
				routerA.map('abc').to ()-> invokeCount.a++
				routerA.map('def').to ()->
				routerB.map('abc').to ()-> invokeCount.b++
				routerB.map('def').to ()->
				routerA.priority(0).listen()
				routerB.listen()

			.delay()
			.then ()->
				expect(invokeCount.a).to.equal 0
				expect(invokeCount.b).to.equal 0
				setHash('abc')
			
			.then ()->
				expect(invokeCount.a).to.equal 1
				expect(invokeCount.b).to.equal 1
				routerB.priority(NaN)
				setHash('def').then ()-> setHash('abc')
			
			.then ()->
				expect(invokeCount.a).to.equal 2
				expect(invokeCount.b).to.equal 2
				routerA.priority('5')
				setHash('def').then ()-> setHash('abc')
			
			.then ()->
				expect(invokeCount.a).to.equal 3
				expect(invokeCount.b).to.equal 3




	test "router.kill() will destroy the router instance and will remove all handlers", ()->
		RouterA = Routing.Router()
		RouterB = Routing.Router()
		invokeCountA = {}
		invokeCountB = {}

		defineRoutes = (router, invokeCount)->
			router.map('AAA').to ()-> invokeCount.AAA ?= 0; invokeCount.AAA++
			router.map('BBB').to ()-> invokeCount.BBB ?= 0; invokeCount.BBB++
			router.map('CCC').to ()-> invokeCount.CCC ?= 0; invokeCount.CCC++
			router.listen()

		invokeChanges = ()->
			Promise.resolve()
				.then ()-> setHash('AAA')
				.then ()-> setHash('BBB')
				.then ()-> setHash('CCC')

		Promise.resolve()
			.then ()->
				defineRoutes(RouterA, invokeCountA)
				defineRoutes(RouterB, invokeCountB)
				invokeChanges()
			
			.delay()
			.then ()->
				expect(invokeCountA.AAA).to.equal 1
				expect(invokeCountA.BBB).to.equal 1
				expect(invokeCountA.CCC).to.equal 1
				expect(invokeCountB.AAA).to.equal 1
				expect(invokeCountB.BBB).to.equal 1
				expect(invokeCountB.CCC).to.equal 1
				invokeChanges()
				
			.then ()->
				expect(invokeCountA.AAA).to.equal 2
				expect(invokeCountA.BBB).to.equal 2
				expect(invokeCountA.CCC).to.equal 2
				expect(invokeCountB.AAA).to.equal 2
				expect(invokeCountB.BBB).to.equal 2
				expect(invokeCountB.CCC).to.equal 2
				RouterA.kill()
				invokeChanges()
				
			.then ()->
				expect(invokeCountA.AAA).to.equal 2
				expect(invokeCountA.BBB).to.equal 2
				expect(invokeCountA.CCC).to.equal 2
				expect(invokeCountB.AAA).to.equal 3
				expect(invokeCountB.BBB).to.equal 3
				expect(invokeCountB.CCC).to.equal 3



	test "routing.killAll() will destroy all existing router instances and will remove all handlers", ()->
		RouterA = Routing.Router()
		RouterB = Routing.Router()
		invokeCountA = {}
		invokeCountB = {}

		defineRoutes = (router, invokeCount)->
			router.map('AAA').to ()-> invokeCount.AAA ?= 0; invokeCount.AAA++
			router.map('BBB').to ()-> invokeCount.BBB ?= 0; invokeCount.BBB++
			router.map('CCC').to ()-> invokeCount.CCC ?= 0; invokeCount.CCC++
			router.listen()

		invokeChanges = ()->
			Promise.resolve()
				.then ()-> setHash('AAA')
				.then ()-> setHash('BBB')
				.then ()-> setHash('CCC')

		Promise.resolve()
			.then ()->
				defineRoutes(RouterA, invokeCountA)
				defineRoutes(RouterB, invokeCountB)
				invokeChanges()
			
			.delay()
			.then ()->
				expect(invokeCountA.AAA).to.equal 1
				expect(invokeCountA.BBB).to.equal 1
				expect(invokeCountA.CCC).to.equal 1
				expect(invokeCountB.AAA).to.equal 1
				expect(invokeCountB.BBB).to.equal 1
				expect(invokeCountB.CCC).to.equal 1
				invokeChanges()
				
			.then ()->
				expect(invokeCountA.AAA).to.equal 2
				expect(invokeCountA.BBB).to.equal 2
				expect(invokeCountA.CCC).to.equal 2
				expect(invokeCountB.AAA).to.equal 2
				expect(invokeCountB.BBB).to.equal 2
				expect(invokeCountB.CCC).to.equal 2
				Routing.killAll()
				invokeChanges()
				
			.then ()->
				expect(invokeCountA.AAA).to.equal 2
				expect(invokeCountA.BBB).to.equal 2
				expect(invokeCountA.CCC).to.equal 2
				expect(invokeCountB.AAA).to.equal 2
				expect(invokeCountB.BBB).to.equal 2
				expect(invokeCountB.CCC).to.equal 2












