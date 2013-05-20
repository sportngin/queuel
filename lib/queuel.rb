require "queuel/version"
require "forwardable"
require "queuel/configurator"
require "queuel/introspect"

require "queuel/base/engine"
require "queuel/base/queue"
require "queuel/base/message"
require "queuel/base/poller"

require "queuel/null/engine"
require "queuel/null/queue"
require "queuel/null/message"
require "queuel/null/poller"

require "queuel/iron_mq/engine"
require "queuel/iron_mq/queue"
require "queuel/iron_mq/message"
require "queuel/iron_mq/poller"

require "queuel/client"

module Queuel
  extend Introspect
  class << self
    extend Forwardable
    def_delegators :client, :push, :pop, :receive, :with
    def_delegators :config, :credentials, :default_queue, :receiver_threads
    alias << pop
  end

  def self.engine
    requires
    warn_engine_selection
    const_with_nesting engine_const_name
  end

  def self.configure(&block)
    config.instance_eval &block
  end

  def self.config
    @config ||= Configurator.new
  end

  def self.client
    Client.new engine, credentials
  end

  def self.logger
    config.logger.tap { |log|
      log.level = config.log_level
    }
  end

  private

  def self.warn_engine_selection
    @warned_null_engine ||= logger.warn(engine_config[:message])
  end

  def self.engine_config
    engines.fetch(config.engine) { engines[:null] }
  end

  def self.configured_engine_name
    engine_config[:const]
  end

  def self.engines
    {
      iron_mq: {
        require: 'iron_mq',
        const: "IronMq",
        message: "Using IronMQ"
      },
      null: {
        const: "Null",
        message: "Using Null Engine, for compatability."
      }
    }
  end

  def self.requires
    require engine_config[:require] if engine_config[:require]
  end

  def self.engine_const_name
    "Queuel::#{configured_engine_name}::Engine"
  end
end
