module Antlr4::Runtime

  class LexerPopModeAction < LexerAction
    include Singleton

    def action_type
      LexerActionType::POP_MODE
    end

    def position_dependent?
      false
    end

    def execute(lexer)
      lexer.pop_mode
    end

    def hash
      return @_hash unless @_hash.nil?

      hash_code = RumourHash.calculate([action_type])

      if !@_hash.nil?
        if hash_code == @_hash
          puts 'Same hash_code for LexerPopModeAction'
        else
          puts 'Different hash_code for LexerPopModeAction'
        end
      end
      @_hash = hash_code
    end

    def equals(other)
      other == self
    end

    def to_s
      'popMode'
    end
  end
end
