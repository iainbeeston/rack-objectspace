require 'spec_helper'
require 'support/rack_helpers'
require 'support/rack_matchers'
require 'rack/mock'

describe Rack::Profiler do
  include RackHelpers

  it 'does not modify the response from the app' do
    env = [418, { 'Content-Type' => 'text/plain', 'Content-Length' => '12' }, ["I'm a teapot"]]
    app = ->(_) { env }
    profiler = profiler(app)
    expect(request(profiler, '/')).to match_response(response(env))
  end
end
