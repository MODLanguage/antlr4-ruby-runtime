require '../antlr4/chunk'

class TextChunk < Chunk
  attr_reader :text

  def initialize(text)
    raise IllegalArgumentException, 'text cannot be null' if text.nil?

    @text = text
  end

  def to_s
    "'" + @text + "'"
  end
end
