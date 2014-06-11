http = require 'http'

###
    Nopac
###
module.exports = class Nopac then constructor: ->

	# Public
	self = {

	}

	# Private
	ego = {
		init: ->
	}

	for k, v of self
		@[k] = v
	self = @

	for k, v of ego
		if typeof v == 'function'
			v.bind self

	ego.init()

	return self
