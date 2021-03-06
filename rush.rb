# Rush (= Ruby Scheme Interpreter)

require 'pry'

# main function
def interpreter
  loop do
    print 'rush >> '
    input = gets

    # when "(quit)" or "(exit)" is input, break lopp
    break if %w[(quit)\n (exit)\n].include? input

    print '-> ', evaluate(parse(input)), "\n" unless evaluate(parse(input)).nil?
  end
  print "-> bye...\n"
end

# tokenize & parse input
def parse(raw_string)
  # read_tokens_only tokenize(s)
  read_tokens before_read(tokenize(raw_string))
end

# separate input words
def tokenize(raw_string)
  raw_string.gsub(/[()]/, ' \0 ').split
end

# convert tokens into structured Array
# def read_tokens(tokens)
#   raise SyntaxError, 'unexpected EOF while reading' if tokens.length == 0

#   case token = tokens.shift
#   when '('
#     l = []
#     while tokens[0] != ')'
#       l.push read_tokens(tokens)
#     end
#     tokens.shift
#     l
#   when ')'
#     raise SyntaxError, 'unexpected ")"'
#   else
#     atom token
#   end
# end

# try to allow pending in tokenize & make structured tree process
#
# rush >> (+ 10
#  ... >> 15)
# -> 25
# def re_read_tokens(tokens)
#   tokens = pend_input if tokens.length == 0

#   case token = tokens.shift
#   when '('
#     l = []
#     while tokens[0] != ')'
#       l.push re_read_tokens(tokens)
#     end
#     tokens.shift
#     l
#   when ')'
#     raise SyntaxError, 'unexpected ")"'
#   else
#     atom token
#   end
# end

# def read_tokens_with_analysis(tokens)
#   level = static_analysis(tokens)

#   while level != 0
#     added_tokens = pend_input
#     level = static_analysis(added_tokens, level)

#     added_tokens.each do |added_token|
#       tokens.push added_token
#     end
#   end

#   case token = tokens.shift
#   when '('
#     l = []
#     while tokens[0] != ')'
#       l.push read_tokens_deep(tokens)
#     end
#     tokens.shift
#     l
#   when ')'
#     raise SyntaxError, 'unexpected ")"'
#   else
#     atom token
#   end
# end

def read_tokens(tokens)
  case token = tokens.shift
  when '('
    l = []
    l.push read_tokens(tokens) while tokens[0] != ')'
    tokens.shift
    l
  when ')'
    raise SyntaxError, 'unexpected ")"'
  else
    atom token
  end
end

def before_read(tokens)
  level = static_analysis(tokens)

  while level != 0
    added_tokens = pend_input
    level = static_analysis(added_tokens, level)

    added_tokens.each do |added_token|
      tokens.push added_token
    end
  end

  tokens
end

# def read_tokens_deep(tokens)
#   case token = tokens.shift
#   when '('
#     l = []
#     while tokens[0] != ')'
#       l.push read_tokens_deep(tokens)
#     end
#     tokens.shift
#     l
#   when ')'
#     raise SyntaxError, 'unexpected ")"'
#   else
#     atom token
#   end
# end

def static_analysis(code_tokens, level = 0)
  code_tokens.each do |token|
    case token
    when '('
      level += 1
    when ')'
      level -= 1
    end
  end

  raise SyntaxError, 'unexpected ")"' if level < 0

  level
end

def pend_input
  print ' ... >> '
  input = gets

  tokenize input
end

# type casting
def atom(token)
  type_casts = [
    ->(arg) { Integer arg },
    ->(arg) { Float arg },
    ->(arg) { arg.to_sym }
  ]

  begin
    type_casts.first.call(token)
  rescue ArgumentError
    # remove first element of type_casts
    # and retry this method
    type_casts.shift
    retry
  end
end

# evaluation
def evaluate(x, env=$GLOBAL_ENV)
  case x
  when Symbol
    # look for $GLOBAL_ENV hash type data
    # and it would find accurate Proc object
    env.find(x)[x]
  when Array
    case x.first
    when :quote
      _, expr = x
      expr
    when :if
      _, cond, if_t, if_f = x
      evaluate((evaluate(cond, env) ? if_t : if_f), env)
    when :define
      _, var, expr = x
      env[var] = evaluate(expr, env)
      nil
    when :set!
      _, var, expr = x
      env.find(var)[var] = evaluate(expr, env)
    when :lambda
      _, vars, expr = x
      ->(*args) { evaluate(expr, Env.new(vars, args, env)) }
    else
      # evaluate recursively
      process, *exps = x.inject([]) { |mem, exp| mem << evaluate(exp, env) }

      # evaluation
      process[*exps]
    end
  else
    x
  end
end

# this class express which scope program is in
class Env < Hash
  def initialize(params = [], args = [], outer = nil)
    hash = Hash[params.zip(args)]
    merge!(hash)

    @outer = outer
  end

  def find(key)
    key?(key) ? self : @outer.find(key)
  end
end

def make_global_env(env)
  env.merge!(
    :+ => ->(x, y) { x + y },
    :- => ->(x, y) { x - y },
    :* => ->(x, y) { x * y },
    :/ => ->(x, y) { x / y },
    :not => ->(x) { !x },
    :< => ->(x, y) { x < y },
    :> => ->(x, y) { x > y },
    :<= => ->(x, y) { x <= y },
    :>= => ->(x, y) { x >= y },
    :"=" => ->(x, y) { x == y },
    :cons => ->(x, y) { [x, y] },
    :car => ->(x) { x[0] },
    :cdr => ->(x) { x[1..-1] },
    :list => ->(*x) { [*x] },
    :list? => ->(x) { x.is_a?(Array) },
    :null? => ->(x) { x.empty? },
    :symbol? => ->(x) { x.is_a?(Symbol) }
  )
end

# just for test function
def interpret_once(str)
  evaluate(parse(str))
end

# Define Global env
$GLOBAL_ENV = make_global_env(Env.new)

if $PROGRAM_NAME == __FILE__
  interpreter
end
