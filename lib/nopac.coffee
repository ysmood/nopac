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
			ego.init_options()
			ego.init_server()

		init_options: ->
			config_path = __dirname + '/config.example'
			ego.opts = require config_path
			ego.opts.config_path = require.resolve config_path

			commander = require 'commander'
			commander
			.usage '[options] [config.coffee or config.js]'
			.option '-p, --port <port>', 'Port to listen to. Default is ' + ego.opts.port, parseInt
			.option '--host <host>', "Host to listen to. Default is #{ego.opts.host} only"
			.option '-v, --ver', 'Print version'
			.option '--setup', 'Setup app'
			.parse process.argv

			if commander.ver
				conf = require '../package'
				ego.log conf.name + ' v' + conf.version
				process.exit()

			if commander.setup
				ego.setup()
				process.exit()

			if commander.args[0]
				ego.opts.config_path = require.resolve commander.args[0]
				config = require ego.opts.config_path

			defaults = (opts) ->
				return if not opts
				for k, v of ego.opts
					if opts[k]
						ego.opts[k] = opts[k]

			defaults config
			defaults commander

		setup: ->
			fs = require 'fs'

			dist_path = __dirname + '/../config.coffee'

			if fs.existsSync(dist_path)
				return

			data = fs.readFileSync(__dirname + '/config.example.coffee')
			fs.writeFileSync(dist_path, data)

		init_server: ->
			http = require 'http'
			fs = require 'fs'

			ego.server = http.createServer ego.pac_handler
			ego.server.listen ego.opts.port, ego.opts.host
			ego.log "Listen: #{ego.opts.host}:#{ego.opts.port}"

			fs.watchFile ego.opts.config_path, {
				persistent: false
				interval: 1000
			}, (curr, prev) ->
				if curr.mtime != prev.mtime
					delete require.cache[ego.opts.config_path]
					opts = require ego.opts.config_path
					ego.opts.pac = opts.pac
					ego.log 'Config reloaded.'

		pac_handler: (req, res) ->
			ht = { req, res }

			ego.log req.socket.address()

			ego.send ht, 'var FindProxyForURL = ' + ego.opts.pac.toString()

		send: (ht, body = '') ->
			ht.res.writeHead 200, {
				'Content-Type': 'application/x-ns-proxy-autoconfig'
				'Content-Length': body.length
			}
			ht.res.end body

		log: (msg, level = 0) ->
			console.log ">>", msg

	}

	for k, v of self
		@[k] = v
	self = @

	for k, v of ego
		if typeof v == 'function'
			v.bind self

	ego.init()

	return self
