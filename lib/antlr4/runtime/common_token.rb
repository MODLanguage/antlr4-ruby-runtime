require 'ostruct'
require '../antlr4/token'

class CommonToken
  EMPTY_SOURCE = OpenStruct.new

  attr_accessor :type
  attr_accessor :line
  attr_accessor :char_position_in_line
  attr_accessor :channel
  attr_accessor :source
  attr_accessor :index
  attr_accessor :start
  attr_accessor :stop

  def initialize(type = nil)
    @char_position_in_line = -1
    @channel = Token::DEFAULT_CHANNEL
    @index = -1
    @type = type
    @source = EMPTY_SOURCE
    @text = nil
  end

  def self.create1(source, type, channel, start, stop)
    result = CommonToken.new(type)
    result.source = source
    result.channel = channel
    result.start = start
    result.stop = stop
    unless source.a.nil?
      result.line = source.a.line
      result.char_position_in_line = source.a.char_position_in_line
    end
    result
  end

  def self.create2(type, text)
    result = CommonToken.new(type)
    result.text = text
    result
  end

  def create3(old_token)
    result = CommonToken.new(old_token.type)

    result.line = old_token.line
    result.index = old_token.token_index
    result.char_position_in_line = old_token.char_position_in_line
    result.channel = old_token.channel
    result.start = old_token.start_index
    result.stop = old_token.stop_index

    if old_token.is_a? CommonToken
      result.text = old_token.text
      result.source = old_token.source
    else
      result.text = old_token.text
      result.source = OpenStruct.new
      result.source.a = old_token.token_source
      result.source.b = old_token.input_stream
    end
    result
  end

  def input_stream
    @source.b
  end

  def text
    return @text unless @text.nil?

    input = input_stream
    return nil if input.nil?

    n = input.size
    if @start < n && @stop < n
      input.text(Interval.of(@start, @stop))
    else
      '<EOF>'
    end
  end

  def to_s_recog(r = nil)
    channel_str = ''
    channel_str = ',channel=' + @channel.to_s if @channel > 0
    txt = text
    if !txt.nil?
      txt = txt.sub("\n", '\\n')
      txt = txt.sub("\r", '\\r')
      txt = txt.sub("\t", '\\t')
    else
      txt = '<no text>'
    end

    type_string = type.to_s
    type_string = r.get_vocabulary.display_name(@type) unless r.nil?
    '[@' << token_index.to_s << ',' << @start.to_s << ':' << @stop.to_s << "='" << txt << "',<" << type_string << '>' << channel_str << ',' << @line.to_s << ':' << char_position_in_line.to_s << ']'
  end

  def to_s
    '[@ ' << @start.to_s << ':' << @stop.to_s << ',' << @line.to_s << ':' << ']'
  end

  def to_s_old
    channel_str = ''
    channel_str = ',channel=' + @channel.to_s if @channel > 0
    txt = text
    if !txt.nil?
      txt = txt.sub("\n", '\\n')
      txt = txt.sub("\r", '\\r')
      txt = txt.sub("\t", '\\t')
    else
      txt = '<no text>'
    end

    type_string = type.to_s

    '[@' << token_index.to_s << ',' << @start.to_s << ':' << @stop.to_s << "='" << txt << "',<" << type_string << '>' << channel_str << ',' << @line.to_s << ':' << char_position_in_line.to_s << ']'
  end
end
