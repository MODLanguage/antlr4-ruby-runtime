require '../antlr4/rule_node'
require '../antlr4/interval'
require '../antlr4/atn'
require '../antlr4/trees'

class RuleContext < RuleNode
  attr_accessor :parent
  attr_accessor :invoking_state

  def initialize(parent = nil, invoking_state = nil)
    @invoking_state = -1
    @parent = parent
    @invoking_state = invoking_state
  end

  def depth
    n = 0
    p = self
    until p.nil?
      p = p.parent
      n += 1
    end
    n
  end

  def empty?
    @invoking_state == -1
  end

  # satisfy the ParseTree / SyntaxTree interface

  def source_interval
    Interval.INVALID
  end

  def rule_context
    self
  end

  def payload
    self
  end

  def set_alt_number(_num)
  end

  def text
    return '' if child_count == 0

    builder = ''
    i = 0
    while i < child_count
      builder << child(i).text
      i += 1
    end

    builder.to_s
  end

  def rule_index
    -1
  end

  def alt_number
    ATN::INVALID_ALT_NUMBER
  end

  def child(_i)
    nil
  end

  def child_count
    0
  end

  def accept(visitor)
    visitor.visit_children(self)
  end

  def to_string_tree_recog(recog)
    Trees.to_sTree(self, recog)
  end

  def to_string_tree_rulenames(rule_names)
    Trees.to_sTree(self, rule_names)
  end

  def to_string_tree
    to_string_tree_rulenames(nil)
  end

  def to_s
    to_s_recog_ctx(nil, nil)
  end

  def to_s_recog(recog)
    to_s_recog_ctx(recog, ParserRuleContext::EMPTY)
  end

  def to_s_list(rule_names)
    to_s_list_ctx(rule_names, nil)
  end

  def to_s_recog_ctx(recog, stop)
    rule_names = !recog.nil? ? recog.rule_names : nil
    rule_names_list = !rule_names.nil? ? rule_names : nil
    to_s_list_ctx(rule_names_list, stop)
  end

  def to_s_list_ctx(rule_names, stop)
    buf = ''
    p = self
    buf << '['
    while !p.nil? && p != stop
      if rule_names.nil?
        buf << p.invoking_state unless p.empty?
      else
        rule_index = p.rule_index
        rule_name = rule_index >= 0 && rule_index < rule_names.size ? rule_names[rule_index] : rule_index
        buf << rule_name.to_s
      end

      buf << ' ' if !p.parent.nil? && (!rule_names.nil? || !p.parent.empty?)

      p = p.parent
    end

    buf << ']'
    buf
  end
end
