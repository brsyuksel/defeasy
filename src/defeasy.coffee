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

# option range
# min value is default
optRange = (opt, min=0x00, max=0x1F) ->
	opt = if not isNaN +opt then +opt else min
	if (opt&min) is min then (opt&max) else min

# defeasy module function
defeasy = (t=Object.prototype, a={}, w=no, e=yes, c=no) ->
	properties = new DefeasyProperties a, w, e, c
	Object.defineProperties t, properties

constants = 
	WRITABLE: 0x1
	ENUMERABLE: 0x2
	CONFIGURABLE: 0x4
	READ_ONLY: 0x2 # ENUMERABLE
	READ_WRITE: 0x5 # WRITABLE | CONFIGURABLE
	DEFAULT: 0x7 # READ_WRITE | ENUMERABLE
	ALL: 0x7 # DEFAULT
	DEFAULT_ASSIGN: 0x7 # default value for descriptor like as assignment
	NONE: 0x0
	DEFAULT_DEFINE: 0x0 # default value for descriptor like as using definePropert*
	USE_PROTO: 0x8
	OTHERS_UNDEFINED: 0x10

for key, value of constants
	Object.defineProperty defeasy, key, {value:value}

class DefeasyProperties
	constructor: (aliases, writable, enumerable, configurable) ->
		d = defeasy # for constants

		defeasyFn = 
			defeasy: (prop, value..., opt) ->
				# default attributes for property
				# no matter that it is writable for accessors
				# it will not be used
				opt = optRange opt, d.NONE, d.ALL|d.USE_PROTO|d.OTHERS_UNDEFINED

				if value.length > 2 or not value.length
					throw new Error "Invalid descriptor"

				# defining options and property attributes
				[o, p, w, e, c] = [
					!!(opt&d.OTHERS_UNDEFINED), !!(opt&d.USE_PROTO)
					!!(opt&d.WRITABLE), !!(opt&d.ENUMERABLE)
					!!(opt&d.CONFIGURABLE)
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
				opt = optRange opt, d.READ_ONLY, d.READ_ONLY | d.USE_PROTO
				@defeasy prop, value, opt
			readWrite: (prop, value, opt) ->
				opt = optRange opt, d.READ_WRITE, d.USE_PROTO | d.ALL
				@defeasy prop, value, opt

			accessor: (prop, getf, setf, opt) ->
				opt = optRange opt, d.NONE, \
				d.OTHERS_UNDEFINED | d.USE_PROTO | d.ENUMERABLE | d.CONFIGURABLE
				@defeasy prop, getf, setf, opt
			getter: (prop, getf, opt=d.CONFIGURABLE|d.ENUMERABLE) ->
				@accessor prop, getf, undefined, opt
			setter: (prop, setf, opt=d.CONFIGURABLE|d.ENUMERABLE) ->
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

module.exports = defeasy