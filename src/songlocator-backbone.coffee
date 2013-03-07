###

  SongLocator for Backbone.

  2013 (c) Andrey Popp <8mayday@gmail.com>

###

{Collection, Model} = require 'backbone'
{uniqueId, extend} = require 'underscore'

class Stream extends Model

class Song extends Model
  initialize: ->
    super
    this.streams = this.get('streams') or new Collection()
    if not (this.streams instanceof Collection)
      this.streams = new Collection(this.streams)
    this.set('streams', this.streams)
    this.listenTo this.streams, 'change add remove destroy sort reset', =>
      this.trigger 'change:streams', this, this.streams, {}
      this.trigger 'change', this, {}

class Songs extends Collection
  model: Song

  equals: (a, b) ->
    a.get('title').toLowerCase() == b.get('title').toLowerCase() \
      and a.get('artist').toLowerCase() == b.get('artist').toLowerCase()

  songForStream: (stream) ->
    this.find (song) =>
      this.equals(song, stream)

  addStream: (stream) ->
    if not (stream instanceof Stream)
      stream = new Stream(stream)
    song = this.songForStream(stream)
    if song
      streams = song.streams.where(source: stream.source)
      song.streams.add(stream) if streams.length == 0
    else
      song = new Song
        title: stream.get('title')
        artist: stream.get('artist')
        streams: [stream]
      this.add(song)

class ResolvedSongs extends Songs

  constructor: (resolver, songs, options) ->
    super(songs, options)
    this.resolver = resolver
    this.qid = undefined

    this.listenTo this.resolver, 'results', (r) =>
      return unless r.qid == this.qid
      this.addStream(stream) for stream in r.results

  search: (query) ->
    this.qid = uniqueId('searchQID')
    this.resolver.search(this.qid, query)
    this.reset()

  resolve: (title, artist, album) ->
    this.qid = uniqueId('resolveQID')
    this.resolver.resolve(this.qid, title, artist, album)
    this.reset()

extend exports, {Song, Stream, Songs, ResolvedSongs}
