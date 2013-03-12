###

  SongLocator for Backbone.

  2013 (c) Andrey Popp <8mayday@gmail.com>

###

((root, factory) ->
  if typeof exports == 'object'
    _ = require 'underscore'
    Backbone = require 'backbone'
    module.exports = factory(_, Backbone, require)
  else if typeof define == 'function' and define.amd
    define (require) ->
      _ = require 'underscore'
      Backbone = require 'backbone'
      root.Backbone.SongLocator = factory(_, Backbone, require)
  else
    root.Backbone.SongLocator = factory(root._, root.Backbone)

) this, (_, Backbone, require) ->

  {Collection, Model} = Backbone
  {uniqueId, extend} = _

  class Stream extends Model

  class Song extends Model

    equals: (b) ->
      this.get('title').toLowerCase() == b.get('title').toLowerCase() \
        and this.get('artist').toLowerCase() == b.get('artist').toLowerCase()

    constructor: (attributes, options) ->
      super

      this.qid = undefined

      this.streams = this.get('streams') or new Collection()
      if not (this.streams instanceof Collection)
        this.streams = new Collection(this.streams)
      this.set('streams', this.streams)
      this.listenTo this.streams, 'change add remove destroy sort reset', =>
        this.trigger 'change:streams', this, this.streams, {}
        this.trigger 'change', this, {}

      if options?.resolver?
        this.resolver = options.resolver
        this.listenTo this.resolver, 'results', (r) =>
          return unless r.qid == this.qid
          for stream in r.results
            stream = new Stream(stream)
            continue unless this.equals(stream)
            this.streams.add(stream) 

    resolve: ->
      this.qid = uniqueId('resolveQID')
      this.resolver.resolve(this.qid, this.get('title'), this.get('artist'))

  class Songs extends Collection
    model: Song

    songForStream: (stream) ->
      this.find (song) =>
        song.equals(stream)

    createSong: (stream) ->
      new Song
        title: stream.get('title')
        artist: stream.get('artist')
        streams: [stream]

    addStream: (stream) ->
      if not (stream instanceof Stream)
        stream = new Stream(stream)
      song = this.songForStream(stream)
      if song
        streams = song.streams.where(source: stream.source)
        song.streams.add(stream) if streams.length == 0
      else
        song = this.createSong(stream)
        this.add(song)

  class ResolvedSongs extends Songs

    constructor: (resolver, songs, options) ->
      super(songs, options)
      this.resolver = resolver
      this.qid = undefined

      this.listenTo this.resolver, 'results', (r) =>
        return unless r.qid == this.qid
        this.addStream(stream) for stream in r.results

    createSong: (stream) ->
      new Song {
        title: stream.get('title')
        artist: stream.get('artist')
        streams: [stream]
      }, {resolver: this.resolver}

    search: (query) ->
      this.qid = uniqueId('searchQID')
      this.resolver.search(this.qid, query)
      this.reset()

  {Song, Stream, Songs, ResolvedSongs}
