require '../antlr4/code_point_char_stream'

class CharStreams
  DEFAULT_BUFFER_SIZE = 4096

  def self.from_string(s, source_name)
    CodePointCharStream.new(0, s.length, source_name, s.bytes)
  end
end
