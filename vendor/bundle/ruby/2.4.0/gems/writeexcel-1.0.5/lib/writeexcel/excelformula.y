#
# copyright (c) 2009, 2010  Hideo Nakamura, cxn03651@msj.biglobe.ne.jp


class ExcelFormulaParser

prechigh
  nonassoc UMINUS
  right    '^'
  left     '&'
  left     '*' '/'
  left     '+' '-'
  left     '<' '>' '<=' '>=' '<>'
  left     '='
preclow

rule

  formula      : expr_list

  expr_list    :                      { result = [] }
               | expr_list expr EOL   { result.push val[1], '_arg', '1' }
               | expr_list EOL

  expr         : expr '+' expr        { result = [ val[0], val[2], 'ptgAdd' ] }
               | expr '-' expr        { result = [ val[0], val[2], 'ptgSub' ] }
               | expr '*' expr        { result = [ val[0], val[2], 'ptgMul' ] }
               | expr '/' expr        { result = [ val[0], val[2], 'ptgDiv' ] }
               | expr '^' expr        { result = [ val[0], val[2], 'ptgPower' ] }
               | expr '&' expr        { result = [ val[0], val[2], 'ptgConcat' ] }
               | expr LT  expr        { result = [ val[0], val[2], 'ptgLT' ] }
               | expr GT  expr        { result = [ val[0], val[2], 'ptgGT' ] }
               | expr LE  expr        { result = [ val[0], val[2], 'ptgLE' ] }
               | expr GE  expr        { result = [ val[0], val[2], 'ptgGE' ] }
               | expr NE  expr        { result = [ val[0], val[2], 'ptgNE' ] }
               | expr '=' expr        { result = [ val[0], val[2], 'ptgEQ' ] }
               | primary

  primary      : '(' expr ')'         { result = [ val[1], '_arg', '1', 'ptgParen'] }
               | '-' expr  = UMINUS   { result = [ '_num', '-1', val[1], 'ptgMul' ] }
               | FUNC
               | NUMBER               { result = [ '_num',     val[0] ] }
               | STRING               { result = [ '_str',     val[0] ] }
               | REF2D                { result = [ '_ref2d',   val[0] ] }
               | REF3D                { result = [ '_ref3d',   val[0] ] }
               | RANGE2D              { result = [ '_range2d', val[0] ] }
               | RANGE3D              { result = [ '_range3d', val[0] ] }
               | NAME                 { result = [ '_name',    val[0] ] }
               | TRUE                 { result = [ 'ptgBool',  '1'    ] }
               | FALSE                { result = [ 'ptgBool',  '0'    ] }
               | funcall

  funcall      : FUNC '(' args ')'    { result = [ '_class', val[0], val[2], '_arg', val[2].size.to_s, '_func', val[0] ] }
               | FUNC '(' ')'         { result = [ '_func', val[0] ] }

  args         : expr                 { result = val }
               | args ',' expr        { result.push val[2] }

end


---- footer

class ExcelFormulaParserError < StandardError; end

module Writeexcel

   class Node
   
      def exec_list(nodes)
         v = nil
         nodes.each { |i| v = i.evaluate }
         v
      end
   
      def excelformulaparser_error(msg)
         raise ExcelFormulaParserError,
                  "in #{fname}:#{lineno}: #{msg}"
      end
   
   end
   
   class RootNode < Node
   
      def initialize(tree)
         @tree = tree
      end
   
      def evaluate
         exec_list @tree
      end
   
   end
   
   
   class FuncallNode < Node
   
      def initialize(func, args)
         @func = func
         @args = args
      end
   
      def evaluate
         arg = @args.collect {|i| i.evaluate }
         out = []
         arg.each { |i| o.push i }
         o.push @func
         p o
      end
   
   end
   
   class NumberNode < Node
   
      def initialize(val)
         @val = val
      end
   
      def evaluate
         p @val
      end
   
   end
   
   class OperateNode < Node
   
      def initialize(op, left, right)
         @op = op
         @left = left
         @right = right
      end
   
      def evaluate
         o = []
         o.push @left
         o.push @right
         o.push @op
         p o
      end
   end
end

