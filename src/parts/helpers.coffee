module.exports = helpers = {}

helpers.noop = ()-> Promise.resolve()

helpers.currentPath = ()->
	helpers.cleanPath(window.location.hash)

helpers.copyObject = (source)->
	target = {}
	target[key] = value for key,value of source
	return target

helpers.removeItem = (target, item)->
	itemIndex = target.indexOf(item)
	target.splice(itemIndex, 1) # if itemIndex isnt -1
	return target

### istanbul ignore next ###
helpers.logError = (err)->
	err = new Error(err) unless err instanceof Error
	if console?.error?
		console.error(err)
	else if console?.log?
		console.log(err)
	return


helpers.applyBase = (path, base)->
	if base and not base.test(path)
		return "#{base.string}/#{path}"

	return path


helpers.removeBase = (path, base)->
	if base and base.test(path)
		return path.slice(base.length+1)

	return path


helpers.cleanPath = (path)->
	path = path.slice(1) if path[0] is '#'
	if path.length > 1
		path = path.slice(1) if path[0] is '/'
		path = path.slice(0,-1) if path[path.length-1] is '/'

	return path


helpers.parsePath = (path)->
	dynamic = optional = false
	currentSegment = ''
	segments = []
	length = path.length
	i = -1

	addSegment = ()->
		segments.push(currentSegment)
		index = segments.length-1
		
		if dynamic
			segments.optional ?= {}
			segments.dynamic ?= {length:0}
			segments.dynamic[index] = currentSegment
		if optional
			segments.optional[index] = currentSegment
		
		currentSegment = ''
		dynamic = optional = false
	

	while ++i isnt length
		switch char = path[i]
			when '/' then addSegment()
			when ':' then dynamic = true
			when '?' then optional = true
			else currentSegment += char

	addSegment()
	return segments


helpers.pathToRegex = (pathOrig)->
	path = pathOrig.replace /\//g, '\\/'
	regex = new RegExp "^#{pathOrig}"
	regex.string = pathOrig
	regex.length = pathOrig.length
	return regex

helpers.segmentsToRegex = (segments)->
	path = ''
	for segment,index in segments
		if segments.dynamic?[index]
			segment = '[^\/]+'
			segment += '$' if segments.length is 1
			segment = "/#{segment}" if path
			segment = "(?:#{segment})?" if segments.optional[index]
		else
			path += '/' if path
		
		path += segment

	return helpers.pathToRegex(path)



