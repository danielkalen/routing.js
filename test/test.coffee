window.Promise = import 'bluebird'
chai = import 'chai'
sinon = import 'sinon'
chai.config.truncateThreshold = 1e3
mocha.setup('tdd')
mocha.slow(700)
mocha.bail() unless window.__karma__
{expect} = chai
Promise.config longStackTraces:false, warnings:false
runAfterDelay = setTimeout


getHash = (hash=window.location.hash)->
	hash.replace /^#?\/?/, ''

setHash = (targetHash, delay=4, extra={})-> new Promise (resolve)->
	return resolve() if getHash() is getHash(targetHash)
	targetHash = getHash(targetHash)
	{clock, router} = extra
	
	handler = ()->
		window.removeEventListener('hashchange', handler)
		Promise.resolve()
			.then ()-> if router then (router._pendingRoute or router._P)
			.catch ()-> ;
			.finally ()-> if delay then runAfterDelay(resolve, delay) else resolve()
		if clock then clock.tick(delay)
	
	window.addEventListener('hashchange', handler)
	window.location.hash = targetHash





suite "Routing.JS", ()->
	teardown ()-> window.location.hash = ''; Routing.killAll()

	test "Routing.Router() will return a new router instance", ()->
		routerA = Routing.Router()
		routerB = Routing.Router()
		expect(routerA).not.to.equal(routerB)
		expect(routerA.ID).to.equal(1)
		expect(routerB.ID).to.equal(2)


	test "router.map() should accept a path and return a cachable Route instance", ()->
		router = Routing.Router()
		routeA = router.map('/abc')
		routeB = router.map('/abc')
		expect(routeA).to.equal(routeB)


	test "a route can be specified with or without forward/backward slashes", ()->
		router = Routing.Router()
		routeA = router.map('/abc/')
		routeB = router.map('/abc')
		routeC = router.map('abc')
		routeD = router.map('abc/')
		
		expect(routeA).to.equal(routeB)
		expect(routeB).to.equal(routeC)
		expect(routeC).to.equal(routeD)


	test "a route can be mapped to invoke a specific function on hash change", ()->
		router = Routing.Router()
		invokeCount = {'/':0, '/test':0, '/another':0}
		
		Promise.resolve()
			.then ()->
				router
					.map('/').to ()-> invokeCount['/']++
					.map('/test').to ()-> invokeCount['/test']++
					.map('/another').to ()-> invokeCount['/another']++
					.listen()

			.delay()
			.then ()->
				expect(invokeCount['/']).to.equal 1
				expect(invokeCount['/test']).to.equal 0
				expect(invokeCount['/another']).to.equal 0
				setHash('/test')
		
			.then ()->
				expect(invokeCount['/']).to.equal 1
				expect(invokeCount['/test']).to.equal 1
				expect(invokeCount['/another']).to.equal 0
				setHash('/another')

			.then ()->
				expect(invokeCount['/']).to.equal 1
				expect(invokeCount['/test']).to.equal 1
				expect(invokeCount['/another']).to.equal 1
				setHash('test')

			.then ()->
				expect(invokeCount['/']).to.equal 1
				expect(invokeCount['/test']).to.equal 2
				expect(invokeCount['/another']).to.equal 1


	test "route functions will be invoked within a dedicated context", ()->
		router = Routing.Router()
		invokeCount = 0
		prevContext = null

		Promise.resolve()
			.then ()->
				router.map('/another')
				router.map('/test/path').to ()->
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
		
				router.listen()
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


	suite "params", ()->
		test "a route can have dynamic segments which will be available with resolved values in this.params", ()->
			router = Routing.Router()
			invokeCount = 0
			context = null

			Promise.resolve()
				.then ()->
					router.map('/user/:ID/:page').to ()-> invokeCount++; context = @
					router.map('/admin/:ID/:name?/:page?').to ()-> invokeCount++; context = @
					router.listen()

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
			router = Routing.Router()
			invokeCount = 0
			context = null

			Promise.resolve()
				.then ()->
					router.map('/:page').to ()-> invokeCount++; context = @
					router.listen()

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


	suite "query", ()->
		test "parsed query params are accessible via this.query in route actions", ()->
			count = {}
			query = {}
			router = Routing.Router()
			register = (path)->
				count[path] = 0; query[path] = null;
				router.map(path).to ()-> count[path]++; query[path] = @query

			Promise.resolve()
				.then ()->
					register '/'
					register '/abc'
					register '/def'
					router.listen()

				.delay()
				.then ()->
					expect(count).to.eql '/':1, '/abc':0, '/def':0
					expect(query).to.eql '/':{}, '/abc':null, '/def':null
					setHash('/abc?item=23&name=product')
				
				.then ()->
					expect(count).to.eql '/':1, '/abc':1, '/def':0
					expect(query).to.eql '/':{}, '/abc':{item:'23',name:'product'}, '/def':null
					setHash('?item=45&key=value')
				
				.then ()->
					expect(count).to.eql '/':2, '/abc':1, '/def':0
					expect(query).to.eql '/':{item:'45', key:'value'}, '/abc':{item:'23',name:'product'}, '/def':null


		test "the route's action will trigger every time the query string changes", ()->
			count = {}
			query = {}
			router = Routing.Router()
			register = (path)->
				count[path] = 0; query[path] = null;
				router.map(path).to ()-> count[path]++; query[path] = @query

			Promise.resolve()
				.then ()->
					register '/'
					register '/abc'
					register '/def'
					router.listen()

				.delay()
				.then ()->
					expect(count).to.eql '/':1, '/abc':0, '/def':0
					expect(query).to.eql '/':{}, '/abc':null, '/def':null
					setHash('/abc?item=23&name=product')
				
				.then ()->
					expect(count).to.eql '/':1, '/abc':1, '/def':0
					expect(query).to.eql '/':{}, '/abc':{item:'23',name:'product'}, '/def':null
					setHash('/abc?item=45&key=value')
				
				.then ()->
					expect(count).to.eql '/':1, '/abc':2, '/def':0
					expect(query).to.eql '/':{}, '/abc':{item:'45', key:'value'}, '/def':null
					setHash('/def?')
				
				.then ()->
					expect(count).to.eql '/':1, '/abc':2, '/def':1
					expect(query).to.eql '/':{}, '/abc':{item:'45', key:'value'}, '/def':{}
					setHash('/def?size=large&name=king&size=small')
				
				.then ()->
					expect(count).to.eql '/':1, '/abc':2, '/def':2
					expect(query).to.eql '/':{}, '/abc':{item:'45', key:'value'}, '/def':{size:'small',name:'king'}


		test "will work with path params", ()->
			count = {}
			query = {}
			params = {}
			router = Routing.Router()
			register = (path)->
				count[path] = 0; query[path] = null; params[path] = null;
				router.map(path).to ()-> count[path]++; query[path] = @query; params[path] = @params

			Promise.resolve()
				.then ()->
					register '/abc'
					register '/abc/:param'
					register '/def/:param?'
					router.listen()

				.delay()
				.then ()->
					expect(count).to.eql '/abc':0, '/abc/:param':0, '/def/:param?':0
					expect(query).to.eql '/abc':null, '/abc/:param':null, '/def/:param?':null
					expect(params).to.eql '/abc':null, '/abc/:param':null, '/def/:param?':null
					setHash('/abc?a=1&b=2&c=3')
				
				.then ()->
					expect(count).to.eql '/abc':1, '/abc/:param':0, '/def/:param?':0
					expect(query).to.eql '/abc':{a:'1',b:'2',c:'3'}, '/abc/:param':null, '/def/:param?':null
					expect(params).to.eql '/abc':{}, '/abc/:param':null, '/def/:param?':null
					setHash('/abc/blabla')
				
				.then ()->
					expect(count).to.eql '/abc':1, '/abc/:param':1, '/def/:param?':0
					expect(query).to.eql '/abc':{a:'1',b:'2',c:'3'}, '/abc/:param':{}, '/def/:param?':null
					expect(params).to.eql '/abc':{}, '/abc/:param':{param:'blabla'}, '/def/:param?':null
					setHash('/abc/blabla?d=4&e=5')
				
				.then ()->
					expect(count).to.eql '/abc':1, '/abc/:param':2, '/def/:param?':0
					expect(query).to.eql '/abc':{a:'1',b:'2',c:'3'}, '/abc/:param':{d:'4',e:'5'}, '/def/:param?':null
					expect(params).to.eql '/abc':{}, '/abc/:param':{param:'blabla'}, '/def/:param?':null
					setHash('/def?d=4&e=5')
				
				.then ()->
					expect(count).to.eql '/abc':1, '/abc/:param':2, '/def/:param?':1
					expect(query).to.eql '/abc':{a:'1',b:'2',c:'3'}, '/abc/:param':{d:'4',e:'5'}, '/def/:param?':{d:'4',e:'5'}
					expect(params).to.eql '/abc':{}, '/abc/:param':{param:'blabla'}, '/def/:param?':{param:''}
					setHash('/def/orem?d=4&e=5')
				
				.then ()->
					expect(count).to.eql '/abc':1, '/abc/:param':2, '/def/:param?':2
					expect(query).to.eql '/abc':{a:'1',b:'2',c:'3'}, '/abc/:param':{d:'4',e:'5'}, '/def/:param?':{d:'4',e:'5'}
					expect(params).to.eql '/abc':{}, '/abc/:param':{param:'blabla'}, '/def/:param?':{param:'orem'}
					setHash('/def/orem?f=6&g=7')
				
				.then ()->
					expect(count).to.eql '/abc':1, '/abc/:param':2, '/def/:param?':3
					expect(query).to.eql '/abc':{a:'1',b:'2',c:'3'}, '/abc/:param':{d:'4',e:'5'}, '/def/:param?':{f:'6',g:'7'}
					expect(params).to.eql '/abc':{}, '/abc/:param':{param:'blabla'}, '/def/:param?':{param:'orem'}


		test "will work with base path", ()->
			count = {}
			query = {}
			params = {}
			router = Routing.Router().base('theBase/2/')
			register = (path)->
				count[path] = 0; query[path] = null; params[path] = null;
				router.map(path).to ()-> count[path]++; query[path] = @query; params[path] = @params

			Promise.resolve()
				.then ()->
					register '/abc'
					register '/abc/:param'
					register '/def/:param?'
					router.listen()

				.delay()
				.then ()->
					expect(count).to.eql '/abc':0, '/abc/:param':0, '/def/:param?':0
					expect(query).to.eql '/abc':null, '/abc/:param':null, '/def/:param?':null
					expect(params).to.eql '/abc':null, '/abc/:param':null, '/def/:param?':null
					setHash('/theBase/2/abc?a=1&b=2&c=3')
				
				.then ()->
					expect(count).to.eql '/abc':1, '/abc/:param':0, '/def/:param?':0
					expect(query).to.eql '/abc':{a:'1',b:'2',c:'3'}, '/abc/:param':null, '/def/:param?':null
					expect(params).to.eql '/abc':{}, '/abc/:param':null, '/def/:param?':null
					setHash('/theBase/2/abc/blabla')
				
				.then ()->
					expect(count).to.eql '/abc':1, '/abc/:param':1, '/def/:param?':0
					expect(query).to.eql '/abc':{a:'1',b:'2',c:'3'}, '/abc/:param':{}, '/def/:param?':null
					expect(params).to.eql '/abc':{}, '/abc/:param':{param:'blabla'}, '/def/:param?':null
					setHash('/theBase/2/abc/blabla?d=4&e=5')
				
				.then ()->
					expect(count).to.eql '/abc':1, '/abc/:param':2, '/def/:param?':0
					expect(query).to.eql '/abc':{a:'1',b:'2',c:'3'}, '/abc/:param':{d:'4',e:'5'}, '/def/:param?':null
					expect(params).to.eql '/abc':{}, '/abc/:param':{param:'blabla'}, '/def/:param?':null
					setHash('/theBase/2/def?d=4&e=5')
				
				.then ()->
					expect(count).to.eql '/abc':1, '/abc/:param':2, '/def/:param?':1
					expect(query).to.eql '/abc':{a:'1',b:'2',c:'3'}, '/abc/:param':{d:'4',e:'5'}, '/def/:param?':{d:'4',e:'5'}
					expect(params).to.eql '/abc':{}, '/abc/:param':{param:'blabla'}, '/def/:param?':{param:''}
					setHash('/theBase/2/def/orem?d=4&e=5')
				
				.then ()->
					expect(count).to.eql '/abc':1, '/abc/:param':2, '/def/:param?':2
					expect(query).to.eql '/abc':{a:'1',b:'2',c:'3'}, '/abc/:param':{d:'4',e:'5'}, '/def/:param?':{d:'4',e:'5'}
					expect(params).to.eql '/abc':{}, '/abc/:param':{param:'blabla'}, '/def/:param?':{param:'orem'}
					setHash('/theBase/2/def/orem?f=6&g=7')
				
				.then ()->
					expect(count).to.eql '/abc':1, '/abc/:param':2, '/def/:param?':3
					expect(query).to.eql '/abc':{a:'1',b:'2',c:'3'}, '/abc/:param':{d:'4',e:'5'}, '/def/:param?':{f:'6',g:'7'}
					expect(params).to.eql '/abc':{}, '/abc/:param':{param:'blabla'}, '/def/:param?':{param:'orem'}


		test "will work with passive routes", ()->
			count = {}
			query = {}
			params = {}
			router = Routing.Router()
			register = (path,passive)->
				target = if passive then "#{path}-passive" else path
				route = if passive then router.map(path).passive() else router.map(path)
				count[target] = 0; query[target] = null; params[target] = null;
				route.to ()-> count[target]++; query[target] = @query; params[target] = @params

			Promise.resolve()
				.then ()->
					register '/abc',true
					register '/def/:param?'
					register '/def/:param?',true
					router.listen()

				.delay()
				.then ()->
					expect(count).to.eql '/abc-passive':0, '/def/:param?':0, '/def/:param?-passive':0
					expect(query).to.eql '/abc-passive':null, '/def/:param?':null, '/def/:param?-passive':null
					expect(params).to.eql '/abc-passive':null, '/def/:param?':null, '/def/:param?-passive':null
					setHash('/abc?a=1')
				
				.then ()->
					expect(count).to.eql '/abc-passive':1, '/def/:param?':0, '/def/:param?-passive':0
					expect(query).to.eql '/abc-passive':{a:'1'}, '/def/:param?':null, '/def/:param?-passive':null
					expect(params).to.eql '/abc-passive':{}, '/def/:param?':null, '/def/:param?-passive':null
					setHash('/abc?a=2')
				
				.then ()->
					expect(count).to.eql '/abc-passive':2, '/def/:param?':0, '/def/:param?-passive':0
					expect(query).to.eql '/abc-passive':{a:'2'}, '/def/:param?':null, '/def/:param?-passive':null
					expect(params).to.eql '/abc-passive':{}, '/def/:param?':null, '/def/:param?-passive':null
					setHash('/def/kale?b=2')
				
				.then ()->
					expect(count).to.eql '/abc-passive':2, '/def/:param?':1, '/def/:param?-passive':1
					expect(query).to.eql '/abc-passive':{a:'2'}, '/def/:param?':{b:'2'}, '/def/:param?-passive':{b:'2'}
					expect(params).to.eql '/abc-passive':{}, '/def/:param?':{param:'kale'}, '/def/:param?-passive':{param:'kale'}
					setHash('/def/kale?b=2&c=3')
				
				.then ()->
					expect(count).to.eql '/abc-passive':2, '/def/:param?':2, '/def/:param?-passive':2
					expect(query).to.eql '/abc-passive':{a:'2'}, '/def/:param?':{b:'2',c:'3'}, '/def/:param?-passive':{b:'2',c:'3'}
					expect(params).to.eql '/abc-passive':{}, '/def/:param?':{param:'kale'}, '/def/:param?-passive':{param:'kale'}



	suite "actions", ()->
		test "a route can be mapped to an entering function which will be invoked when entering the route (before regular action)", ()->
			router = Routing.Router()
			invokeCount = before:0, reg:0

			Promise.resolve()
				.then ()->
					router.map('/def456')
					router.map('/abc123')
						.entering ()-> invokeCount.before++; expect(invokeCount.before - invokeCount.reg).to.equal(1)
						.to ()-> invokeCount.reg++

					router.listen()

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
			router = Routing.Router()
			invokeCount = after:0, reg:0

			Promise.resolve()
				.then ()->
					router.map('/def456')
					router.map('/abc123')
						.to ()-> invokeCount.reg++
						.leaving ()-> invokeCount.after++

					router.listen()

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
			router = Routing.Router()
			invokeCount = before:0, after:0, abc123:0, def456:0
			delays = before:null, abc123:null, after:null
			initDelays = ()->
				delays.before = new Promise ()->
				delays.abc123 = new Promise ()->
				delays.after = new Promise ()->
				return null

			Promise.resolve()
				.then ()->
					router.map('/abc123')
						.entering ()-> invokeCount.before++; delays.before
						.to ()-> invokeCount.abc123++; delays.abc123
			
					router.map('/def456')
						.to ()-> invokeCount.def456++;
						.leaving ()-> invokeCount.after++; delays.after

					router.listen()
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


		test "router.beforeAll/afterAll() can take a function which will be executed before/after all route changes", ()->
			invokeCount = before:0, after:0, beforeB:0
			delays = before:null, after:null, afterC:null
			router = Routing.Router()

			Promise.resolve()
				.then ()->
					router
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
					router
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
			router = Routing.Router()
			args = path:false, route:false
			
			userRoute = router.map('/user/:ID').to (path, route)-> args = {path,route}
			adminRoute = router.map('/admin/:ID').to (path, route)-> args = {path,route}
			Promise.resolve()
				.then ()-> router.listen()
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
			router = Routing.Router()
			userArgs = path:false, route:false
			adminArgs = path:false, route:false
			
			userRoute = router.map('/user/:ID').leaving (path, route)-> userArgs = {path,route}
			adminRoute = router.map('/admin/:ID').leaving (path, route)-> adminArgs = {path,route}
			Promise.resolve()
				.then ()-> router.listen()
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


		test "routes can have multiple actions", ()->
			router = Routing.Router()
			count = a:0, b:0, c:0, d:0
			
			Promise.resolve()
				.then ()->
					router
						.map('/abc')
						.map('/def')
							.to ()-> count.a++
							.to ()-> count.b++
							.entering ()-> count.c++
							.to ()-> count.d++
						.listen('/abc')

				.then ()->
					expect(count).to.eql a:0, b:0, c:0, d:0
					setHash('def')

				.then ()->
					expect(count).to.eql a:1, b:1, c:1, d:1
					setHash('/def')

				.then ()->
					expect(count).to.eql a:1, b:1, c:1, d:1
					setHash('/abc')

				.then ()->
					expect(count).to.eql a:1, b:1, c:1, d:1
					router.back()

				.then ()->
					expect(count).to.eql a:2, b:2, c:2, d:2




	suite "history / naviagation", ()->
		test "router.back/forward() can be used to navigate through history", ()->
			invokeCount = {}
			incCount = (prop)-> invokeCount[prop] ?= 0; invokeCount[prop]++
			
			router = Routing.Router()
			Promise.resolve()
				.then ()->
					router.map('AAA').to ()-> incCount('AAA')
					router.map('BBB').to ()-> incCount('BBB')
					router.map('CCC').to ()-> incCount('CCC')
					router.map('DDD').to ()-> incCount('DDD')
					router.listen()

				.delay()
				.then ()->
					router.fallback ()-> incCount('fallback')
					expect(invokeCount.AAA).to.equal undefined
					expect(invokeCount.BBB).to.equal undefined
					expect(invokeCount.CCC).to.equal undefined
					expect(invokeCount.DDD).to.equal undefined
					expect(invokeCount.fallback).to.equal undefined
					router.forward()

				.then ()->
					expect(invokeCount.fallback).to.equal undefined
					router.back()

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
					router.back()

				.then ()->
					expect(invokeCount.CCC).to.equal 2
					router.back()
						
				.then ()->
					expect(invokeCount.BBB).to.equal 2
					router.forward().then ()-> router.forward()

				.then ()->
					expect(invokeCount.AAA).to.equal 1
					expect(invokeCount.BBB).to.equal 2
					expect(invokeCount.CCC).to.equal 3
					expect(invokeCount.DDD).to.equal 2
					router.back().then ()-> router.back()

				.then ()->
					expect(invokeCount.AAA).to.equal 1
					expect(invokeCount.BBB).to.equal 3
					expect(invokeCount.CCC).to.equal 4
					expect(invokeCount.DDD).to.equal 2
					router.back()

				.then ()->
					expect(invokeCount.AAA).to.equal 2
					expect(invokeCount.BBB).to.equal 3
					expect(invokeCount.CCC).to.equal 4
					expect(invokeCount.DDD).to.equal 2
					expect(getHash()).to.equal 'AAA'
					router.back()

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
			
			router = Routing.Router()
			Promise.resolve()
				.then ()->
					router
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
					router.refresh()

				.then ()->
					expect(invokeCount.abc.before).to.equal 1
					expect(invokeCount.abc.reg).to.equal 1
					expect(invokeCount.abc.after).to.equal 1
					expect(invokeCount.def.before).to.equal 2
					expect(invokeCount.def.reg).to.equal 2
					expect(invokeCount.def.after).to.equal 1
					router.refresh()

				.then ()->
					expect(invokeCount.abc.before).to.equal 1
					expect(invokeCount.abc.reg).to.equal 1
					expect(invokeCount.abc.after).to.equal 1
					expect(invokeCount.def.before).to.equal 3
					expect(invokeCount.def.reg).to.equal 3
					expect(invokeCount.def.after).to.equal 2


		test "a default route can be specified in router.listen() which will be defaulted to if there isn't a matching route for the current hash", ()->
			invokeCount = abc:0, def:0
			router = null
			createrouter = (targetHash='')->
				setHash(targetHash)
				invokeCount.abc = invokeCount.def = 0
				router?.kill()
				router = Routing.Router()
				router.map('/abc').to ()-> invokeCount.abc++
				router.map('/def').to ()-> invokeCount.def++
				return router

			Promise.resolve()
				.then ()-> createrouter().listen()
				.delay()
				.then ()->
					expect(getHash()).to.equal ''
					expect(invokeCount.abc).to.equal 0
					expect(invokeCount.def).to.equal 0
				
				.then ()-> createrouter('def').listen('abc')
				.delay()
				.then ()->
					expect(getHash()).to.equal 'def'
					expect(invokeCount.abc).to.equal 0
					expect(invokeCount.def).to.equal 1
				
				.then ()-> createrouter().listen('/abc')
				.delay()
				.then ()->
					expect(getHash()).to.equal 'abc'
					expect(invokeCount.abc).to.equal 1
					expect(invokeCount.def).to.equal 0
				
				.then ()-> createrouter().listen('def')
				.delay()
				.then ()->
					expect(getHash()).to.equal 'def'
					expect(invokeCount.abc).to.equal 0
					expect(invokeCount.def).to.equal 1
				
				.then ()-> createrouter().listen('/akjsdf')
				.delay()
				.then ()->
					expect(getHash()).to.equal ''
					expect(invokeCount.abc).to.equal 0
					expect(invokeCount.def).to.equal 0


		test "if a falsey value is passed to router.listen() the initial route match will be skipped", ()->
			window.invokeCount = 0
			router = null
			createrouter = (initialHash)->
				router?.kill()
				setHash(initialHash)
				router = Routing.Router()
				router.map('/abc').to ()-> invokeCount++
				router.fallback ()-> invokeCount++
				return router
			
			Promise.resolve()
				.then ()-> createrouter('c')
				.delay()
				.then ()-> router.listen()
				.delay()
				.then ()-> expect(invokeCount).to.equal 1

				.then ()-> createrouter('abc')
				.delay()
				.then ()-> router.listen()
				.delay()
				.then ()-> expect(invokeCount).to.equal 2

				.then ()-> createrouter('def')
				.delay()
				.then ()-> router.listen()
				.delay()
				.then ()-> expect(invokeCount).to.equal 3

				.then ()-> createrouter('')
				.delay()
				.then ()-> router.listen(false)
				.delay()
				.then ()-> expect(invokeCount).to.equal 3

				.then ()-> createrouter('abc')
				.delay()
				.then ()-> router.listen('')
				.delay()
				.then ()-> expect(invokeCount).to.equal 3


		test "a fallback route (e.g. 404) can be specified to be defaulted to when the specified hash has no matching routes", ()->
			invokeCount = abc:0, fallback:0
			router = Routing.Router()

			Promise.resolve()
				.then ()->
					router.map('abc').to ()-> invokeCount.abc++
					router.fallback ()-> invokeCount.fallback++
					router.listen()
				
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
					router.fallback ()-> setHash('abc')
					setHash('aksjdfh')

				.then ()->				
					expect(getHash()).to.equal 'abc'


		test "a failed route transition will cause the router to go to the fallback route if exists", ()->
			invokeCount = 0
			sinon.stub(console, 'error')
			thrown = false;
			router = Routing.Router()

			Promise.delay()
				.then ()-> 
					router.map('abc').to ()-> Promise.delay().then ()-> thrown=true;throw new Error 'rejected'
					router.fallback ()-> invokeCount++
					router.listen()
				
				.delay()
				
				.then ()->
					expect(invokeCount).to.equal 1
					expect(getHash()).to.equal ''
					setHash('abc', null, {router})
			
				.then ()->
					expect(getHash()).to.equal 'abc'
					expect(thrown).to.equal true
					expect(invokeCount).to.equal 2
				
				.finally ()-> console.error.restore()


		test "a failed route transition will cause the router to go to the previous route if no fallback exists", ()->
			invokeCount = 0
			sinon.stub(console, 'error')
			router = Routing.Router()

			Promise.delay()
				.then ()-> 
					router.map('abc').to ()-> invokeCount++
					router.map('def').to ()-> Promise.delay().then ()-> throw new Error 'rejected'
					router.listen()
				
				.delay()
				.then ()->
					expect(invokeCount).to.equal 0
					expect(getHash()).to.equal ''
					setHash('abc', null, {router})
			
				.then ()->
					expect(getHash()).to.equal 'abc'
					expect(invokeCount).to.equal 1
					setHash('def', null, {router})
			
				.then ()->
					expect(getHash()).to.equal 'abc'
					expect(invokeCount).to.equal 2
				
				.finally ()-> console.error.restore()



	suite "filters", ()->
		test "route.filters() can accept a param:filterFn object map which will be invoked for each param on route matching and will use the return value to decide the match result", ()->
			invokeCount = route:0, fallback:0
			params = {}
			router = Routing.Router()
			
			router.fallback ()-> invokeCount.fallback++
			router
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

			Promise.resolve(router.listen()).delay()
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
					setHash('/api/5/ /kevin')

				.then ()->
					expect(invokeCount.route).to.equal 3
					expect(invokeCount.fallback).to.equal 3
					params.function = params.function.replace('%20',' ') if typeof params.function is 'string'
					expect(params).to.eql {version:'5', function:' ', username:'kevin'}



	suite "base paths", ()->
		test "a base path can be specified via Routing.base() and will only match routes that begin with the base", ()->
			base = 'theBase/goes/here'
			router = Routing.Router()
			invokeCount = abc:0, def:0, fallback:0, root:0
			
			Promise.resolve(setHash(base))
				.then ()->
					router
						.base(base)
						.fallback ()-> invokeCount.fallback++
						.map('/').to ()-> invokeCount.root++
						.map('abc').to ()-> invokeCount.abc++
						.map('def').to ()-> invokeCount.def++
						.listen()
				
				.delay()
				.then ()->
					expect(invokeCount).to.eql abc:0, def:0, fallback:0, root:1
					setHash('abc')

				.then ()->
					expect(invokeCount).to.eql abc:0, def:0, fallback:0, root:1
					expect(router.current.path).to.equal base
					expect(getHash()).to.equal 'abc'
					setHash("#{base}/abc")

				.then ()->
					expect(invokeCount).to.eql abc:1, def:0, fallback:0, root:1
					expect(router.current.path).to.equal "#{base}/abc"
					expect(getHash()).to.equal "#{base}/abc"
					setHash('def')

				.then ()->
					expect(invokeCount).to.eql abc:1, def:0, fallback:0, root:1
					expect(router.current.path).to.equal "#{base}/abc"
					expect(getHash()).to.equal "def"
					setHash("#{base}/def")

				.then ()->
					expect(invokeCount).to.eql abc:1, def:1, fallback:0, root:1
					expect(router.current.path).to.equal "#{base}/def"
					expect(getHash()).to.equal "#{base}/def"


		test "routers with base paths should have their .go() method auto-prefix paths with the base path if they do not have it", ()->
			base = 'theBase/goes/here'
			invokeCount = abc:0, def:0
			router = Routing.Router()
			
			Promise.resolve()
				.then ()->
					router
						.base(base)
						.map('abc').to ()-> invokeCount.abc++
						.map('def').to ()-> invokeCount.def++
						.listen()			

				.delay()
				.then ()->
					expect(invokeCount.abc).to.equal 0
					expect(invokeCount.def).to.equal 0
					router.go('abc')

				.then ()->
					expect(invokeCount.abc).to.equal 1
					expect(invokeCount.def).to.equal 0
					expect(router.current.path).to.equal "#{base}/abc"
					expect(getHash()).to.equal "#{base}/abc"
					router.go('/def')

				.then ()->
					expect(invokeCount.abc).to.equal 1
					expect(invokeCount.def).to.equal 1
					expect(router.current.path).to.equal "#{base}/def"
					expect(getHash()).to.equal "#{base}/def"
					router.go("#{base}/abc")

				.then ()->
					expect(invokeCount.abc).to.equal 2
					expect(invokeCount.def).to.equal 1
					expect(router.current.path).to.equal "#{base}/abc"
					expect(getHash()).to.equal "#{base}/abc"
					router.go("#{base}/def")

				.then ()->
					expect(invokeCount.abc).to.equal 2
					expect(invokeCount.def).to.equal 2
					expect(router.current.path).to.equal "#{base}/def"
					expect(getHash()).to.equal "#{base}/def"


		test "default paths will work with routers that have a base path specified", ()->
			base = 'theBase/goes/here'
			router = Routing.Router()
			invokeCount = abc:0, def:0, fallback:0
			
			Promise.resolve()
				.then ()->
					router
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
					router.kill()
					setHash('')
					router
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



	suite "redirects", ()->
		test "invoking this.redirect(target) from inside a route function will cause the router to redirect to the specified path", ()->
			invokeCount = abc:0, def:0, ghi:0
			router = Routing.Router()

			Promise.resolve()
				.then ()->
					router.map('abc').to ()-> invokeCount.abc++; @redirect('def')
					router.map('def').to ()-> invokeCount.def++
					router.map('ghi').to ()-> invokeCount.ghi++; @redirect('abc')
					router.listen()
				
				.delay()
				.then ()->
					expect(invokeCount).to.eql {abc:0, def:0, ghi:0}
					expect(router.current.path).to.equal null
					expect(getHash()).to.equal ''
					setHash('abc')
				
				.then ()->
					expect(invokeCount).to.eql {abc:1, def:1, ghi:0}
					expect(router.current.path).to.equal 'def'
					expect(getHash()).to.equal 'def'
					setHash('ghi')
				
				.then ()->
					expect(invokeCount).to.eql {abc:2, def:2, ghi:1}
					expect(router.current.path).to.equal 'def'
					expect(getHash()).to.equal 'def'
					setHash('ghi')


		test "redirects should replace the last entry in the router's history", ()->
			invokeCount = abc:0, def:0, ghi:0
			router = Routing.Router()
			router.history = router._history or router._h

			Promise.resolve()
				.then ()->
					router.map('abc').to ()-> invokeCount.abc++; @redirect('def')
					router.map('def').to ()-> invokeCount.def++
					router.map('ghi').to ()-> invokeCount.ghi++; @redirect('abc')
					router.map('jkl')
					router.listen()
				
				.delay()
				.then ()->
					expect(invokeCount).to.eql {abc:0, def:0, ghi:0}
					expect(getHash()).to.equal ''
					expect(router.current.path).to.equal null
					expect(router.history.length).to.equal 0
					setHash('abc')
				
				.then ()->
					expect(invokeCount).to.eql {abc:1, def:1, ghi:0}
					expect(getHash()).to.equal 'def'
					expect(router.current.path).to.equal 'def'
					expect(router.history.length).to.equal 0
					setHash('jkl')
				
				.then ()->
					expect(invokeCount).to.eql {abc:1, def:1, ghi:0}
					expect(getHash()).to.equal 'jkl'
					expect(router.current.path).to.equal 'jkl'
					expect(router.history.length).to.equal 1
					setHash('ghi')
				
				.then ()->
					expect(invokeCount).to.eql {abc:2, def:2, ghi:1}
					expect(getHash()).to.equal 'def'
					expect(router.current.path).to.equal 'def'
					expect(router.history.length).to.equal 2
					expect(router.history[1].path).to.equal 'jkl'



	suite "priority", ()->
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



	suite "passive routes", ()->
		test "routes can be marked as passive via route.passive() which will cause it not to update the window.location.hash or router history on transition", ()->
			router = Routing.Router()
			router.history = router._history or router._h
			window.invokeCount = aA:0, aB:0, pA:0, pB:0, pC:0, lA:0, lD:0, eD:0

			Promise.resolve()
				.then ()->
					router
						.map('def')
						.map('abc/first').to ()-> invokeCount.aA++
						.map('abc/second').to ()-> invokeCount.aB++
						.map('abc/:paramA').passive().to ()-> invokeCount.pA++
						.map('abc/:paramA').passive().leaving ()-> invokeCount.lA++
						.map('abc/:paramA/:paramC?').passive().to ()-> invokeCount.pB++
						.map('abc/:paramA/:paramC').passive().to ()-> invokeCount.pC++
						.map('ghi').passive()
							.entering ()-> invokeCount.eD++
							.leaving ()-> invokeCount.lD++
						.listen('def')

				.delay()
				.then ()->
					expect(invokeCount, 'def').to.eql aA:0, aB:0, pA:0, pB:0, pC:0, lA:0, lD:0, eD:0
					expect(router.history.length).to.equal 0
					expect(getHash()).to.equal 'def'
					setHash('abc/first')

				.then ()->
					expect(invokeCount, 'abc/first').to.eql aA:1, aB:0, pA:1, pB:1, pC:0, lA:0, lD:0, eD:0
					expect(router.history.length).to.equal 1
					expect(getHash()).to.equal 'abc/first'
					router.go('abc/second')

				.then ()->
					expect(invokeCount, 'abc/second').to.eql aA:1, aB:1, pA:2, pB:2, pC:0, lA:1, lD:0, eD:0
					expect(router.history.length).to.equal 2
					expect(getHash()).to.equal 'abc/second'
					router.go('abc/second/third')

				.then ()->
					expect(invokeCount, 'abc/second/third').to.eql aA:1, aB:1, pA:2, pB:3, pC:1, lA:2, lD:0, eD:0
					expect(router.history.length).to.equal 2
					expect(getHash()).to.equal 'abc/second'
					router.go('ghi')

				.then ()->
					expect(invokeCount, 'ghi').to.eql aA:1, aB:1, pA:2, pB:3, pC:1, lA:2, lD:0, eD:1
					expect(router.history.length).to.equal 2
					expect(getHash()).to.equal 'abc/second'
					router.go('abc/first')

				.then ()->
					expect(invokeCount, 'abc/first').to.eql aA:2, aB:1, pA:3, pB:4, pC:1, lA:2, lD:1, eD:1
					expect(router.history.length).to.equal 3
					expect(getHash()).to.equal 'abc/first'


		test "passive routes should have different instances from non-passive routes", ()->
			router = Routing.Router()
			expect(router.map('/abc'), "non-passive = non-passive").to.equal(router.map('/abc'))
			expect(router.map('/abc').passive(), "passive = passive").to.equal(router.map('/abc').passive())
			expect(router.map('/abc').passive(), "passive = passive.passive").to.equal(router.map('/abc').passive().passive())
			expect(router.map('/abc'), "non-passive != passive").not.to.equal(router.map('/abc').passive())
			invokeCount = entering:0, to:0, leaving:0, real:0
			
			Promise.resolve()
				.then ()->
					router
						.map('/abc').to ()-> ;
						.map('/def').passive()
							.entering ()-> invokeCount.entering++
							.to ()-> invokeCount.to++
							.leaving ()-> invokeCount.leaving++
						.map('/def')
							.to ()-> invokeCount.real++
					
					router.listen()

				.delay()
				.then ()->
					expect(invokeCount).to.eql entering:0, to:0, leaving:0, real:0
					setHash('abc')

				.then ()->
					expect(invokeCount).to.eql entering:0, to:0, leaving:0, real:0
					setHash('def')

				.then ()->
					expect(invokeCount).to.eql entering:1, to:1, leaving:0, real:1
					setHash('abc')

				.then ()->
					expect(invokeCount).to.eql entering:1, to:1, leaving:1, real:1
					router.go('def')

				.then ()->
					expect(invokeCount).to.eql entering:2, to:2, leaving:1, real:2



	suite "misc", ()->
		test "a route can be removed by calling its .remove() method or by invoking this.remove() from inside the route", ()->
			invokeCount = {abc:0, def:0}
			router = Routing.Router()
			abcRoute = router.map('abc').to ()-> invokeCount.abc++
			defRoute = router.map('def').to ()-> invokeCount.def++
			router.map('ghi')

			Promise.resolve()
				.then ()-> router.listen()
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
					defRoute.to ()-> @remove()
					setHash('ghi').then ()-> setHash('def')

				.then ()->
					expect(invokeCount.abc).to.equal 2
					expect(invokeCount.def).to.equal 3
					expect(getHash()).to.equal 'def'
					setHash('abc').then ()-> setHash('def')

				.then ()->
					expect(invokeCount.abc).to.equal 2
					expect(invokeCount.def).to.equal 3
					expect(getHash()).to.equal 'def'


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


		test "Routing.Router() accpets a number-type argument which will be used as the route loading timeout (ms)", ()->
			sinon.stub(console, 'error')
			invokeCount = abc:0, def:0, ghi:0
			delay = abc:0, def:0
			router = Routing.Router(20)

			Promise.bind(@)
				.then ()->
					router.map('abc').to ()-> invokeCount.abc++; Promise.delay(delay.abc)
					router.map('def').to ()-> invokeCount.def++; Promise.delay(delay.def)
					router.map('ghi').to ()-> invokeCount.ghi++;
					router.listen()

				.delay()
				.then ()->
					@clock = sinon.useFakeTimers(now:Date.now())
				
				.then ()->
					setHash('abc', 10, {@clock})

				.then ()->
					expect(invokeCount).to.eql abc:1, def:0, ghi:0
					expect(console.error.callCount).to.equal 0
					expect(router.current.path).to.equal 'abc'
					expect(getHash()).to.equal 'abc'
					delay.abc = delay.def = 10
					setHash('def', 15, {@clock})

				.then ()->
					expect(invokeCount).to.eql abc:1, def:1, ghi:0
					expect(console.error.callCount).to.equal 0
					expect(router.current.path).to.equal 'def'
					expect(getHash()).to.equal 'def'
					delay.abc = 20
					setHash('abc', 25, {@clock})

				.then ()->
					expect(invokeCount).to.eql abc:2, def:2, ghi:0
					expect(console.error.callCount).to.equal 1
					expect(router.current.path).to.equal 'def'
					expect(getHash()).to.equal 'def'
					delay.def = 20
					setHash('ghi', 10, {@clock})

				.then ()->
					expect(invokeCount).to.eql abc:2, def:2, ghi:1
					expect(console.error.callCount).to.equal 1
					expect(router.current.path).to.equal 'ghi'
					expect(getHash()).to.equal 'ghi'
					setHash('def', 30, {@clock})

				.then ()->
					expect(invokeCount).to.eql abc:2, def:3, ghi:2
					expect(console.error.callCount).to.equal 2
					expect(router.current.path).to.equal 'ghi'
					expect(getHash()).to.equal 'ghi'

				.finally ()->
					console.error.restore()
					@clock.restore()




	suite "destruction", ()->
		test "router.kill() will destroy the router instance and will remove all handlers", ()->
			routerA = Routing.Router()
			routerB = Routing.Router()
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
					defineRoutes(routerA, invokeCountA)
					defineRoutes(routerB, invokeCountB)
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
					routerA.kill()
					invokeChanges()
					
				.then ()->
					expect(invokeCountA.AAA).to.equal 2
					expect(invokeCountA.BBB).to.equal 2
					expect(invokeCountA.CCC).to.equal 2
					expect(invokeCountB.AAA).to.equal 3
					expect(invokeCountB.BBB).to.equal 3
					expect(invokeCountB.CCC).to.equal 3



		test "routing.killAll() will destroy all existing router instances and will remove all handlers", ()->
			routerA = Routing.Router()
			routerB = Routing.Router()
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
					defineRoutes(routerA, invokeCountA)
					defineRoutes(routerB, invokeCountB)
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












