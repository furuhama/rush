# Rush (= Ruby Scheme Interpreter)

# main function
def interpreter
  loop do
    print 'rush >> '
    input = gets

    # when "quit" is input, break lopp
    break if input == "(quit)\n" || input == "(exit)\n"

    print '-> ', evaluate(parse(input)), "\n" unless evaluate(parse(input)).nil?
  end
  print "-> bye...\n"
end

# tokenize & parse input
def read(s)
  read_tokens tokenize(s)
end
alias :parse :read

# separate input words
def tokenize(s)
  s.gsub(/[()]/, ' \0 ').split
end

# convert tokens into structured Array
def read_tokens(tokens)
  raise SyntaxError, 'unexpected EOF while reading' if tokens.length == 0

  case token = tokens.shift
  when '('
    l = []
    while tokens[0] != ')'
      l.push read_tokens(tokens)
    end
    tokens.shift
    l
  when ')'
    raise SyntaxError, 'unexpected ")"'
  else
    atom token
  end
end

# try to allow pending in tokenize & make structured tree process
#
# rush >> (+ 10
#  ... >> 15)
# -> 25
def re_read_tokens(tokens)
  if tokens.length == 0
    pend_input.each do |token|
      tokens << token
    end
  end

  case token = tokens.shift
  when '('
    l = []
    while tokens[0] != ')'
      l.push re_read_tokens(tokens)
    end
    tokens.shift
    l
  when ')'
    raise SyntaxError, 'unexpected ")"'
  else
    atom token
  end
end

def pend_input
  print ' ... >> '
  input = gets

  tokenize input
end

# type casting
def atom(token)
  type_casts = [
    lambda { |arg| Integer arg },
    lambda { |arg| Float arg },
    lambda { |arg| arg.to_sym },
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
      lambda { |*args| evaluate(expr, Env.new(vars, args, env)) }
    else
      # evaluate recursively
      process, *exps = x.inject([]) {|mem, exp| mem << evaluate(exp, env) }

      # evaluation
      process[*exps]
    end
  else
    x
  end
end

# this class express which scope program is in
class Env < Hash
  def initialize(params=[], args=[], outer=nil)
    hash = Hash[params.zip(args)]
    self.merge!(hash)

    @outer = outer
  end

  def find(key)
    self.has_key?(key) ? self : @outer.find(key)
  end
end

def make_global_env(env)
  env.merge!({
  :+ => lambda {|x, y| x + y },
  :- => lambda {|x, y| x - y },
  :* => lambda {|x, y| x * y },
  :/ => lambda {|x, y| x / y },
  :not => lambda {|x| !x },
  :< => lambda {|x, y| x < y },
  :> => lambda {|x, y| x > y },
  :<= => lambda {|x, y| x <= y },
  :>= => lambda {|x, y| x >= y },
  :"=" => lambda {|x, y| x == y },
  :cons => lambda {|x, y| [x, y] },
  :car => lambda {|x| x[0] },
  :cdr => lambda {|x| x[1..-1] },
  :list => lambda {|*x| [*x] },
  :list? => lambda {|x| x.is_a?(Array) },
  :null? => lambda {|x| x.empty? },
  :symbol? => lambda {|x| x.is_a?(Symbol) },
  })
end

# just for test function
def interpret_once(s)
  evaluate(parse(s))
end

# Define Global env
$GLOBAL_ENV = make_global_env(Env.new)

if __FILE__ == $0
  interpreter
end
