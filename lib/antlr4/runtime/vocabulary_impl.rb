require '../antlr4/vocabulary'

class VocabularyImpl < Vocabulary
  @@empty_names = []

  def initialize(literal_names, symbolic_names, display_names = nil)
    @literal_names = !literal_names.nil? ? literal_names : @@empty_names
    @symbolic_names = !symbolic_names.nil? ? symbolic_names : @@empty_names
    @display_names = !display_names.nil? ? display_names : @@empty_names
    # See note here on -1 part: https:#github.com/antlr/antlr4/pull/1146
    @max_token_type = [@display_names.length, @literal_names.length, @symbolic_names.length].max - 1
  end

  EMPTY_VOCABULARY = VocabularyImpl.new(@@empty_names, @@empty_names, @@empty_names)

  def self.from_token_names(token_names)
    return EMPTY_VOCABULARY if token_names.nil? || token_names.empty?

    @literal_names = Array.new(token_names)
    @symbolic_names = Array.new(token_names)
    i = 0
    while i < token_names.length
      token_name = token_names[i]
      if token_name.nil?
        i += 1
        next
      end

      unless token_name.empty?
        first_char = token_name[0]
        if first_char == '\''
          @symbolic_names[i] = nil
          i += 1
          next
        end
      end

      # wasn't a literal or symbolic name
      @literal_names[i] = nil
      @symbolic_names[i] = nil
      i += 1
    end

    VocabularyImpl.new(@literal_names, @symbolic_names, token_names)
  end

  def literal_name(token_type)
    if token_type >= 0 && token_type < @literal_names.length
      return @literal_names[token_type]
    end

    nil
  end

  def symbolic_name(token_type)
    if token_type >= 0 && token_type < @symbolic_names.length
      return @symbolic_names[token_type]
    end

    return 'EOF' if token_type == Token::EOF

    token_type.to_s
  end

  def display_name(token_type)
    if token_type >= 0 && token_type < @display_names.length
      disp_name = @display_names[token_type]
      return disp_name unless disp_name.nil?
    end

    lit_name = literal_name(token_type)
    return lit_name unless lit_name.nil?

    sym_name = symbolic_name(token_type)
    return sym_name unless sym_name.nil?

    Integer.to_s(token_type)
  end
end
