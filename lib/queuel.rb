require "queuel/version"
require "forwardable"
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
    const_with_nesting const_name
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

  def self.engines
    {
      iron_mq: { require: 'iron_mq', const: "IronMq" },
      null: { const: "Null" }
    }
  end

  def self.requires
    require engines[config.engine][:require] if engines.fetch(config.engine, {})[:require]
  end

  def self.const_name
    "Queuel::#{engines.fetch(config.engine, {}).fetch(:const, nil) || engines[:null][:const]}::Engine"
  end

  class Configurator
    private
    attr_accessor :option_values

    def self.option_values
      @option_values ||= {}
    end

    def self.param(param_name, options = {})
      attr_accessor param_name
      self.option_values[param_name] = options
      define_method param_name do |*values|
        value = values.first
        if value
          self.send("#{param_name}=", value)
        else
          if instance_variable_defined?("@#{param_name}")
            instance_variable_get("@#{param_name}")
          else
            self.class.option_values[param_name][:default]
          end
        end
      end
      public param_name
      public "#{param_name}="
    end

    public

    param :credentials
    param :engine
    param :default_queue
    param :receiver_threads, default: 1
  end
end
