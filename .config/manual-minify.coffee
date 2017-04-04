fs = require 'fs'
replacements = [
	[/_specialRoutes/g, '_s']
	[/_routesMap/g, '_r']
	[/_cache/g, '_c']
	[/_history/g, '_h']
	[/_future/g, '_f']
	[/_globalBefore/g, '_gB']
	[/_globalAfter/g, '_gA']
	[/_pendingRoute/g, '_P']
	[/_pendingPath/g, '_PP']
	[/_matchPath/g, '_M']
	[/_addRoute/g, '_A']
	[/_listenCallback/g, '_lC']
	[/action/g, 'A']
	[/enterAction/g, 'eA']
	[/leaveAction/g, 'lA']
	[/_run/g, '_R']
	[/_leave/g, '_L']
	[/_resolveParams/g, '_RP']
	[/_dynamicFilters/g, '_d']
]


fs.readFile 'dist/routing.js', {encoding:'utf8'}, (err, fileContent)-> if err then throw err else
	output = fileContent
	
	replacements.forEach (replacement)->
		source = replacement[0]
		dest = replacement[1]

		output = output.replace(source, dest)

	fs.writeFile 'dist/routing.js', output, (err)-> if err then throw err
