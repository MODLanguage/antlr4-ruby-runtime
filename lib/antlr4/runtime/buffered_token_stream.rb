require '../antlr4/token_stream'
require '../antlr4/writable_token'

class BufferedTokenStream < TokenStream
  def initialize(token_source)
    raise NilPointerException, 'token_source cannot be nil' if token_source.nil?

    @token_source = token_source
    @tokens = []
    @ptr = -1
    @fetched_eof = false
  end

  attr_reader :token_source

  def index
    @ptr
  end

  def mark
    0
  end

  def release(marker); end

  def reset
    seek(0)
  end

  def seek(index)
    lazy_init
    @ptr = adjust_seek_index(index)
  end

  def size
    @tokens.length
  end

  def consume
    skip_eof_check = false
    if @ptr >= 0
      if @fetched_eof
        # the last token in tokens is EOF. skip check if p indexes any
        # fetched token except the last.
        skip_eof_check = @ptr < @tokens.length - 1
      else # no EOF token in tokens. skip check if p indexes a fetched token.
        skip_eof_check = @ptr < @tokens.length
      end
    else # not yet initialized
      skip_eof_check = false
    end

    if !skip_eof_check && la(1) == EOF
      raise IllegalStateException, 'cannot consume EOF'
    end

    @ptr = adjust_seek_index(@ptr + 1) if sync(@ptr + 1)
  end

  def sync(i)
    n = i - @tokens.length + 1 # how many more elements we need?

    if n > 0
      fetched = fetch(n)
      return fetched >= n
    end

    true
  end

  def fetch(n)
    return 0 if @fetched_eof

    i = 0
    while i < n
      t = @token_source.next_token
      t.setTokenIndex(@tokens.length) if t.is_a? WritableToken
      @tokens << t
      if t.type == Token::EOF
        @fetched_eof = true
        return i + 1
      end
      i += 1
    end

    n
  end

  def get(i)
    if i < 0 || i >= @tokens.length
      raise IndexOutOfBoundsException, 'token index ' + i + ' out of range 0..' + (@tokens.length - 1)
    end

    @tokens[i]
  end

  def get_list(start, stop)
    return nil if start < 0 || stop < 0

    lazy_init
    subset = []
    stop = @tokens.length - 1 if stop >= @tokens.length
    i = start
    while i <= stop
      t = @tokens[i]
      break if t.type == Token::EOF

      subset.add(t)
      i += 1
    end
    subset
  end

  def la(i)
    lt(i).type
  end

  def lb(k)
    return nil if (@ptr - k) < 0

    @tokens[@ptr - k]
  end

  def lt(k)
    lazy_init
    return nil if k == 0

    return lb(-k) if k < 0

    i = @ptr + k - 1
    sync(i)
    if i >= @tokens.length # return EOF token
      # EOF must be last token
      return @tokens.get(@tokens.length - 1)
    end

    #    if ( i>range ) range = i
    @tokens[i]
  end

  def adjust_seek_index(i)
    i
  end

  def lazy_init
    setup if @ptr == -1
  end

  def setup
    sync(0)
    @ptr = adjust_seek_index(0)
  end

  def token_source(tokenSource)
    @token_source = tokenSource
    @tokens.clear
    @ptr = -1
    @fetched_eof = false
  end

  attr_reader :tokens

  def tokens1(start, stop, types = nil)
    lazy_init
    if start < 0 || stop >= @tokens.length || stop < 0 || start >= @tokens.length

      raise IndexOutOfBoundsException, 'start ' + start + ' or stop ' + stop + ' not in 0..' + (@tokens.length - 1)
    end
    return nil if start > stop

    # list = tokens[start:stop]:T t, t.getType() in typesend
    filtered_tokens = []
    i = start
    while i <= stop
      t = @tokens[i]
      filtered_tokens.add(t) if types.nil? || types.include?(t.type)
      i += 1
    end
    filtered_tokens = nil if filtered_tokens.empty?
    filtered_tokens
  end

  def get_tokens2(start, stop, ttype)
    s = Set.new
    s.add(ttype)
    tokens1(start, stop, s)
  end

  def next_token_on_channel(i, channel)
    sync(i)
    return size - 1 if i >= size

    token = @tokens[i]
    while token.channel != channel
      return i if token.type == Token::EOF

      i += 1
      sync(i)
      token = @tokens[i]
    end

    i
  end

  def previous_token_on_channel(i, channel)
    sync(i)
    if i >= size
      # the EOF token is on every channel
      return size - 1
    end

    while i >= 0
      token = @tokens[i]
      return i if token.type == Token::EOF || token.channel == channel

      i -= 1
    end

    i
  end

  def hidden_tokens_to_right(token_index, channel)
    lazy_init
    if token_index < 0 || token_index >= tokens.size
      raise IndexOutOfBoundsException, token_index + ' not in 0..' + (@tokens.length - 1)
    end

    next_on_channel = next_token_on_channel(token_index + 1, Lexer.DEFAULT_TOKEN_CHANNEL)
    from = token_index + 1
    # if none onchannel to right, next_on_channel=-1 so set to = last token
    to = next_on_channel == -1 ? size - 1 : next_on_channel

    filter_for_channel(from, to, channel)
  end

  def hidden_tokens_to_right2(token_index)
    hidden_tokens_to_right(token_index, -1)
  end

  def hidden_tokens_to_left(token_index, channel)
    lazy_init
    if token_index < 0 || token_index >= tokens.size
      raise IndexOutOfBoundsException, token_index + ' not in 0..' + (@tokens.length - 1)
    end

    if token_index == 0
      # obviously no tokens can appear before the first token
      return nil
    end

    prev_on_channel = previous_token_on_channel(token_index - 1, Lexer.DEFAULT_TOKEN_CHANNEL)
    return nil if prev_on_channel == token_index - 1

    # if none onchannel to left, prev_on_channel=-1 then from=0
    from = prev_on_channel + 1
    to = token_index - 1

    filter_for_channel(from, to, channel)
  end

  def hidden_tokens_to_left1(token_index)
    hidden_tokens_to_left(token_index, -1)
  end

  def filter_for_channel(from, to, channel)
    hidden = []
    i = from
    while i <= to
      t = @tokens[i]
      if channel == -1
        hidden.add(t) if t.channel != Lexer.DEFAULT_TOKEN_CHANNEL
      else
        hidden.add(t) if t.channel == channel
      end
      i += 1
    end
    return nil if hidden.empty?

    hidden
  end

  def source_name
    @token_source.get_source_name
  end

  def text
    text2(Interval.of(0, size - 1))
  end

  def text2(interval)
    start = interval.a
    stop = interval.b
    return '' if start < 0 || stop < 0

    fill
    stop = @tokens.length - 1 if stop >= @tokens.length

    buf = ''
    i = start
    while i <= stop
      t = @tokens[i]
      break if t.type == Token::EOF

      buf << t.text
      buf << i += 1
    end
    buf
  end

  def text3(ctx)
    text2(ctx.source_interval)
  end

  def text4(start, stop)
    if !start.nil? && !stop.nil?
      return text2(Interval.of(start.index, stop.index))
    end

    ''
  end

  def fill
    lazy_init
    block_size = 1000
    loop do
      fetched = fetch(block_size)
      return if fetched < block_size
    end
  end
end
