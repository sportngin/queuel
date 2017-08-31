module IntegrationHelpers
  QUEUE = nil

  def config
    @@config ||= YAML::load_file(File.expand_path('../../integration.yml', __FILE__))
  end

  def queue
    @queue ||= QUEUE || begin
      c = config
      creds = Hash[*c['credentials'].map {|k, v| [k.to_sym, v]}.flatten]
      Queuel.configure do
        engine c['engine'].to_s.to_sym
        credentials creds
      end
      Queuel.with(c['queue']).tap {|q| silence_warnings { IntegrationHelpers.const_set(:QUEUE, q) } }
    end
  end

  def silence_warnings
    v, $VERBOSE = $VERBOSE, nil
    yield
  ensure
    $VERBOSE = v
  end
end
