require '../antlr4/recognizer'
require '../antlr4/token'
require '../antlr4/common_token_factory'
require '../antlr4/lexer_no_viable_alt_exception'

class Lexer < Recognizer
  DEFAULT_MODE = 0
  MORE = -2
  SKIP = -3

  DEFAULT_TOKEN_CHANNEL = Token::DEFAULT_CHANNEL
  HIDDEN = Token::HIDDEN_CHANNEL
  MIN_CHAR_VALUE = 0x0000
  MAX_CHAR_VALUE = 0x10FFFF

  attr_accessor :_input
  attr_accessor :token
  attr_accessor :_token_start_char_index
  attr_accessor :_token_start_line
  attr_accessor :_token_start_char_position_in_line
  attr_accessor :_hit_eof
  attr_accessor :_channel
  attr_accessor :_type
  attr_accessor :_mode_stack
  attr_accessor :_mode
  attr_accessor :_text

  def reset
    # wack Lexer state variables
    unless @_input.nil?
      @_input.seek(0) # rewind the input
    end
    @_token = nil
    @_type = Token::INVALID_TYPE
    @_channel = Token::DEFAULT_CHANNEL
    @_token_start_char_index = -1
    @_token_start_char_position_in_line = -1
    @_token_start_line = -1
    @_text = nil

    @_hit_eof = false
    @_mode = DEFAULT_MODE
    @_mode_stack.clear

    @_interp.reset unless @_interp.nil?
  end

  def initialize(input = nil)
    super()
    unless input.nil?
      @_input = input
      @_token_factory_source_pair = OpenStruct.new
      @_token_factory_source_pair.a = self
      @_token_factory_source_pair.b = input
    end
    @_mode_stack = []
    reset
    @_factory = CommonTokenFactory.instance
  end

  def next_token
    if @_input.nil?
      raise IllegalStateException, 'nextToken requires a non-nil input stream.'
    end

    # Mark start location in char stream so unbuffered streams are
    # guaranteed at least have text of current token
    token_start_marker = @_input.mark
    begin
      repeat_outer = true
      repeat_outer = next_token_inner while repeat_outer
      return @_token
    ensure # make sure we release marker after match or
      # unbuffered char stream will keep buffering
      @_input.release(token_start_marker)
    end
  end

  def next_token_inner
    loop do
      if @_hit_eof
        emit_eof
        return false
      end

      @_token = nil
      @_channel = Token::DEFAULT_CHANNEL
      @_token_start_char_index = @_input.index
      @_token_start_char_position_in_line = @_interp.char_position_in_line
      @_token_start_line = @_interp.line
      @_text = nil
      loop do
        @_type = Token::INVALID_TYPE

        begin
          ttype = @_interp.match(@_input, @_mode)
        rescue LexerNoViableAltException => e
          notify_listeners(e) # report error
          recover1(e)
          ttype = SKIP
        end
        @_hit_eof = true if @_input.la(1) == IntStream::EOF
        @_type = ttype if @_type == Token::INVALID_TYPE
        return true if @_type == SKIP
        break if @_type != MORE
      end

      emit if @_token.nil?
      return false
    end
  end

  def skip
    @_type = SKIP
  end

  def more
    @_type = MORE
  end

  def mode(m)
    @_mode = m
  end

  def push_mode(m)
    puts('pushMode ' + m) if LexerATNSimulator.debug
    @_mode_stack.push(@_mode)
    mode(m)
  end

  def pop_mode
    raise EmptyStackException if @_mode_stack.empty?

    puts('popMode back to ' + @_mode_stack[-1]) if LexerATNSimulator.debug
    mode(@_mode_stack.pop)
    @_mode
  end

  def input_stream(input)
    @_input = nil
    @_token_factory_source_pair = OpenStruct.new
    @_token_factory_source_pair.a = self
    @_token_factory_source_pair.b = @_input
    reset
    @_input = input
    @_token_factory_source_pair.a = self
    @_token_factory_source_pair.b = @_input
  end

  def source_name
    @_input.get_source_name
  end

  def emit(token = nil)
    if !token.nil?
      @_token = token
    else
      @_token = @_factory.create(@_token_factory_source_pair, @_type, @_text, @_channel, @_token_start_char_index, char_index - 1, @_token_start_line, @_token_start_char_position_in_line)
    end
  end

  def emit_eof
    cpos = char_position_in_line
    eof = @_factory.create(@_token_factory_source_pair, Token::EOF, nil, Token::DEFAULT_CHANNEL, @_input.index, @_input.index - 1, line, cpos)
    emit(eof)
    eof
  end

  def line
    @_interp.line
  end

  def char_position_in_line
    @_interp.char_position_in_line
  end

  def set_line(line)
    @_interp.set_line(line)
  end

  def set_char_position_in_line(char_position_in_line)
    @_interp.set_char_position_in_line(char_position_in_line)
  end

  def char_index
    @_input.index
  end

  def text
    return @_text unless @_text.nil?

    @_interp.text(@_input)
  end

  def all_tokens
    tokens = []
    t = next_token
    while t.type != Token::EOF
      tokens << t
      t = next_token
    end
    tokens
  end

  def recover1(_e)
    if @_input.la(1) != IntStream::EOF
      # skip a char and begin again
      @_interp.consume(@_input)
    end
  end

  def notify_listeners(e)
    text = @_input.text(Interval.of(@_token_start_char_index, @_input.index))
    msg = "token recognition error at: '" + error_display(text) + "'"

    listener = error_listener_dispatch
    listener.syntax_error(self, nil, @_token_start_line, @_token_start_char_position_in_line, msg, e)
  end

  def error_display(s)
    buf = ''
    s.chars.each do |c|
      buf << error_display_char(c)
    end
    buf
  end

  def error_display_char(c)
    s = ''
    s << c
    case c
    when Token::EOF
      s = '<EOF>'
    when '\n'
      s = '\\n'
    when '\t'
      s = '\\t'
    when '\r'
      s = '\\r'
    else
      # type code here
    end
    s
  end

  def char_error_display(c)
    s = error_display_char(c)
    "'" + s + "'"
  end

  def recover2(_re)
    @_input.consume
  end
end
