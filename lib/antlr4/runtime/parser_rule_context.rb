require '../antlr4/rule_context'

class ParserRuleContext < RuleContext
  EMPTY = ParserRuleContext.new

  attr_accessor :children
  attr_accessor :start
  attr_accessor :stop
  attr_accessor :exception

  def copy_from(ctx)
    @parent = ctx.parent
    @invoking_state = ctx.invoking_state

    @start = ctx.start
    @stop = ctx.stop

    # copy any error nodes to alt label node
    unless ctx.children.nil?
      @children = []
      # reset parent pointer for any error nodes
      ctx.children.each do |child|
        addChild(child) if child.is_a ErrorNode
      end
    end
  end

  def initialize(parent = nil, invoking_state_number = nil)
    super(parent, invoking_state_number)
    @children = []
  end

  def enter_rule(_listener)
  end

  def exit_rule(_listener)
  end

  def add_any_child(t)
    @children = [] if @children.nil?
    @children << t
    t
  end

  def add_child_rule_invocation(rule_invocation)
    add_any_child(rule_invocation)
  end

  def add_child_terminal_node(t)
    t.parent = self
    add_any_child(t)
  end

  def add_error_node(error_node)
    error_node.setParent(self)
    add_any_child(error_node)
  end

  def remove_last_child
    @children.delete_at(-1) unless @children.nil?
  end

  def child_at(i)
    !@children.nil? && i >= 0 && i < @children.length ? @children[i] : nil
  end

  def child(ctxType, i)
    return nil if @children.nil? || i < 0 || i >= @children.length

    j = -1 # what element have we found with ctx_type?
    @children.each do |o|
      next unless o.class.name.include? ctxType

      j += 1
      return o if j == i
    end
    nil
  end

  def token(ttype, i)
    return nil if @children.nil? || i < 0 || i >= @children.length

    j = -1 # what token with ttype have we found?
    @children.each do |o|
      next unless o.is_a? TerminalNode

      tnode = o
      symbol = tnode.symbol
      if !symbol.nil? && symbol.type == ttype
        j += 1
        return tnode if j == i
      end
    end

    nil
  end

  def tokens(ttype)
    return [] if @children.nil?

    tokens = nil
    @children.each do |o|
      next unless o.is_a? TerminalNode

      tnode = o
      symbol = tnode.symbol
      if symbol.type == ttype
        tokens = [] if tokens.nil?
        tokens << tnode
      end
    end

    return [] if tokens.nil?

    tokens
  end

  def rule_context(ctx_type, i)
    child(ctx_type, i)
  end

  def rule_contexts(ctxType)
    return [] if @children.nil?

    contexts = nil
    @children.each do |o|
      next unless o.class.name.include? ctxType

      contexts = [] if contexts.nil?

      contexts << o
    end

    return [] if contexts.nil?

    contexts
  end

  def child_count
    !@children.nil? ? @children.length : 0
  end

  def source_interval
    return Interval.INVALID if @start.nil?
    if @stop.nil? || @stop.token_index < @start.token_index
      return Interval.of(@start.token_index, @start.token_index - 1) # empty
    end

    Interval.of(@start.token_index, @stop.token_index)
  end

  def to_info_string(recognizer)
    rules = recognizer.rule_invocation_stack2(self)
    rules.reverse!
    'ParserRuleContext' + rules + '' + 'start=' + @start + ', stop=' + @stop + 'end'
  end
end
