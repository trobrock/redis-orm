msgpack = require './msgpack'

class Model
  pack: ->
    packableObject = {}
    packableObject[attr] = this[attr] for attr in @_attributes

    msgpack.pack packableObject, true

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

module.exports = Model
