helpers = exports

helpers.noopObj = {}

helpers.noop = ()-> Promise.resolve()

helpers.currentPath = ()->
	helpers.cleanPath(window.location.hash)

# helpers.currentQuery = ()->
# 	helpers.parseQuery(window.location.hash)

helpers.removeQuery = (path)->
	path.split('?')[0]

helpers.parseQuery = (path, parser)->
	query = path.split('?').slice(1).join('?')
	
	if query
		query = decodeURIComponent(query)
		parsed = {}
		pairs = query.split('&')
		
		for pair in pairs
			split = pair.split('=')
			key = split[0]
			value = split[1]
			if (value[0] is '{' or value[0] is '[') and (value[value.length-1] is '}' or value[value.length-1] is ']')
				value = JSON.parse(value, parser)
			else if parser
				value = parser(key, value)
			
			parsed[key] = value

		return parsed

	return helpers.noopObj

helpers.serializeQuery = (query, serializer)->
	output = ''
	keys = Object.keys(query)
	for key in keys
		value = query[key]
		output += '&' if output
		output += "#{key}="
		if value and typeof value is 'object'
			value = JSON.stringify(value, serializer)
			value = value.slice(1,-1) if value[0] is '"' and value[value.length-1] is '"'
		else if serializer
			value = serializer(key, value)
		else
			value = value
		
		output += encodeURIComponent value

	return output


helpers.copyObject = (source)->
	target = {}
	target[key] = value for key,value of source
	return target

helpers.includes = (target, item)->
	target.indexOf(item) isnt -1

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
		path = path.slice(base.length+1)
		path = '/'+path if not path.length or path[0] is '?'

	return path


helpers.cleanPath = (path)->
	path = path.slice(1) if path[0] is '#'
	if path.length is 0 or path[0] is '?'
		path = '/'+path
	
	else if path.length > 1
		path = path.slice(1) if path[0] is '/'
		path = path.slice(0,-1) if path[path.length-1] is '/'

	return path


helpers.parsePath = (path)->
	return ['/'] if path is '/'
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


helpers.pathToRegex = (targetPath, openEnded, original)->
	path = targetPath.replace /\//g, '\\/'
	regex = "^#{targetPath}"
	regex += '$' unless openEnded
	regex = new RegExp(regex)
	regex.original = original
	regex.string = targetPath
	regex.length = targetPath.length
	return regex


helpers.segmentsToRegex = (segments, original)->
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

	return helpers.pathToRegex(path, false, original)



