###

  SongLocator for Backbone.

  2013 (c) Andrey Popp <8mayday@gmail.com>

###

{Collection, Model} = require 'backbone'
{uniqueId, extend} = require 'underscore'

class Song extends Model
  initialize: ->
    super
    this.streams = this.streams or new Collection()
    if not (this.streams instanceof Collection)
      this.streams = new Collection(this.streams)
    this.set('streams', this.streams)

class Songs extends Collection
  model: Song

  equals: (a, b) ->
    a.get('track').toLowerCase() == b.get('track').toLowerCase() \
      and a.get('artist').toLowerCase() == b.get('artist').toLowerCase()

  songForStream: (stream) ->
    this.find (song) -> equals(song, stream)

  addStream: (stream) ->
    song = this.songForStream(stream)
    if song
      streams = song.streams.where(source: stream.source)
      song.streams.add(stream) if streams.length == 0
    else
      song = new Song(track: stream.track, artist: stream.artist, streams: [stream])
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
    this.reset()

  resolve: (track, artist, album) ->
    this.qid = uniqueId('resolveQID')
    this.reset()

extend exports, {Song, Stream, Songs, ResolvedSongs}
