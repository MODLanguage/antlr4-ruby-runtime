class Trees
  def self.to_s_tree_recog(t, recog = nil)
    rule_names = !recog.nil? ? recog.rule_names : nil
    rule_names_list = !rule_names.nil? ? rule_names : nil
    to_s_tree_rulenames(t, rule_names_list)
  end

  def self.to_s_tree_rulenames(t, rule_names)
    s = Utils.escape_whitespace(getNodeText(t, rule_names), false)
    return s if t.child_count == 0

    buf = ''
    buf << '('
    s = Utils.escape_whitespace(getNodeText(t, rule_names), false)
    buf << s
    buf << ' '
    i = 0
    while i < t.child_count
      buf << ' ' if i > 0
      buf << to_string_tree(t.child(i), rule_names)
      i += 1
    end
    buf << ')'
    buf
  end

  def self.node_text_recog(t, recog)
    rule_names = !recog.nil? ? recog.rule_names : nil
    rule_names_list = !rule_names.nil? ? rule_names : nil
    getNodeText(t, rule_names_list)
  end

  def self.node_text_rulenames(t, rule_names)
    unless rule_names.nil?
      if t.is_a? RuleContext
        rule_index = t.rule_context.rule_index
        rule_name = rule_names[rule_index]
        alt_number = t.alt_number
        if alt_number != ATN::INVALID_ALT_NUMBER
          return rule_name + ':' + alt_number
        end

        return rule_name
      elsif t.is_a? ErrorNode
        return t.to_s
      elsif t.is_a? TerminalNode
        symbol = t.getSymbol
        unless symbol.nil?
          s = symbol.text
          return s
        end
      end
    end
    # no recog for rule names
    payload = t.payload
    return payload.text if payload.is_a Token

    t.payload.to_s
  end

  def self.children(t)
    kids = []
    i = 0
    while i < t.child_count
      kids << t.child(i)
      i += 1
    end

    kids
  end

  def self.ancestors(t)
    return [] if t.get_parent.nil?

    ancestors = []
    t = t.get_parent
    until t.nil?
      ancestors.unshift(t) # insert at start
      t = t.get_parent
    end
    ancestors
  end

  def self.ancestor_of?(t, u)
    return false if t.nil? || u.nil? || t.get_parent.nil?

    p = u.get_parent
    until p.nil?
      return true if t == p

      p = p.get_parent
    end
    false
  end

  def self.find_all_token_nodes(t, ttype)
    find_all_nodes(t, ttype, true)
  end

  def self.find_all_rule_nodes(t, rule_index)
    find_all_nodes(t, rule_index, false)
  end

  def self.find_all_nodes(t, index, find_tokens)
    nodes = []
    _find_all_nodes(t, index, find_tokens, nodes)
    nodes
  end

  def self._find_all_nodes(t, index, find_tokens, nodes)
    # check this node (the root) first
    if find_tokens && t.is_a?(TerminalNode)
      tnode = t
      nodes.add(t) if tnode.getSymbol.type == index
    elsif !find_tokens && t.is_a(ParserRuleContext)
      ctx = t
      nodes.push(t) if ctx.rule_index == index
    end
    # check children
    i = 0
    while i < t.child_count
      _find_all_nodes(t.child(i), index, find_tokens, nodes)
      i += 1
    end
  end

  def self.descendants(t)
    nodes = []
    nodes.push(t)

    n = t.child_count
    i = 0
    while i < n
      nodes.add_all(descendants(t.child(i)))
      i += 1
    end
    nodes
  end

  def self.root_of_subtree_enclosing_region(t, start_token_index, stop_token_index)
    n = t.child_count
    i = 0
    while i < n
      ParseTree child = t.child(i)
      ParserRuleContext r = root_of_subtree_enclosing_region(child, start_token_index, stop_token_index)
      return r unless r.nil?

      i += 1
    end
    if t.is_a? ParserRuleContext
      r = t
      if start_token_index >= r.getStart.token_index && # is range fully contained in t?
         (r.getStop.nil? || stop_token_index <= r.getStop.token_index)

        # note: r.getStop()==nil likely implies that we bailed out of parser and there's nothing to the right
        return r
      end
    end
    nil
  end

  def self.strip_children_out_of_range(t, root, start_index, stop_index)
    return if t.nil?

    i = 0
    while i < t.child_count
      child = t.child(i)
      range = child.source_interval
      next unless child.is_a? ParserRuleContext && (range.b < start_index || range.a > stop_index)

      if ancestor_of?(child, root) # replace only if subtree doesn't have displayed root
        abbrev = CommonToken.new(Token::INVALID_TYPE)
        t.children.set(i, TerminalNodeImpl.new(abbrev))
      end
    end
  end

  def self.find_node_such_that(t, pred)
    return t if pred.test(t)

    return nil if t.nil?

    n = t.child_count
    i = 0
    while i < n
      u = find_node_such_that(t.child(i), pred)
      return u unless u.nil?

      i += 1
    end
    nil
  end
end
