assert = require 'assert'
Defeasy = require '../'

describe 'defeasy', ->
	methods = [
		"defeasy", "readOnly", "readWrite"
		"setter", "getter", "accessor",
		"nonExtensibleMe", "sealMe", "freezeMe"
	]

	describe 'defeasing', ->
		it 'defeasy should return an object', ->
			class DefeasyTest
			defeasy = Defeasy DefeasyTest.prototype
			assert.ok !!defeasy
			assert.ok Object.isFrozen defeasy

		it 'prototype should have defeasy methods as non-c and non-w', ->
			class DefeasyTest2
			defeasy = Defeasy DefeasyTest2.prototype
			res = methods.every (e, i, a) ->
				desc = Object.getOwnPropertyDescriptor DefeasyTest2.prototype, e
				!desc.writable and !desc.configurable

			assert.ok res

		it 'prototype should have defeasy methods as configurable and writable', ->
			class DefeasyTest3
			defeasy = Defeasy DefeasyTest3.prototype, {}, yes, yes, yes
			res = methods.every (e, i, a) ->
				desc = Object.getOwnPropertyDescriptor DefeasyTest3.prototype, e
				desc.writable and desc.configurable

			assert.ok res

		it 'prototype should have read_only method when setted alias for readOnly', ->
			class DefeasyTest3a
			defeasy = Defeasy DefeasyTest3a.prototype, {'readOnly':'read_only'}
			assert.ok DefeasyTest3a.prototype.hasOwnProperty 'read_only'

	describe 'instance', ->
		it 'nonextensible, sealed, frozen instance', ->
			class DefeasyTest4
				constructor: ->
					@x = 1
			defeasy = Defeasy DefeasyTest4.prototype, {}, yes, yes, yes
			x = new DefeasyTest4

			assert.ifError not Object.isExtensible(x) or Object.isSealed(x) or Object.isFrozen(x)

			x.nonExtensibleMe()
			assert.ifError Object.isExtensible x

			x.sealMe()
			assert.ok Object.isSealed x

			x.freezeMe()
			assert.ok Object.isFrozen x

	describe 'property', ->
		class DefeasyTest5
			constructor: ->
				@x = 1
		defeasy = Defeasy DefeasyTest5.prototype
		x = new DefeasyTest5

		it '(non-)writable, (non-)enumerable, (non-)configurable', ->
			x.defeasy 'b', 2, defeasy.NONE
			x.b = 3
			assert.equal x.b, 2
			delete x.b
			assert.ok !!x.b
			assert.ifError !!~Object.keys(x).indexOf('b')
			assert.throws -> x.defeasy 'b', 3, defeasy.ALL

			# WRITABLE
			x.defeasy 'c', 3, defeasy.WRITABLE
			desc = Object.getOwnPropertyDescriptor x, 'c'
			assert.ok desc.writable and not desc.enumerable and not desc.configurable

			# ENUMERABLE
			x.defeasy 'd', 4, defeasy.ENUMERABLE
			desc = Object.getOwnPropertyDescriptor x, 'd'
			assert.ok not desc.writable and desc.enumerable and not desc.configurable

			# CONFIGURABLE
			x.defeasy 'e', 5, defeasy.CONFIGURABLE
			desc = Object.getOwnPropertyDescriptor x, 'e'
			assert.ok not desc.writable and not desc.enumerable and desc.configurable

		it 'readOnly-readWrite methods', ->
			x.readOnly 'f', 6
			desc = Object.getOwnPropertyDescriptor x, 'f'
			assert.ok not desc.writable and desc.enumerable and not desc.configurable

			# try to define as writable with .readOnly
			x.readOnly 'g', 6, defeasy.WRITABLE
			desc = Object.getOwnPropertyDescriptor x, 'g'
			assert.ifError desc.writable

			# readwrite
			x.readWrite 'h', 7
			desc = Object.getOwnPropertyDescriptor x, 'h'
			assert.ok desc.writable and not desc.enumerable and desc.configurable

			x.readWrite 'h', 7, defeasy.ALL
			desc = Object.getOwnPropertyDescriptor x, 'h'
			assert.ok desc.enumerable

		it 'defeasy ALL-NONE-USE_PROTO constants', ->
			x.defeasy 'h', 8, defeasy.ALL
			desc = Object.getOwnPropertyDescriptor x, 'h'
			assert.ok desc.writable and desc.enumerable and desc.configurable

			x.defeasy 'h', 8, defeasy.NONE
			desc = Object.getOwnPropertyDescriptor x, 'h'
			assert.ok not desc.writable and not desc.enumerable and not desc.configurable

			x.defeasy 'i', 10, defeasy.ALL | defeasy.USE_PROTO
			y = new DefeasyTest5
			assert.equal y.i, 10
			desc = Object.getOwnPropertyDescriptor DefeasyTest5.prototype, 'i'
			assert.ok desc.writable and desc.enumerable and desc.configurable

		it 'accessor property', ->

			getf = -> @c
			setf = (v) -> @c = v * 3
			x.defeasy 'j', getf, setf, defeasy.CONFIGURABLE
			assert.equal x.j, 3
			x.j = 10
			assert.equal x.j, 30

			# dont write over setter
			getf = -> @c-1
			x.defeasy 'j', getf, undefined, defeasy.CONFIGURABLE
			assert.equal x.j, 29
			x.j = 4
			assert.equal x.j, 11

			# write over setter as undefined
			x.defeasy 'j', getf, undefined, defeasy.CONFIGURABLE | defeasy.OTHERS_UNDEFINED
			assert.equal x.j, 11
			x.j = 5
			assert.equal x.j, 11

			# define setter
			x.setter 'j', setf
			x.j = 6
			assert.equal x.j, 17

			# define getter
			x.getter 'j', -> @c
			assert.equal x.j, 18

			# not function getter throws
			assert.throws -> x.getter 'j', 6

		it 'invalid desc', ->
			assert.throws -> x.defeasy 'in', 3,4,5,6, defeasy.ALL
			assert.throws -> x.defeasy 'in', 3