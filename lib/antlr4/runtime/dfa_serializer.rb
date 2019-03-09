require '../antlr4/integer'

class DFASerializer
  def init_from_token_names(dfa, token_names)
    init_from_vocabulary(dfa, VocabularyImpl.from_token_names(token_names))
  end

  def init_from_vocabulary(dfa, vocabulary)
    @dfa = dfa
    @vocabulary = vocabulary
  end

  def to_s
    return nil if @dfa.s0.nil?

    buf = ''
    states = @dfa.get_states
    states.each do |s|
      n = 0
      n = s.edges.length unless s.edges.nil?
      i = 0
      while i < n
        t = s.edges[i]
        if !t.nil? && t.state_number != Integer::MAX
          buf << state_string(s)
          label = edge_label(i)
          buf << '-' << label << '->' << state_string(t) << '\n'
        end
        i += 1
      end
    end

    output = buf
    return '' if output.empty?

    # return Utils.sortLinesInString(output)
    output
  end

  def edge_label(i)
    @vocabulary.display_name(i - 1)
  end

  def state_string(s)
    n = s.state_number
    base_state_str = (s.is_accept_state ? ':' : '') << 's' << n.to_s << (s.requires_full_context ? '^' : '')
    if s.is_accept_state
      if !s.predicates.nil?
        preds = ''
        s.predicates.each do |p|
          preds << p.to_s
        end

        return base_state_str << '=>' << preds
      else
        return base_state_str << '=>' << @vocabulary.symbolic_name(s.prediction)
      end
    end
    base_state_str
  end
end
