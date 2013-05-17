# Queuel
[![Gem Version](https://badge.fury.io/rb/queuel.png)](http://badge.fury.io/rb/queuel)
[![Build Status](https://travis-ci.org/sportngin/queuel.png?branch=master)](https://travis-ci.org/sportngin/queuel)

Queuel is a kewl, lite wrapper around Queue interfaces. Currently it implements:

* IronMQ
* Null pattern

Each of these should reliably implement:

* `push`
* `pop`
* `receive`

Along with some further conveniences.

## Installation

Add this line to your application's Gemfile as well as the proper Gem for
your queuing:

```ruby
gem 'iron_mq'
# IronMQ recommends `gem "typhoeus"` as well for some speed benefits
gem 'queuel'
```

And then execute:

    $ bundle

You will then want to configure:

```ruby
Queuel.configure do
  # Optional, but a queue must be selected before running put/pop/receive
  default_queue :venues

  # requirement depends on your Queue
  credentials token: 'asdufasdf8a7sd8fa7sdf', project_id: 'project_id'

  # currently only [:iron_mq, :null] available
  engine :iron_mq

  # For Queuel.recevier {} you can configure more than one thread to
  # handle incoming messages
  receiver_threads 3 # default: 1
end
```

## Usage

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

### The message

```ruby
message.id        # => ID of the message
message.body      # => Message body
message.delete    # => Delete the message
```

## TODO

* Implement AMQP
* Configureable exponential back-off on `receive`
* Logger
* Provide a Daemon

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
