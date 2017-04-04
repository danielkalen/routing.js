module.exports = Route = (@path, @segments)->
	@action = @enterAction = @leaveAction = noop
	@context = params:{}

	return @



Route::entering = (fn)->
	@enterAction = fn
	return @

Route::leaving = (fn)->
	@leaveAction = fn
	return @

Route::to = (fn)->
	@action = fn
	return @


Route::_run = (path, prevRoute, prevPath)->
	@_resolveParams(path)
	Promise.resolve(@enterAction.call(@context, prevPath, prevRoute))
		.then ()=> @action.call(@context, prevPath, prevRoute)

Route::_leave = (newRoute, newPath)->
	@leaveAction.call(@context, newPath, newRoute)

Route::_resolveParams = (path)->
	segments = path.split('/')
	
	for dynamicIndex,dynamicSegment of @segments.dynamic
		@context.params[dynamicSegment] = segments[dynamicIndex] or ''

	return































