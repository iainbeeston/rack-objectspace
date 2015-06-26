module RackHelpers
  def rack(middleware)
    Rack::Lint.new(middleware)
  end

  def request(app, path, headers = {})
    Rack::MockRequest.new(app).get(path, headers)
  end

  def response(env)
    Rack::MockResponse.new(*env)
  end
end
