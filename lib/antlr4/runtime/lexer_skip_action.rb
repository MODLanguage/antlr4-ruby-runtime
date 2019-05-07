module Antlr4::Runtime

  class LexerSkipAction < LexerAction
    include Singleton

    def action_type
      LexerActionType::SKIP
    end

    def position_dependent?
      false
    end

    def execute(lexer)
      lexer.skip
    end

    def hash
      return @_hash unless @_hash.nil?

      hash_code = MurmurHash.hash_int(action_type)

      if !@_hash.nil?
        if hash_code == @_hash
          puts 'Same hash_code for LexerSkipAction'
        else
          puts 'Different hash_code for LexerSkipAction'
        end
      end
      @_hash = hash_code
    end

    def eql?(other)
      other == self
    end

    def to_s
      'skip'
    end
  end
end
