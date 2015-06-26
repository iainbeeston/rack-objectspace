module RackHelpers
  def profiler(app)
    Rack::Lint.new(Rack::Profiler.new(app))
  end

  def request(app, path, headers = {})
    Rack::MockRequest.new(app).get(path, headers)
  end

  def response(env)
    Rack::MockResponse.new(*env)
  end
end
