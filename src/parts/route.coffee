module.exports = Route = (@path, @segments)->
	@originalPath = @path
	@action = @enterAction = @leaveAction = helpers.noop
	@context = {@path, @segments, params:{}}
	@_dynamicFilters = {}

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

Route::filters = (filters)->
	@_dynamicFilters = filters
	return @


Route::_run = (path, prevRoute, prevPath)->
	@_resolveParams(path)
	Promise.resolve(@enterAction.call(@context, prevPath, prevRoute))
		.then ()=> @action.call(@context, prevPath, prevRoute)

Route::_leave = (newRoute, newPath)->
	@leaveAction.call(@context, newPath, newRoute)

Route::_resolveParams = (path)-> if @segments.hasDynamic
	segments = path.split('/')
	
	for dynamicIndex,dynamicSegment of @segments.dynamic
		@context.params[dynamicSegment] = segments[dynamicIndex] or ''

	return































