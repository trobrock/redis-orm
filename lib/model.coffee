msgpack = require './msgpack'
util = require 'util'

packArray = (array) ->
  output = []
  for item in array
    item = packObject(item) if item.constructor == Object
    output.push(item)
  output

packObject = (object) ->
  output = {}
  for key, value of object
    if isModel value
      output[key] = value.pack()
    else
      output[key] = value
  output

unpack = (value) ->
  return value unless value
  if value.constructor == Array
    # console.log "ARRAY"
    value = (unpack(val) for val in value)
  else if value.constructor == Object
    # console.log "OBJECT"
    for attr, val of value
      # console.log "Unpacking #{attr} => #{val} == #{unpack(val)}"
      value[attr] = unpack(val)
    value
  else
    output = msgpack.unpack(value)
    return value unless output
    return value unless output.constructor == Object
    unpack(output)

isModel = (obj) ->
  return false unless obj
  return false unless obj.constructor.__super__
  obj.constructor.__super__.constructor.name == "Model"

class Model
  pack: ->
    packableObject = {
      type: this.constructor.name
    }
    for attr in @_attributes
      val = this[attr]
      val = packArray(val) if val && val.constructor == Array
      packableObject[attr] = val

    console.log "Before: #{util.inspect(packableObject, false, null, true)}"
    console.log "Unpacked: #{util.inspect(Model.unpack(msgpack.pack(packableObject, true)), false, null, true)}"
    msgpack.pack packableObject, true

  packArray: (array) ->

Model.db         = null
Model.key        = ""

Model.find       = (name) ->
  (item for item in @collection() when item.name == name)[0]
Model.collection = -> @_collection ?= []
Model.sync       = (callback) ->
  @db.smembers @key, (err, items) =>
    @collection().push new this(msgpack.unpack(item)) for item in items
    callback() if callback?
Model.create     = (options) ->
  obj = new this(options)
  @collection().push obj
  @db.sadd @key, obj.pack()
  obj
Model.unpack     = (item) ->
  item = unpack(item)

  item

module.exports = Model
