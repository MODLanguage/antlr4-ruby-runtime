require '../antlr4/integer'
require '../antlr4/rule_context'
require '../antlr4/array_prediction_context'

class PredictionContextUtils
  INITIAL_HASH = 1
  EMPTY_RETURN_STATE = Integer::MAX

  def self.from_rule_context(atn, outer_ctx)
    outer_ctx = ParserRuleContext::EMPTY if outer_ctx.nil?

    # if we are in RuleContext of start rule, s, then PredictionContext
    # is EMPTY. Nobody called us. (if we are empty, return empty)
    if outer_ctx.parent.nil? || outer_ctx == ParserRuleContext::EMPTY
      return EmptyPredictionContext::EMPTY
    end

    # If we have a parent, convert it to a PredictionContext graph
    parent = PredictionContextUtils.from_rule_context(atn, outer_ctx.parent)

    state = atn.states[outer_ctx.invoking_state]
    transition = state.transition(0)
    SingletonPredictionContext.new(parent, transition.follow_state.state_number)
  end

  def self.merge(a, b, root_is_wildcard, merge_cache)
    # share same graph if both same
    return a if a == b || a.eql?(b)

    if a.class.name == 'SingletonPredictionContext' && b.class.name == 'SingletonPredictionContext'
      return merge_singletons(a, b, root_is_wildcard, merge_cache)
    end

    # At least one of a or b is array
    # If one is $ and root_is_wildcard, return $ as * wildcard
    if root_is_wildcard
      return a if a.is_a? EmptyPredictionContext
      return b if b.is_a? EmptyPredictionContext
    end

    # convert singleton so both are arrays to normalize
    a = ArrayPredictionContext.new(a) if a.is_a? SingletonPredictionContext
    b = ArrayPredictionContext.new(b) if b.is_a? SingletonPredictionContext
    merge_arrays(a, b, root_is_wildcard, merge_cache)
  end

  def self.merge_singletons(a, b, root_is_wildcard, merge_cache)
    unless merge_cache.nil?
      previous = merge_cache.get2(a, b)
      return previous unless previous.nil?

      previous = merge_cache.get2(b, a)
      return previous unless previous.nil?
    end

    root_merge = merge_root(a, b, root_is_wildcard)
    unless root_merge.nil?
      merge_cache.put(a, b, root_merge) unless merge_cache.nil?
      return root_merge
    end

    if a.return_state == b.return_state # a == b
      parent = merge(a.parent, b.parent, root_is_wildcard, merge_cache)
      # if parent is same as existing a or b parent or reduced to a parent, return it
      if parent == a.parent
        return a # ax + bx = ax, if a=b
      end
      if parent == b.parent
        return b # ax + bx = bx, if a=b
      end

      # else: ax + ay = a'[x,y]
      # merge parents x and y, giving array node with x,y then remainders
      # of those graphs.  dup a, a' points at merged array
      # new joined parent so create new singleton pointing to it, a'
      a_ = SingletonPredictionContext.new(parent, a.return_state)
      merge_cache.put(a, b, a_) unless merge_cache.nil?
      return a_
    else # a != b payloads differ
      # see if we can collapse parents due to $+x parents if local ctx
      single_parent = nil
      if a == b || (!a.parent.nil? && a.parent.eql?(b.parent)) # ax + bx = [a,b]x
        single_parent = a.parent
      end
      unless single_parent.nil? # parents are same
        # sort payloads and use same parent
        payloads = [a.return_state, b.return_state]
        if a.return_state > b.return_state
          payloads[0] = b.return_state
          payloads[1] = a.return_state
        end
        parents = [single_parent, single_parent]
        a_ = ArrayPredictionContext.new(parents, payloads)
        merge_cache.put(a, b, a_) unless merge_cache.nil?
        return a_
      end
      # parents differ and can't merge them. Just pack together
      # into array can't merge.
      # ax + by = [ax,by]
      payloads = [a.return_state, b.return_state]
      parents = [a.parent, b.parent]
      if a.return_state > b.return_state # sort by payload
        payloads[0] = b.return_state
        payloads[1] = a.return_state
        parents = [b.parent, a.parent]
      end
      a_ = ArrayPredictionContext.new(parents, payloads)
      merge_cache.put(a, b, a_) unless merge_cache.nil?
      return a_
    end
  end

  def self.merge_root(a, b, root_is_wildcard)
    if root_is_wildcard
      if a.return_state == EMPTY_RETURN_STATE
        return EmptyPredictionContext::EMPTY # * + b = *
      end
      if b.return_state == EMPTY_RETURN_STATE
        return EmptyPredictionContext::EMPTY # a + * = *
      end
    else
      if a.return_state == EMPTY_RETURN_STATE && b.return_state == EMPTY_RETURN_STATE
        return EmptyPredictionContext::EMPTY # $ + $ = $
      end

      if a.return_state == EMPTY_RETURN_STATE # $ + x = [x,$]
        payloads = [b.return_state, EMPTY_RETURN_STATE]
        parents = [b.parent, nil]
        joined = ArrayPredictionContext.new(parents, payloads)
        return joined
      end
      if b.return_state == EMPTY_RETURN_STATE # x + $ = [x,$] ($ is always last if present)
        payloads = [a.return_state, EMPTY_RETURN_STATE]
        parents = [a.parent, nil]
        joined = ArrayPredictionContext.new(parents, payloads)
        return joined
      end
    end
    nil
  end

  def self.merge_arrays(a, b, root_is_wildcard, merge_cache)
    unless merge_cache.nil?
      previous = merge_cache.get2(a, b)
      return previous unless previous.nil?

      previous = merge_cache.get2(b, a)
      return previous unless previous.nil?
    end

    # merge sorted payloads a + b => M
    i = 0 # walks a
    j = 0 # walks b
    k = 0 # walks target M array

    merged_return_states = []
    merged_parents = []
    # walk and merge to yield merged_parents, merged_return_states
    while i < a.return_states.length && j < b.return_states.length
      a_parent = a.parents[i]
      b_parent = b.parents[j]
      if a.return_states[i] == b.return_states[j]
        # same payload (stack tops are equal), must yield merged singleton
        payload = a.return_states[i]
        # $+$ = $
        both = payload == EMPTY_RETURN_STATE && a_parent.nil? && b_parent.nil?
        ax_ax = (!a_parent.nil? && !b_parent.nil?) && a_parent.eql?(b_parent) # ax+ax -> ax
        if both || ax_ax
          merged_parents[k] = a_parent # choose left
          merged_return_states[k] = payload
        else # ax+ay -> a'[x,y]
          merged_parent = merge(a_parent, b_parent, root_is_wildcard, merge_cache)
          merged_parents[k] = merged_parent
          merged_return_states[k] = payload
        end
        i += 1 # hop over left one as usual
        j += 1 # but also skip one in right side since we merge
      elsif a.return_states[i] < b.return_states[j] # copy a[i] to M
        merged_parents[k] = a_parent
        merged_return_states[k] = a.return_states[i]
        i += 1
      else # b > a, copy b[j] to M
        merged_parents[k] = b_parent
        merged_return_states[k] = b.return_states[j]
        j += 1
      end

      k += 1
    end

    # copy over any payloads remaining in either array
    if i < a.return_states.length
      p = i
      while p < a.return_states.length
        merged_parents[k] = a.parents[p]
        merged_return_states[k] = a.return_states[p]
        k += 1
        p += 1
      end
    else
      p = j
      while p < b.return_states.length
        merged_parents[k] = b.parents[p]
        merged_return_states[k] = b.return_states[p]
        k += 1
        p += 1
      end
    end

    # trim merged if we combined a few that had same stack tops
    if k < merged_parents.length # write index < last position trim
      if k == 1 # for just one merged element, return singleton top
        a_ = SingletonPredictionContext.create(merged_parents[0], merged_return_states[0])
        merge_cache.put(a, b, a_) unless merge_cache.nil?
        return a_
      end
    end

    m = ArrayPredictionContext.new(merged_parents, merged_return_states)

    # if we created same array as a or b, return that instead
    # TODO: track whether this is possible above during merge sort for speed
    if m.equals(a)
      merge_cache.put(a, b, a) unless merge_cache.nil?
      return a
    end
    if m.equals(b)
      merge_cache.put(a, b, b) unless merge_cache.nil?
      return b
    end

    combine_common_parents(merged_parents)

    merge_cache.put(a, b, m) unless merge_cache.nil?
    m
  end

  def self.combine_common_parents(parents)
    unique_parents = {}

    p = 0
    while p < parents.length
      parent = parents[p]
      unique_parents[parent] = parent unless unique_parents.key?(parent) # don't replace
      p += 1
    end

    p = 0
    while p < parents.length
      parents[p] = unique_parents[parents[p]]
      p += 1
    end
  end

  def self.to_dot_string(context)
    return '' if context.nil?

    buf = ''
    buf << "digraph G \n"
    buf << "rankdir=LR\n"

    nodes = all_context_nodes(context)
    nodes.sort {|a, b| a.id - b.id}

    nodes.each do |current|
      if current.is_a? SingletonPredictionContext
        s = current.id.to_s
        buf << '  s' << s
        return_state = current.get_return_state(0).to_s
        return_state = '$' if current.is_a? EmptyPredictionContext
        buf << ' [label="' << return_state << "\"]\n"
        next
      end
      arr = current
      buf << '  s' << arr.id
      buf << ' [shape=box, label="'
      buf << '['
      first = true
      arr.return_states.each do |inv|
        buf << ', ' unless first
        buf << if inv == EMPTY_RETURN_STATE
                 '$'
               else
                 inv
               end
        first = false
      end
      buf << ']'
      buf << "\"]\n"
    end

    nodes.each do |current|
      next if current == EMPTY

      i = 0
      while i < current.size
        if current.get_parent(i).nil?
          i += 1
          next
        end
        String s = String.valueOf(current.id)
        buf << '  s' << s
        buf << '->'
        buf << 's'
        buf << current.get_parent(i).id
        buf << if current.size > 1
                 ' [label="parent[' + i + "]\"]\n"
               else
                 "\n"
               end
        i += 1
      end
    end

    buf << "end\n"
    buf
  end

  def self.cached_context(context, context_cache, visited)
    return context if context.empty?

    existing = visited[context]
    return existing unless existing.nil?

    existing = context_cache.get(context)
    unless existing.nil?
      visited[context] = existing
      return existing
    end

    changed = false
    parents = []
    i = 0
    while i < parents.length
      parent = cached_context(context.get_parent(i), context_cache, visited)
      if changed || parent != context.get_parent(i)
        unless changed
          parents = []
          j = 0
          while j < context.size
            parents[j] = context.get_parent(j)
            j += 1
          end
          changed = true
        end
        parents[i] = parent
      end
      i += 1
    end

    unless changed
      context_cache.add(context)
      visited[context] = context
      return context
    end

    if parents.empty?
      updated = EMPTY
    elsif parents.length == 1
      updated = SingletonPredictionContext.create(parents[0], context.get_return_state(0))
    else
      array_pred_ctx = context
      updated = ArrayPredictionContext.new(parents, array_pred_ctx.return_states)
    end

    context_cache.add(updated)
    visited[updated] = updated
    visited[context] = updated

    updated
  end

  def self.all_context_nodes(context)
    nodes = []
    visited = {}
    all_context_nodes_(context, nodes, visited)
    nodes
  end

  def self.all_context_nodes_(context, nodes, visited)
    return if context.nil? || visited.key?(context)

    visited[context] = context
    nodes.add(context)
    i = 0
    while i < context.size
      all_context_nodes_(context.get_parent(i), nodes, visited)
      i += 1
    end
  end

  def self.calculate_empty_hash_code
    hash = INITIAL_HASH
    MurmurHash.finish(hash, 0)
  end

  def self.calculate_hash_code1(parent, return_state)
    hash = INITIAL_HASH
    hash = MurmurHash.update_obj(hash, parent)
    hash = MurmurHash.update_int(hash, return_state)
    MurmurHash.finish(hash, 2)
  end

  def self.calculate_hash_code2(parents, return_states)
    hash = INITIAL_HASH

    parents.each do |parent|
      hash = MurmurHash.update_obj(hash, parent)
    end

    return_states.each do |returnState|
      hash = MurmurHash.update_int(hash, returnState)
    end

    MurmurHash.finish(hash, 2 * parents.length)
  end
end
