require '../antlr4/char_stream'
require '../antlr4/integer'

class CodePointCharStream < CharStream
  def initialize(position, remaining, name, byte_array)
    @size = remaining
    @name = name
    @position = position
    @byte_array = byte_array
  end

  def text(interval)
    start_idx = [interval.a, @size].min
    len = [interval.b - interval.a + 1, @size - start_idx].min

    # We know the maximum code point in byte_array is U+00FF,
    # so we can treat this as if it were ISO-8859-1, aka Latin-1,
    # which shares the same code points up to 0xFF.
    chars = @byte_array.slice(start_idx, len)
    result = ''
    chars.each do |c|
      result << c
    end
    result
  end

  def la(i)
    case Integer.signum(i)
    when -1
      offset = @position + i
      return IntStream::EOF if offset < 0

      return @byte_array[offset] & 0xFF
    when 0
      # Undefined
      return 0
    when 1
      offset = @position + i - 1
      return IntStream::EOF if offset >= @size

      return @byte_array[offset] & 0xFF
    else
      # type code here
    end
    raise UnsupportedOperationException, 'Not reached'
  end

  def internal_storage
    @byte_array
  end

  def consume
    raise IllegalStateException, 'cannot consume EOF' if (@size - @position).zero?

    @position += 1
  end

  def index
    @position
  end

  attr_reader :size

  def mark
    -1
  end

  def release(marker); end

  def seek(index)
    @position = index
  end

  def source_name
    return UNKNOWN_SOURCE_NAME if @name.nil? || @name.empty?

    @name
  end
end
