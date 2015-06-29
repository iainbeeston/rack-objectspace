require 'moneta'
require 'yaml'

module FakeStoreHelpers
  def fake_store(unique_id)
    Moneta.new(:YAML, file: path(unique_id))
  end

  def fake_store_keys(unique_id)
    YAML.load_file(path(unique_id)).keys
  end

  private

  def path(unique_id)
    File.join('tmp', "#{unique_id}.yml")
  end
end
