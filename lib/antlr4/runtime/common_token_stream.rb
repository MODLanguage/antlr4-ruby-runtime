require '../antlr4/buffered_token_stream'
require '../antlr4/token'

class CommonTokenStream < BufferedTokenStream
  def initialize(token_source, channel = nil)
    super(token_source)
    @channel = Token::DEFAULT_CHANNEL
    @channel = channel unless channel.nil?
  end

  def adjust_seek_index(i)
    next_token_on_channel(i, @channel)
  end

  def lb(k)
    return nil if k.zero? || (@ptr - k) < 0

    i = @ptr
    n = 1
    # find k good tokens looking backwards
    while n <= k && i > 0
      # skip off-channel tokens
      i = previous_token_on_channel(i - 1, @channel)
      n += 1
    end
    return nil if i < 0

    @tokens[i]
  end

  def lt(k)
    lazy_init
    return nil if k == 0
    return lb(-k) if k < 0

    i = @ptr
    n = 1 # we know tokens[p] is a good one
    # find k good tokens
    while n < k
      # skip off-channel tokens, but make sure to not look past EOF
      i = next_token_on_channel(i + 1, @channel) if sync(i + 1)
      n += 1
    end
    #    if ( i>range ) range = i
    @tokens[i]
  end

  def number_of_on_channel_tokens
    n = 0
    fill
    i = 0
    while i < @tokens.size
      t = @tokens.get(i)
      n += 1 if t.channel == @channel
      break if t.type == Token::EOF

      i += 1
    end
    n
  end
end
