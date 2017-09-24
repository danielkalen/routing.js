module.exports = (file, options, file_, content)->
	if options._flags.debug or not file.endsWith('.js')
		return content
	else
		try
			parse = require('esprima').parse
			generate = require('escodegen').generate
			replace = require 'ast-replace'
		catch
			return content
		
		output = replace parse(content),
			CallExpression:
				test: (node)-> node.callee.name is 'debug'
				replace: ()-> null

			VariableDeclarator:
				test: (node)-> node.id.name is 'debug'
				replace: ()-> null

			AssignmentExpression:
				test: (node)-> node.left.name is 'debug'
				replace: ()-> null
			
		return generate(output)



removeNode = (node,collection)->
	if node.parent
		collection ?= 'body' if node.parent and not node.parent.indexOf
		if collection
			node.parent[collection].splice node.parent[collection].indexOf(node), 1
		else
			node.parent.splice node.parent.indexOf(node), 1