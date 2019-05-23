module Antlr4::Runtime

  class CharStreams
    DEFAULT_BUFFER_SIZE = 4096

    def self.from_string(s, source_name)
      CodePointCharStream.new(0, s.length, source_name, s.codepoints)
    end
  end
end
