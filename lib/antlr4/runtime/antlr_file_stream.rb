class ANTLRFileStream < ANTLRInputStream
  def initialize(file_name, encoding)
    @file_name = file_name
    load(file_name, encoding)
  end

  def load(file_name, encoding)
    data = Utils.read_file(file_name, encoding)
    @n_items = data.length
  end

  def source_name
    @file_name
  end
end
