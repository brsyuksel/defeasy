# defeasy

`defeasy` is a small library. it helps you define data and accessor properties. 

## install

`npm install defeasy`

## usage

```javascript
var defeasy = require('defeasy');

opt = defeasy(UserDefinedClass.prototype);
```

or 

```javascript
var defeasy = require('defeasy')(); // defined at Object.prototype
```

now, you can call defeasy function for initialization. defeasy function has basic usage:

**defeasy( [target=Object.prototype [, writable=false [, enumerable=true [,configurable=false]]]] );** 

defeasy function defines methods listed at methods section to target and returns an object such as contains option constants.

### defeasy methods

#### instance.defeasy(prop, value [, value1], option)

+ **prop**: name of property. must be string.
+ **value**: for data-property, it must be javascript data: number, string, date, function etc. if you want to define a accessor-property ( getter, setter functions for a key ), you must call this method with two parameters such as they are functions.
+ **option**: attributes of property. it must be a property returned by defeasy initialization function. you can use attributes with `|` operator _(bitwise or)_.
	* defeasy.WRITABLE: define property as writable
	* defeasy.ENUMERABLE: define property as enumerable
	* defeasy.CONFIGURABLE: define property as configurable
	* defeasy.READ_ONLY: define as enumerable, not writable and not configurable
	* defeasy.READ_WRITE: define as writable and configurable. _(= defeasy.WRITABLE | defeasy.CONFIGURABLE)_
	* defeasy.DEFAULT (defeasy.ALL): defined as like by assigning, all attributes are true
	* defeasy.NONE: all attributes are false.
	* defeasy.USE_PROTO: define property at prototype of instance.
	* defeasy.OTHERS_UNDEFINED: it just for accessor-property. if property is already defined and you want to define a new setter(getter) function for it, you can write over getter(setter) as undefined with this option.

```javascript
var defeasy = require('defeasy')(UserDefined.prototype);
var userdf = new UserDefined();

// data-property
userdf.defeasy('prop', 'string-value', defeasy.READ_ONLY);
console.log(userdf.prop); // string-value
desc = Object.getOwnPropertyDescriptor(userdf, 'prop');
desc.writable === false && desc.configurable === false && desc.enumerable === true // true

// accessor-property
getter = function(){ return this.x; };
setter = function(newval){ this.x = newval * 2 };
userdf.defeasy('accessor', getter, setter, defeasy.DEFAULT);
```

#### instance.readOnly(prop, value [, option=defeasy.ENUMERABLE])

defines property as not writable and not configurable. 

#### instance.readWrite(prop, value [,option=defeasy.READ_WRITE])

defines property as writable and configurable

#### instance.accessor(prop, getter, setter [, option=defeasy.ENUMERABLE|defeasy.CONFIGURABLE])

defines a accessor-property. getter and setter parameters must be function. if you want to define a new getter/setter for already defined accessor-property, you can set as undefined it's setter/getter via passing undefined argument and using defeasy.OTHERS_UNDEFINED

```javascript
instance.accessor('accprop', function(){return this.v;}, undefined, defeasy.CONFIGURABLE|defeasy.OTHERS_UNDEFINED);
desc = Object.getOwnPropertyDescriptor(instance, 'accprop');
desc.set === undefined // true
```

#### instance.getter(prop, getter [, option=defeasy.ENUMERABLE|defeasy.CONFIGURABLE])

alias for instance.accessor(prop, getter, undefined, option)

#### instance.setter(prop, setter [, option=defeasy.ENUMERABLE|defeasy.CONFIGURABLE])

alias for instance.accessor(prop, undefined, setter, option)

#### instance.nonExtensibleMe(), instance.sealMe(), instance.freezeMe()

they are alias functions for Object.preventExtensions(instance), Object.seal(instance), Object.freeze(instance)

#### define a property at prototype of instance

```javascript
instance.readWrite('shared', 'shared content', defeasy.ALL|defeasy.USE_PROTO);

var new_instance = new UserDefined();

console.log(new_instance.shared);
```
