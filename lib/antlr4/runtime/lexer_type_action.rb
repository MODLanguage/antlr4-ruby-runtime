module Antlr4::Runtime

  class LexerTypeAction < LexerAction
    attr_reader :type

    def initialize(type)
      @type = type
    end

    def action_type
      LexerActionType::TYPE
    end

    def position_dependent?
      false
    end

    def execute(lexer)
      lexer._type = @type
    end

    def hash
      return @_hash unless @_hash.nil?

      hash_code = RumourHash.calculate([action_type, @type])

      unless @_hash.nil?
        if hash_code == @_hash
          puts 'Same hash_code for LexerTypeAction'
        else
          puts 'Different hash_code for LexerTypeAction'
        end
      end
      @_hash = hash_code
    end

    def eql?(other)
      if other == self
        return true
      else
        return false unless other.is_a? LexerTypeAction
      end

      @type == other.type
    end

    def to_s
      'type(' << @type << ')'
    end
  end
end
