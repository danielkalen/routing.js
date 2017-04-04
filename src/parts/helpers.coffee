module.exports = helpers = {}

helpers.noop = ()-> Promise.resolve()

helpers.removeItem = (target, item)->
	itemIndex = target.indexOf(item)
	target.splice(itemIndex, 1)  if itemIndex isnt -1
	return target

### istanbul ignore next ###
helpers.logError = (err)->
	err = new Error(err) unless err instanceof Error
	if console?.error?
		console.error(err)
	else if console?.log?
		console.log(err)
	return


helpers.cleanPath = (path)->
	path = path.slice(1) if path[0] is '#'
	if path.length > 1
		path = path.slice(1) if path[0] is '/'
		path = path.slice(0,-1) if path[path.length-1] is '/'

	return path


helpers.parsePath = (path)->
	dynamic = false
	currentSegment = ''
	segments = []
	segments.dynamic = {}
	length = path.length
	i = -1

	addSegment = ()->
		segments.push(currentSegment)
		segments.dynamic[segments.length-1] = currentSegment if dynamic
		segments.hasDynamic = true if dynamic
		currentSegment = ''
		dynamic = false
	
	while ++i isnt length
		switch char = path[i]
			when '/' then addSegment()
			when ':' then dynamic = true
			else currentSegment += char

	addSegment()
	return segments




