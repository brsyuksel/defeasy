class DefeasyOptions
	constructor: ->
		@WRITABLE = 0x1
		@ENUMERABLE = 0x2
		@CONFIGURABLE = 0x4

		@READ_ONLY = @ENUMERABLE
		@READ_WRITE = @WRITABLE | @CONFIGURABLE

		@DEFAULT = @ALL = @READ_WRITE | @ENUMERABLE
		@NONE = 0x0

		@USE_PROTO = 0x8
		@OTHERS_UNDEFINED = 0x10
defy = new DefeasyOptions
Object.freeze defy

class Descriptor
	constructor: (enumerable, configurable) ->
		this.enumerable = !!enumerable
		this.configurable = !!configurable

class DataDescriptor extends Descriptor
	constructor: (value, writable, enumerable, configurable) ->
		this.value = value
		this.writable = !!writable
		super enumerable, configurable

class AccessorDescriptor extends Descriptor
	constructor: (getf, setf, enumerable, configurable) ->
		this.get = if typeof getf is "function" then getf else undefined
		this.set = if typeof setf is "function" then setf else undefined
		super enumerable, configurable

optRange = (opt, defaultv, max=0x1F) ->
	opt = if not isNaN +opt then +opt else defaultv
	opt &= max
	opt

class DefeasyPrototype
	constructor: (aliases, writable, enumerable, configurable) ->
		defeasyFn = 
			defeasy: (prop, value..., opt) ->
				# default attributes for property
				# no matter that it is writable for accessors
				# it will not be used
				opt = optRange opt, defy.READ_WRITE | defy.ENUMERABLE, 0xFF

				if value.length > 2 or not value.length
					throw new Error "Invalid descriptor"

				# defining options and property attributes
				[o, p, w, e, c] = [
					!!(opt&defy.OTHERS_UNDEFINED), !!(opt&defy.USE_PROTO)
					!!(opt&defy.WRITABLE), !!(opt&defy.ENUMERABLE)
					!!(opt&defy.CONFIGURABLE)
				]

				# p is true means define at __proto__
				target = if p then Object.getPrototypeOf @ else @

				# behave it is accessor property
				# if value length is 2 and functions are valid,
				# it's accessor, both getter and setter functions are not
				# valid, throw Error, otherwise it is data property
				[getf, setf] = value

				if value.length is 2 and \
				(typeof getf is "function" or typeof setf is "function")
					# try to get current descriptor of property
					# cause overwriting as undefined is not allowed
					if not o and target.hasOwnProperty prop
						current = Object.getOwnPropertyDescriptor target, prop
						getf ?= current.get
						setf ?= current.set

					desc = new AccessorDescriptor getf, setf, e, c
				else if value.length is 1
					desc = new DataDescriptor getf, w, e, c
				else
					throw new Error "Invalid descriptor"

				Object.defineProperty target, prop, desc
			
			readOnly: (prop, value, opt) ->
				opt = optRange opt,defy.READ_ONLY, defy.USE_PROTO|defy.READ_ONLY
				@defeasy prop, value, opt
			readWrite: (prop, value, opt) ->
				opt = optRange opt, defy.READ_WRITE, defy.USE_PROTO|defy.ALL
				@defeasy prop, value, opt

			accessor: (prop, getf, setf, opt) ->
				opt = optRange opt, defy.ENUMERABLE | defy.CONFIGURABLE, \
				defy.OTHERS_UNDEFINED | defy.USE_PROTO | defy.ENUMERABLE | \
				defy.CONFIGURABLE
				@defeasy prop, getf, setf, opt
			getter: (prop, getf, opt) ->
				@accessor prop, getf, undefined, opt
			setter: (prop, setf, opt) ->
				@accessor prop, undefined, setf, opt

			nonExtensibleMe: ->
				Object.isExtensible(@) and Object.preventExtensions @
			sealMe: ->
				not Object.isSealed(@) and Object.seal @
			freezeMe: ->
				not Object.isFrozen(@) and Object.freeze @

		for key, dfn of defeasyFn
			@[aliases[key] || key] = new DataDescriptor dfn, writable, \
			enumerable, configurable

module.exports =
	Defeasy: (t=Object.prototype, a={}, w=no, e=yes, c=no) ->
		properties = new DefeasyPrototype a, w, e, c
		Object.defineProperties t, properties

		defy
	DefeasyOptions: defy