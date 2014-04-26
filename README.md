Queuel
======

[![Gem Version](https://badge.fury.io/rb/queuel.png)](http://badge.fury.io/rb/queuel)
[![Build Status](https://travis-ci.org/sportngin/queuel.png?branch=master)](https://travis-ci.org/sportngin/queuel)
[![Code Climate](https://codeclimate.com/github/sportngin/queuel.png)](https://codeclimate.com/github/sportngin/queuel)
[![Coverage Status](https://coveralls.io/repos/sportngin/queuel/badge.png)](https://coveralls.io/r/sportngin/queuel)

Queuel is a 'kewl', lite wrapper around Queue interfaces. Currently it implements:

* IronMQ
* Amazon SQS
* RabbitMQ
* Null pattern

Each of these should reliably implement:

* `push`
* `pop`
* `receive`

Along with some further conveniences.



Installation
------------

Add this line to your application's Gemfile as well as the proper Gem for
your queuing:

```ruby
gem 'iron_mq'
# IronMQ recommends `gem "typhoeus"` as well for some speed benefits
gem 'queuel'
```

And then execute:

```bash
$ bundle
```

You will then want to configure:

```ruby
Queuel.configure do
  # Optional, but a queue must be selected before running put/pop/receive
  default_queue :venues

  # requirement depends on your Queue
  credentials token: 'asdufasdf8a7sd8fa7sdf', project_id: 'project_id'

  # currently [:iron_mq, :rabbit_mq, :sqs, :null] available
  engine :iron_mq

  # For Queuel.recevier {} you can configure more than one thread to
  # handle incoming messages
  receiver_threads 3 # default: 1

  # Logging: Default is MonoLogger, because its a non-blocking log-extension
  # To the standard lib Logger. Any Log4r solution should work.
  logger Logger # default: MonoLogger.new(STDOUT)

  log_level MonoLogger::DEBUG # default: MonoLogger::ERROR # => 3

  # Incoming messages can be automatically encoded/decoded
  decode_by_default false # default: true
  decoder ->(body) { MultiJson.load body } # default: Queuel::Serialization::Json::Decoder

  encode_by_default false # default: true
  encoder ->(body) { body.to_s } # default: Queuel::Serialization::Json::Encoder
end
```



Usage
-----

### General Queue API

```ruby
# Using default Queue from config
Queuel.pop
Queuel.push "My message to you"
Queuel.receive do |message|
  puts "I received #{message.body}" # NOTE the message interface may change, this is currently not wrapped by the gem
end

# With the non-default queue
Queuel.with("officials").pop
Queuel.with("officials").push "My message to you"
Queuel.with("officials").receive do |message|
  puts "I received #{message.body}" # NOTE the message interface may change, this is currently not wrapped by the gem
end

# Break on nil
Queuel.receive break_if_nil: true do |message|
  puts "I received #{message.body}" # NOTE the message interface may change, this is currently not wrapped by the gem
end
```

#### Caveats of the receiver

* Your block must return true in order to not replace the message to the Queue

#### SQS s3 fallback

Currently the SQS engine is the only engine with the s3 fallback support and
takes the following keys:

* `s3_access_key_id`
* `s3_secret_access_key`
* `s3_bucket_name`
* `max_bytesize` (optional)

With these in place, messages over the `max_bytesize` (defaults to 64kb) will
be sent to the designated bucket.  Without this in place, messages over SQS's
limit be dropped from the queue.


### The message

```ruby
message.id        # => ID of the message
message.raw_body  # => Raw Message body
message.body      # => Message body (parsed, if configured to do so)
message.delete    # => Delete the message
```

#### Parsing

Queuel uses [MultiJson](https://github.com/intridea/multi_json) to provide
some auto-message decoding/encoding features. With MultiJson you may install your own engine
(like [Oj](https://github.com/ohler55/oj)).

Because of the parsing given, you will default to encoding and decoding JSON:

```ruby
Queuel.push username: "jon"
Queuel.pop # => { username: "jon" }
```

You can configure your decoder/encoder on the fly:

```ruby
Queuel.push { username: "jon" }, encoder: ->(body) {  }
Queuel.pop decoder: ->(raw) { }
Queuel.receive decoder: ->(raw) { }
```

You can turn of encoding/decoding at calltime with:

```ruby
Queuel.push { username: "jon" }, encode: false
Queuel.pop decode: false
Queuel.receive decode: false
```



Contributing
------------

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
