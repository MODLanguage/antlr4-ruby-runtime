module Antlr4::Runtime

  class LexerModeAction < LexerAction
    attr_reader :mode

    def initialize(mode)
      @mode = mode
    end

    def action_type
      LexerActionType::MODE
    end

    def position_dependent?
      false
    end

    def execute(lexer)
      lexer.mode(@mode)
    end

    def hash
      return @_hash unless @_hash.nil?

      hash_code = RumourHash.calculate([action_type, mode])

      unless @_hash.nil?
        if hash_code == @_hash
          puts 'Same hash_code for LexerModeAction'
        else
          puts 'Different hash_code for LexerModeAction'
        end
      end
      @_hash = hash_code
    end

    def eql?(other)
      if other == self
        return true
      else
        return false unless other.is_a? LexerModeAction
      end

      @mode == other.mode
    end

    def to_s
      'mode(' << @mode << ')'
    end
  end
end
