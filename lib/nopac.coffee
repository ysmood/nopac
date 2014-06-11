fs = require 'fs'

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
			config_path = require.resolve __dirname + '/../config'
			if not fs.existsSync(config_path)
				config_path = require.resolve(__dirname + '/config.example')
			ego.opts = require config_path
			ego.opts.config_path = config_path

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

					for k, v of opts
						ego.opts[k] = v

					ego.log 'Config reloaded.'
			ego.log 'Watch: ' + ego.opts.config_path

		pac_handler: (req, res) ->
			ht = { req, res }

			ego.log req.socket.address()

			reg_list = ''
			for k, v of ego.opts.$
				reg_list += k + ':' + v

			data_list = ''
			for k, v of ego.opts
				if k[0] == '$' and k.length > 1
					data_list += 'var ' + k + '=' + JSON.stringify(v) + ';'

			ego.send ht, 'var $ = {' + reg_list + '};' +
				data_list +
				'var FindProxyForURL = ' + ego.opts.pac.toString()

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
