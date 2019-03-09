require '../antlr4/lexer_indexed_custom_action'

class LexerActionExecutor
  attr_reader :lexer_actions
  attr_reader :hash_code

  def initialize(lexer_actions)
    @lexer_actions = lexer_actions

    @hash_code = 7
    lexer_actions.each do |lexer_action|
      @hash_code = MurmurHash.update_obj(@hash_code, lexer_action)
    end

    @hash_code = MurmurHash.finish(@hash_code, lexer_actions.length)
  end

  def self.append(lexer_action_executor, lexer_action)
    return LexerActionExecutor.new([lexer_action]) if lexer_action_executor.nil?

    lexer_actions = lexer_action_executor.lexer_actions.dup
    lexer_actions << lexer_action
    LexerActionExecutor.new(lexer_actions)
  end

  def fix_offset_before_match(offset)
    updated_lexer_actions = nil
    i = 0
    while i < @lexer_actions.length
      if @lexer_actions[i].position_dependent? && !(@lexer_actions[i].is_a? LexerIndexedCustomAction)
        updated_lexer_actions = @lexer_actions.dup if updated_lexer_actions.nil?

        updated_lexer_actions[i] = LexerIndexedCustomAction.new(offset, @lexer_actions[i])
      end
      i += 1
    end

    return self if updated_lexer_actions.nil?

    LexerActionExecutor.new(updated_lexer_actions)
  end

  def execute(lexer, input, start_index)
    requires_seek = false
    stop_index = input.index
    begin
      @lexer_actions.each do |lexerAction|
        if lexerAction.is_a? LexerIndexedCustomAction
          offset = lexerAction.getOffset
          input.seek(start_index + offset)
          requires_seek = ((start_index + offset) != stop_index)
        else
          if lexerAction.position_dependent?
            input.seek(stop_index)
            requires_seek = false
          end

          lexerAction.execute(lexer)
        end
      end
    ensure
      input.seek(stop_index) if requires_seek
    end
  end

  def eql?(obj)
    if obj == self
      return true
    else
      return false unless obj.is_a? LexerActionExecutor
    end

    @hash_code == obj.hash_code && (@lexer_actions == obj._a)
  end
end
