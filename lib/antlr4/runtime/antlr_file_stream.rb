module Antlr4::Runtime
  class ANTLRFileStream < ANTLRInputStream
    def initialize(file_name, encoding)
      @file_name = file_name
      load_file(file_name, encoding)
    end

    def load_file(file_name, encoding)
      data = Utils.read_file(file_name, encoding)
      @n_items = data.length
    end

    def source_name
      @file_name
    end
  end
end