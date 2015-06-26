module RackHelpers
  def linter(middleware)
    Rack::Lint.new(middleware)
  end

  def request(path, opts = {})
    Rack::MockRequest.env_for(path, opts)
  end

  def response(middleware, path, headers = {})
    Rack::MockRequest.new(linter(middleware)).get(path, headers)
  end
end
