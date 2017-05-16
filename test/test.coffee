mocha.setup('tdd')
mocha.slow(700)
# mocha.timeout(12000)
mocha.bail() unless window.location.hostname
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

	test "Routing.Router() will return a new router instance", ()->
		routerA = Routing.Router()
		routerB = Routing.Router()
		expect(routerA).not.to.equal(routerB)


	test "Router.map() should accept a path and return a cachable Route instance", ()->
		Router = Routing.Router()
		routeA = Router.map('/abc')
		routeB = Router.map('/abc')
		expect(routeA).to.equal(routeB)


	test "A route can be specified with or without forward/backward slashes", ()->
		Router = Routing.Router()
		routeA = Router.map('/abc/')
		routeB = Router.map('/abc')
		routeC = Router.map('abc')
		routeD = Router.map('abc/')
		
		expect(routeA).to.equal(routeB)
		expect(routeB).to.equal(routeC)
		expect(routeC).to.equal(routeD)


	test "A route can be mapped to invoke a specific function on hash change", ()->
		Router = Routing.Router()
		invokeCount = 0
		
		Router.map('/another')
		Router.map('/test').to ()-> invokeCount++
		Router.listen()
		
		expect(invokeCount).to.equal 0

		setHash('/test').then ()->
			expect(invokeCount).to.equal 1

			setHash('/another').then ()->
				expect(invokeCount).to.equal 1

				setHash('test').then ()->
					expect(invokeCount).to.equal 2


	test "Route functions will be invoked within a dedicated context", ()->
		Router = Routing.Router()
		invokeCount = 0
		prevContext = null

		Router.map('/another')
		Router.map('/test/path').to ()->
			invokeCount++
			expect(@constructor).to.equal Object
			expect(@params).to.eql {}
			expect(@path).to.equal 'test/path'
			expect(@segments.length).to.equal 2

			if prevContext
				expect(@).to.equal prevContext
				expect(@persistent).to.equal 'yes'

			@persistent = 'yes'
			prevContext = @
		

		Router.listen()		
		expect(invokeCount).to.equal 0

		setHash('/test/path').then ()->
			expect(invokeCount).to.equal 1

			setHash('/another').then ()->
				expect(invokeCount).to.equal 1

				setHash('/test/path').then ()->
					expect(invokeCount).to.equal 2


	test "A route can have dynamic segments which will be available with resolved values in this.params", ()->
		Router = Routing.Router()
		invokeCount = 0
		context = null

		Router.map('/user/:ID/:page').to ()-> invokeCount++; context = @
		Router.listen()

		setHash('/user/12/profile').then ()->
			expect(context).not.to.equal null
			expect(context.params.ID).to.equal '12'
			expect(context.params.page).to.equal 'profile'
			expect(invokeCount).to.equal 1
			
			setHash('/user/12/settings').then ()->
				expect(context.params.ID).to.equal '12'
				expect(context.params.page).to.equal 'settings'
				expect(invokeCount).to.equal 2
				
				setHash('/user/25/settings').then ()->
					expect(context.params.ID).to.equal '25'
					expect(context.params.page).to.equal 'settings'
					expect(invokeCount).to.equal 3
					
					setHash('/user/29').then ()->
						expect(context.params.ID).to.equal '29'
						expect(context.params.page).to.equal ''
						expect(invokeCount).to.equal 4


	test "A route can be mapped to an entering function which will be invoked when entering the route (before regular action)", ()->
		Router = Routing.Router()
		invokeCount = before:0, reg:0

		Router.map('/def456')
		Router.map('/abc123')
			.entering ()-> invokeCount.before++; expect(invokeCount.before - invokeCount.reg).to.equal(1)
			.to ()-> invokeCount.reg++

		Router.listen()
		
		expect(invokeCount.before).to.equal 0
		expect(invokeCount.reg).to.equal 0

		setHash('/abc123').then ()->
			expect(invokeCount.before).to.equal 1
			expect(invokeCount.reg).to.equal 1

			setHash('/def456').then ()->
				expect(invokeCount.before).to.equal 1
				expect(invokeCount.reg).to.equal 1

				setHash('/abc123').then ()->
					expect(invokeCount.before).to.equal 2


	test "A route can be mapped to a leaving function which will be invoked when leaving the route", ()->
		Router = Routing.Router()
		invokeCount = after:0, reg:0

		Router.map('/def456')
		Router.map('/abc123')
			.to ()-> invokeCount.reg++
			.leaving ()-> invokeCount.after++

		Router.listen()
		
		expect(invokeCount.reg).to.equal 0
		expect(invokeCount.after).to.equal 0

		setHash('/abc123').then ()->
			expect(invokeCount.reg).to.equal 1
			expect(invokeCount.after).to.equal 0

			setHash('/def456').then ()->
				expect(invokeCount.reg).to.equal 1
				expect(invokeCount.after).to.equal 1

				setHash('/abc123').then ()->
					expect(invokeCount.reg).to.equal 2
					expect(invokeCount.after).to.equal 1


	test "Route actions can return a promise which will be waited to be resolved before continuing", ()->
		Router = Routing.Router()
		invokeCount = before:0, after:0, abc123:0, def456:0
		delays = before:null, abc123:null, after:null
		initDelays = ()->
			delays.before = new Promise ()->
			delays.abc123 = new Promise ()->
			delays.after = new Promise ()->

		Router.map('/abc123')
			.entering ()-> invokeCount.before++; delays.before
			.to ()-> invokeCount.abc123++; delays.abc123
		
		Router.map('/def456')
			.to ()-> invokeCount.def456++;
			.leaving ()-> invokeCount.after++; delays.after

		Router.listen()
		initDelays()

		setHash('/abc123').then ()->
			expect(invokeCount.before).to.equal 1
			expect(invokeCount.abc123).to.equal 0
			expect(invokeCount.def456).to.equal 0
			expect(invokeCount.after).to.equal 0

			delays.before._fulfill()
			delays.before.delay().then ()->
				expect(invokeCount.before).to.equal 1
				expect(invokeCount.abc123).to.equal 1
				expect(invokeCount.def456).to.equal 0
				expect(invokeCount.after).to.equal 0

				setHash('/def456').then ()->
					expect(invokeCount.before).to.equal 1
					expect(invokeCount.abc123).to.equal 1
					expect(invokeCount.def456).to.equal 0
					expect(invokeCount.after).to.equal 0

					delays.abc123._fulfill()
					delays.abc123.delay().then ()->
						expect(invokeCount.before).to.equal 1
						expect(invokeCount.abc123).to.equal 1
						expect(invokeCount.def456).to.equal 1
						expect(invokeCount.after).to.equal 0

						setHash('/abc123').then ()->
							expect(invokeCount.before).to.equal 1
							expect(invokeCount.abc123).to.equal 1
							expect(invokeCount.def456).to.equal 1
							expect(invokeCount.after).to.equal 1

							delays.after._fulfill()
							delays.after.delay().then ()->
								expect(invokeCount.before).to.equal 2
								expect(invokeCount.abc123).to.equal 2
								expect(invokeCount.def456).to.equal 1
								expect(invokeCount.after).to.equal 1


	test "A root route can be specified which will be defaulted to on Router.listen() if there isn't a matching route for the current hash", ()->
		invokeCount = abc:0, def:0
		createRouter = ()->
			setHash('')
			invokeCount.abc = invokeCount.def = 0
			Router = Routing.Router()
			Router.map('/abc').to ()-> invokeCount.abc++
			Router.map('/def').to ()-> invokeCount.def++
			return Router

		Router = createRouter()
		Router.listen()._pendingRoute.then ()->
			expect(getHash()).to.equal ''
			expect(invokeCount.abc).to.equal 0
			expect(invokeCount.def).to.equal 0
			
			Router = createRouter()
			Router.root('/abc').listen()._pendingRoute.then ()->
				expect(getHash()).to.equal 'abc'
				expect(invokeCount.abc).to.equal 1
				expect(invokeCount.def).to.equal 0
				
				Router = createRouter()
				Router.root('/def').listen()._pendingRoute.then ()->
					expect(getHash()).to.equal 'def'
					expect(invokeCount.abc).to.equal 0
					expect(invokeCount.def).to.equal 1
					
					Router = createRouter()
					Router.root('/akjsdf').listen()._pendingRoute.then ()->
						expect(getHash()).to.equal ''
						expect(invokeCount.abc).to.equal 0
						expect(invokeCount.def).to.equal 0


	test "A fallback route (e.g. 404) can be specified to be defaulted to when the specified hash has no matching routes", ()->
		invokeCount = abc:0, fallback:0
		Router = Routing.Router()
		Router.map('abc').to ()-> invokeCount.abc++
		Router.fallback ()-> invokeCount.fallback++
		Router.listen()

		Promise.delay().then ()->
			expect(invokeCount.abc).to.equal 0
			expect(invokeCount.fallback).to.equal 1
			expect(getHash()).to.equal ''
			
			setHash('abc').then ()->
				expect(getHash()).to.equal 'abc'
				expect(invokeCount.abc).to.equal 1
				expect(invokeCount.fallback).to.equal 1
			
				setHash('def').then ()->
					expect(getHash()).to.equal 'def'
					expect(invokeCount.abc).to.equal 1
					expect(invokeCount.fallback).to.equal 2
			
					setHash('').then ()->
						expect(getHash()).to.equal ''
						expect(invokeCount.abc).to.equal 1
						expect(invokeCount.fallback).to.equal 3

						
						Router.fallback ()-> setHash('abc')
						setHash('aksjdfh').then ()->
							expect(getHash()).to.equal 'abc'


	test "A failed route transition will cause the router to go to the fallback route if exists", ()->
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


	test "A failed route transition will cause the router to go to the previous route if no fallback exists", ()->
		invokeCount = 0
		consoleError = console.error
		console.error = chai.spy()

		Promise.delay()
			.then ()-> 
				Router = Routing.Router()
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


	test "Router.beforeAll/afterAll() can take a function which will be executed before/after all route changes", ()->
		invokeCount = before:0, after:0, beforeB:0
		delays = before:null, after:null, afterC:null
		Router = Routing.Router()

		Router.map('a')
		Router.map('b').entering ()-> invokeCount.beforeB++
		Router.map('c').leaving ()-> delays.afterC = Promise.delay(20)
		Router
			.beforeAll ()-> invokeCount.before++
			.afterAll ()-> invokeCount.after++
			.listen()

		expect(invokeCount.before).to.equal 0
		expect(invokeCount.after).to.equal 0

		setHash('a').then ()->
			expect(invokeCount.before).to.equal 1
			expect(invokeCount.after).to.equal 1
			expect(invokeCount.beforeB).to.equal 0
		
			setHash('b').then ()->
				expect(invokeCount.before).to.equal 2
				expect(invokeCount.beforeB).to.equal 1
				expect(invokeCount.after).to.equal 2
				

				Router
					.beforeAll ()-> invokeCount.before++; delays.before=Promise.delay(7)
					.afterAll ()-> invokeCount.after++; delays.after=Promise.delay(5)
		
				setHash('c').then ()->
					expect(invokeCount.before).to.equal 3
					expect(invokeCount.after).to.equal 2
					
					Promise.delay(10).then ()->
						expect(invokeCount.before).to.equal 3
						expect(invokeCount.after).to.equal 3
		
						setHash('a',5).then ()->
							expect(invokeCount.before).to.equal 4
							expect(invokeCount.after).to.equal 3
							
							Promise.delay(10).then ()->
								expect(invokeCount.before).to.equal 4
								expect(invokeCount.after).to.equal 3
							
								Promise.delay(20).then ()->
									expect(invokeCount.before).to.equal 4
									expect(invokeCount.after).to.equal 4


	test "Route actions & enter actions will be passed with 2 arguments - 1st is the previous path and 2nd is the previous route object", ()->
		Router = Routing.Router()
		args = path:false, route:false
		
		userRoute = Router.map('/user/:ID').to (path, route)-> args = {path,route}
		adminRoute = Router.map('/admin/:ID').to (path, route)-> args = {path,route}
		Router.listen()

		expect(args.path).to.equal(false)
		expect(args.route).to.equal(false)
		
		setHash('/user/1/').then ()->
			expect(args.path).to.equal(null)
			expect(args.route).to.equal(null)
		
			setHash('admin/2').then ()->
				expect(args.path).to.equal('user/1')
				expect(args.route).to.equal(userRoute)
		
				setHash('user/3').then ()->
					expect(args.path).to.equal('admin/2')
					expect(args.route).to.equal(adminRoute)
		
					setHash('user/4').then ()->
						expect(args.path).to.equal('user/3')
						expect(args.route).to.equal(userRoute)


	test "Route leave actions will be passed with 2 arguments - 1st is the future path and 2nd is the future route object", ()->
		Router = Routing.Router()
		userArgs = path:false, route:false
		adminArgs = path:false, route:false
		
		userRoute = Router.map('/user/:ID').leaving (path, route)-> userArgs = {path,route}
		adminRoute = Router.map('/admin/:ID').leaving (path, route)-> adminArgs = {path,route}
		Router.listen()

		expect(userArgs.path).to.equal(false)
		expect(userArgs.route).to.equal(false)
		expect(adminArgs.path).to.equal(false)
		expect(adminArgs.route).to.equal(false)
		
		setHash('/user/1/').then ()->
			expect(userArgs.path).to.equal(false)
			expect(userArgs.route).to.equal(false)
			expect(adminArgs.path).to.equal(false)
			expect(adminArgs.route).to.equal(false)
		
			setHash('admin/2').then ()->
				expect(userArgs.path).to.equal('admin/2')
				expect(userArgs.route).to.equal(adminRoute)
				expect(adminArgs.path).to.equal(false)
				expect(adminArgs.route).to.equal(false)
		
				setHash('user/3').then ()->
					expect(userArgs.path).to.equal('admin/2')
					expect(userArgs.route).to.equal(adminRoute)
					expect(adminArgs.path).to.equal('user/3')
					expect(adminArgs.route).to.equal(userRoute)
		
					setHash('user/4').then ()->
						expect(userArgs.path).to.equal('user/4')
						expect(userArgs.route).to.equal(userRoute)
						expect(adminArgs.path).to.equal('user/3')
						expect(adminArgs.route).to.equal(userRoute)


	test "Router.back/forward() can be used to navigate through history", ()->
		invokeCount = {}
		incCount = (prop)-> invokeCount[prop] ?= 0; invokeCount[prop]++
		
		Router = Routing.Router()
		Router.map('AAA').to ()-> incCount('AAA')
		Router.map('BBB').to ()-> incCount('BBB')
		Router.map('CCC').to ()-> incCount('CCC')
		Router.map('DDD').to ()-> incCount('DDD')
		Router.listen()

		Promise.delay().then ()->
			Router.fallback ()-> incCount('fallback')
			expect(invokeCount.AAA).to.equal undefined
			expect(invokeCount.BBB).to.equal undefined
			expect(invokeCount.CCC).to.equal undefined
			expect(invokeCount.DDD).to.equal undefined
			expect(invokeCount.fallback).to.equal undefined

			Router.forward().then ()->
				expect(invokeCount.fallback).to.equal undefined

				Router.back().then ()->
					expect(invokeCount.fallback).to.equal undefined
					Promise.resolve()
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

							Router.back().then ()->
								expect(invokeCount.CCC).to.equal 2
								
								Router.back().then ()->
									expect(invokeCount.BBB).to.equal 2

									Router.forward().then ()-> Router.forward().then ()->
										expect(invokeCount.AAA).to.equal 1
										expect(invokeCount.BBB).to.equal 2
										expect(invokeCount.CCC).to.equal 3
										expect(invokeCount.DDD).to.equal 2

										Router.back().then ()-> Router.back().then ()->
											expect(invokeCount.AAA).to.equal 1
											expect(invokeCount.BBB).to.equal 3
											expect(invokeCount.CCC).to.equal 4
											expect(invokeCount.DDD).to.equal 2

											Router.back().then ()->
												expect(invokeCount.AAA).to.equal 2
												expect(invokeCount.BBB).to.equal 3
												expect(invokeCount.CCC).to.equal 4
												expect(invokeCount.DDD).to.equal 2
												expect(getHash()).to.equal 'AAA'

												Router.back().then ()->
													expect(invokeCount.AAA).to.equal 2
													expect(invokeCount.BBB).to.equal 3
													expect(invokeCount.CCC).to.equal 4
													expect(invokeCount.DDD).to.equal 2
													expect(getHash()).to.equal 'AAA'


	test "Router.refresh() can be used to create refresh the current route", ()->
		invokeCount = 
			abc: {before:0, reg:0, after:0}
			def: {before:0, reg:0, after:0}
		
		Router = Routing.Router()
		Router.map('abc')
			.entering ()-> invokeCount.abc.before++
			.to ()-> invokeCount.abc.reg++
			.leaving ()-> invokeCount.abc.after++
		
		Router.map('def')
			.entering ()-> invokeCount.def.before++
			.to ()-> invokeCount.def.reg++
			.leaving ()-> invokeCount.def.after++

		Router.listen()
		setHash('abc').then ()->
			expect(invokeCount.abc.before).to.equal 1
			expect(invokeCount.abc.reg).to.equal 1
			expect(invokeCount.abc.after).to.equal 0
			expect(invokeCount.def.before).to.equal 0
			expect(invokeCount.def.reg).to.equal 0
			expect(invokeCount.def.after).to.equal 0

			setHash('def').then ()->
				expect(invokeCount.abc.before).to.equal 1
				expect(invokeCount.abc.reg).to.equal 1
				expect(invokeCount.abc.after).to.equal 1
				expect(invokeCount.def.before).to.equal 1
				expect(invokeCount.def.reg).to.equal 1
				expect(invokeCount.def.after).to.equal 0

				Router.refresh().then ()->
					expect(invokeCount.abc.before).to.equal 1
					expect(invokeCount.abc.reg).to.equal 1
					expect(invokeCount.abc.after).to.equal 1
					expect(invokeCount.def.before).to.equal 2
					expect(invokeCount.def.reg).to.equal 2
					expect(invokeCount.def.after).to.equal 1

					Router.refresh().then ()->
						expect(invokeCount.abc.before).to.equal 1
						expect(invokeCount.abc.reg).to.equal 1
						expect(invokeCount.abc.after).to.equal 1
						expect(invokeCount.def.before).to.equal 3
						expect(invokeCount.def.reg).to.equal 3
						expect(invokeCount.def.after).to.equal 2


	test "Route.filters() can accept a param:filterFn object map which will be invoked for each param on route matching and will use the return value to decide the match result", ()->
		Promise.delay().then ()->
			window.invokeCount = route:0, fallback:0
			params = {}
			Router = Routing.Router()
			
			Router.fallback ()-> invokeCount.fallback++
			Router.map('/api/:version/:function/:username')
				.to ()-> invokeCount.route++; params = @params
				.filters 
					version: (version)-> version.length is 1 and /\d/.test(version)
					username: (username)-> username and /^[^\d]+$/.test(username)

			Router.listen()
			Promise.delay().then ()->
				expect(invokeCount.route).to.equal 0
				expect(invokeCount.fallback).to.equal 1
				
				setHash('/api/3/anything/daniel').then ()->
					expect(invokeCount.route).to.equal 1
					expect(invokeCount.fallback).to.equal 1
					expect(params).to.eql {version:'3', function:'anything', username:'daniel'}
				
					setHash('/api/3/9/daniel').then ()->
						expect(invokeCount.route).to.equal 2
						expect(invokeCount.fallback).to.equal 1
						expect(params).to.eql {version:'3', function:'9', username:'daniel'}
				
						setHash('/api/13/anything/daniel').then ()->
							expect(invokeCount.route).to.equal 2
							expect(invokeCount.fallback).to.equal 2
				
							setHash('/api/5/anything/dani3el').then ()->
								expect(invokeCount.route).to.equal 2
								expect(invokeCount.fallback).to.equal 3
				
								setHash('/api/5//kevin').then ()->
									expect(invokeCount.route).to.equal 3
									expect(invokeCount.fallback).to.equal 3
									expect(params).to.eql {version:'5', function:'', username:'kevin'}


	test "Routing.Router() accpets a number-type argument which will be used as the route loading timeout (ms)", ()->
		consoleError = console.error
		console.error = chai.spy()
		invokeCount = abc:0, def:0, ghi:0
		delay = abc:0, def:0
		Router = Routing.Router(20)
		Router.map('abc').to ()-> invokeCount.abc++; Promise.delay(delay.abc)
		Router.map('def').to ()-> invokeCount.def++; Promise.delay(delay.def)
		Router.map('ghi').to ()-> invokeCount.ghi++;
		Router.listen()

		setHash('abc', 5).then ()->
			expect(invokeCount.abc).to.equal 1
			expect(invokeCount.def).to.equal 0
			expect(invokeCount.ghi).to.equal 0
			expect(console.error).to.have.been.called.exactly 0
			expect(Router.current.path).to.equal 'abc'
			expect(getHash()).to.equal 'abc'

			delay.abc = delay.def = 10
			setHash('def', 15).then ()->
				expect(invokeCount.abc).to.equal 1
				expect(invokeCount.def).to.equal 1
				expect(invokeCount.ghi).to.equal 0
				expect(console.error).to.have.been.called.exactly 0
				expect(Router.current.path).to.equal 'def'
				expect(getHash()).to.equal 'def'

				delay.abc = 20
				setHash('abc', 25).then ()->
					expect(invokeCount.abc).to.equal 2
					expect(invokeCount.def).to.equal 2
					expect(invokeCount.ghi).to.equal 0
					expect(console.error).to.have.been.called.exactly 1
					expect(Router.current.path).to.equal 'def'
					expect(getHash()).to.equal 'def'

					delay.def = 20
					setHash('ghi', 10).then ()->
						expect(invokeCount.abc).to.equal 2
						expect(invokeCount.def).to.equal 2
						expect(invokeCount.ghi).to.equal 1
						expect(console.error).to.have.been.called.exactly 1
						expect(Router.current.path).to.equal 'ghi'
						expect(getHash()).to.equal 'ghi'

						setHash('def', 30).then ()->
							expect(invokeCount.abc).to.equal 2
							expect(invokeCount.def).to.equal 3
							expect(invokeCount.ghi).to.equal 2
							expect(console.error).to.have.been.called.exactly 2
							expect(Router.current.path).to.equal 'ghi'
							expect(getHash()).to.equal 'ghi'


	test "Router.kill() will destroy the router instance and will remove all handlers", ()->
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

		defineRoutes(RouterA, invokeCountA)
		defineRoutes(RouterB, invokeCountB)
		
		invokeChanges().then ()->
			expect(invokeCountA.AAA).to.equal 1
			expect(invokeCountA.BBB).to.equal 1
			expect(invokeCountA.CCC).to.equal 1
			expect(invokeCountB.AAA).to.equal 1
			expect(invokeCountB.BBB).to.equal 1
			expect(invokeCountB.CCC).to.equal 1
			
			invokeChanges().then ()->
				expect(invokeCountA.AAA).to.equal 2
				expect(invokeCountA.BBB).to.equal 2
				expect(invokeCountA.CCC).to.equal 2
				expect(invokeCountB.AAA).to.equal 2
				expect(invokeCountB.BBB).to.equal 2
				expect(invokeCountB.CCC).to.equal 2
				
				RouterA.kill()
				invokeChanges().then ()->
					expect(invokeCountA.AAA).to.equal 2
					expect(invokeCountA.BBB).to.equal 2
					expect(invokeCountA.CCC).to.equal 2
					expect(invokeCountB.AAA).to.equal 3
					expect(invokeCountB.BBB).to.equal 3
					expect(invokeCountB.CCC).to.equal 3


	test "Routing.killAll() will destroy all existing router instances and will remove all handlers", ()->
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

		defineRoutes(RouterA, invokeCountA)
		defineRoutes(RouterB, invokeCountB)
		
		invokeChanges().then ()->
			expect(invokeCountA.AAA).to.equal 1
			expect(invokeCountA.BBB).to.equal 1
			expect(invokeCountA.CCC).to.equal 1
			expect(invokeCountB.AAA).to.equal 1
			expect(invokeCountB.BBB).to.equal 1
			expect(invokeCountB.CCC).to.equal 1
			
			invokeChanges().then ()->
				expect(invokeCountA.AAA).to.equal 2
				expect(invokeCountA.BBB).to.equal 2
				expect(invokeCountA.CCC).to.equal 2
				expect(invokeCountB.AAA).to.equal 2
				expect(invokeCountB.BBB).to.equal 2
				expect(invokeCountB.CCC).to.equal 2
				
				Routing.killAll()
				invokeChanges().then ()->
					expect(invokeCountA.AAA).to.equal 2
					expect(invokeCountA.BBB).to.equal 2
					expect(invokeCountA.CCC).to.equal 2
					expect(invokeCountB.AAA).to.equal 2
					expect(invokeCountB.BBB).to.equal 2
					expect(invokeCountB.CCC).to.equal 2












