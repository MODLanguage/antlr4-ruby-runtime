require '../antlr4/chunk'

class TagChunk < Chunk
  attr_reader :tag
  attr_reader :label

  def initialize(label, tag)
    if tag.nil? || tag.empty?
      raise IllegalArgumentException, 'tag cannot be nil or empty'
    end

    @label = label
    @tag = tag
  end

  def to_s
    return @label + ':' + @tag unless @label.nil?

    @tag
  end
end
