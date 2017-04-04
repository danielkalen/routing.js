mocha.setup('tdd')
mocha.slow(400)
mocha.timeout(12000)
mocha.bail() unless window.location.hostname
expect = chai.expect
sandbox$ = sandbox = null
restartSandbox = ()->
	sandbox$?.remove()
	sandbox$ = $('<div id="sandbox" style="border:1px solid; padding:20px; box-sizing:border-box"></div>').appendTo(document.body)
	sandbox = sandbox$[0]


suite "routing.js", ()->
	setup(restartSandbox)
