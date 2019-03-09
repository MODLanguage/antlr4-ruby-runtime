class SemanticContext
  def eval(parser, parser_call_stack)
  end

  def eval_precedence(_parser, _parser_call_stack)
    self
  end

  class Predicate < SemanticContext
    attr_accessor :rule_index
    attr_accessor :pred_index
    attr_accessor :is_ctx_dependent # e.g., $i ref in pred

    def initialize(rule_index = -1, pred_index = -1, is_ctx_dependent = false)
      @rule_index = rule_index
      @pred_index = pred_index
      @is_ctx_dependent = is_ctx_dependent
    end

    def eval(parser, parser_call_stack)
      localctx = @is_ctx_dependent ? parser_call_stack : nil
      parser.sempred(localctx, @rule_index, @pred_index)
    end

    def hash
      hashcode = 0
      hashcode = MurmurHash.update_int(hashcode, @rule_index)
      hashcode = MurmurHash.update_int(hashcode, @pred_index)
      hashcode = MurmurHash.update_int(hashcode, @is_ctx_dependent ? 1 : 0)
      MurmurHash.finish(hashcode, 3)
    end

    def eql?(other)
      return false unless other.is_a? Predicate
      return true if self == other

      @rule_index == other.rule_index && @pred_index == other.pred_index && @is_ctx_dependent == other.is_ctx_dependent
    end

    def to_s
      '' + @rule_index + ':' + @pred_index + 'end?'
    end
  end

  class PrecedencePredicate < SemanticContext
    attr_accessor :precedence

    def initialize(precedence = 0)
      @precedence = precedence
    end

    def eval(parser, parser_call_stack)
      parser.precpred(parser_call_stack, @precedence)
    end

    def eval_precedence(parser, parser_call_stack)
      SemanticContext::NONE if parser.precpred(parser_call_stack, @precedence)
    end

    def compare_to(o)
      @precedence - o.precedence
    end

    def hash
      hash_code = 1
      31 * hash_code + @precedence
    end

    def eql?(other)
      return false unless other.is_a? PrecedencePredicate

      return true if self == other

      @precedence == other.precedence
    end

    # precedence >= _precedenceStack.peek()
    def to_s
      '' + @precedence + '>=precend?'
    end
  end

  class Operator < SemanticContext
    def operands
    end
  end

  class AND < Operator
    attr_accessor :opnds

    def initialize(a, b)
      operands = Set.new
      if a.is_a? AND
        operands.add_all(a.opnds)
      else
        operands.add(a)
      end
      if b.is_a? AND
        operands.add_all(b.opnds)
      else
        operands.add(b)
      end
      precedence_predicates = filter_precedence_predicates(operands)
      unless precedence_predicates.empty?
        # interested in the transition with the lowest precedence
        reduced = precedence_predicates.min
        operands.add(reduced)
      end

      @opnds = operands.to_a
    end

    def eql?(other)
      return true if self == other
      return false unless other.is_a? AND

      @opnds.eql?(other.opnds)
    end

    def hash
      MurmurHash.hash(@opnds, AND.hash)
    end

    def eval(parser, parser_call_stack)
      @opnds.each do |opnd|
        return false unless opnd.eval(parser, parser_call_stack)
      end
      true
    end

    def eval_precedence(parser, parser_call_stack)
      differs = false
      operands = []
      @opnds.each do |context|
        evaluated = context.eval_precedence(parser, parser_call_stack)
        differs |= (evaluated != context)
        if evaluated == null
          # The AND context is false if any element is false
          return nil
        elsif evaluated != NONE
          # Reduce the result by skipping true elements
          operands.add(evaluated)
        end
      end

      return self unless differs

      if operands.empty?
        # all elements were true, so the AND context is true
        return NONE
      end

      result = operands[0]
      i = 1
      while i < operands.length
        result = SemanticContext.and(result, operands.get(i))
        i += 1
      end

      result
    end

    def to_s
      @opnds.join('&&')
    end
  end

  class OR < Operator
    attr_accessor :opnds

    def initialize(a, b)
      operands = Set.new
      if a.is_a? OR
        operands.add_all(a.opnds)
      else
        operands.add(a)
      end
      if b.is_a? OR
        operands.add_all(b.opnds)
      else
        operands.add(b)
      end

      precedence_predicates = filter_precedence_predicates(operands)
      unless precedence_predicates.empty?
        # interested in the transition with the highest precedence
        reduced = precedence_predicates.max
        operands.add(reduced)
      end

      @opnds = operands.to_s
    end

    def eql?(other)
      return true if self == other
      return false unless other.is_a? OR

      @opnds.eql?(other.opnds)
    end

    def hash
      MurmurHash.hash(@opnds, OR.hash)
    end

    def eval(parser, parser_call_stack)
      @opnds.each do |opnd|
        return true if opnd.eval(parser, parser_call_stack)
      end
      false
    end

    def eval_precedence(parser, parser_call_stack)
      differs = false
      operands = []
      @opnds.each do |context|
        evaluated = context.eval_precedence(parser, parser_call_stack)
        differs |= (evaluated != context)
        if evaluated == NONE
          # The OR context is true if any element is true
          return NONE
        elsif evaluated != null
          # Reduce the result by skipping false elements
          operands.add(evaluated)
        end
      end
      return self unless differs

      if operands.empty?
        # all elements were false, so the OR context is false
        return nil
      end

      result = operands[0]
      i = 1
      while i < operands.size
        result = SemanticContext.or(result, operands.get(i))
        i += 1
      end

      result
    end

    def to_s
      @opnds.join('||')
    end
  end

  def self.and(a, b)
    return b if a.nil? || a == NONE
    return a if b.nil? || b == NONE

    result = AND.new(a, b)
    return result.opnds[0] if result.opnds.length == 1

    result
  end

  def self.or(a, b)
    return b if a.nil?
    return a if b.nil?
    return NONE if a == NONE || b == NONE

    OR result = OR.new(a, b)
    return result.opnds[0] if result.opnds.length == 1

    result
  end

  def self.filter_precedence_predicates(collection)
    result = collection.select { |item| item.is_a? PrecedencePredicate }
    collection.reject! { |item| (item.is_a? PrecedencePredicate) }
    result
  end

  NONE = Predicate.new
end
