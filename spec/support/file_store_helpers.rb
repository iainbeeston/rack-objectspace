require 'moneta'

module FileStoreHelpers
  def file_store(unique_id)
    Moneta.new(:File, dir: path(unique_id))
  end

  def file_store_keys(unique_id)
    Dir.glob(File.join(path(unique_id), '*')).map { |path| File.basename(path) }
  end

  private

  def path(unique_id)
    File.join('tmp', unique_id)
  end
end
