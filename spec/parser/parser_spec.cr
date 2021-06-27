require "spec"
require "../../src/parser/parser.cr"
require "../../src/parser/lexer.cr"

include FayrantLang

describe "FayrantLang Parser" do
  it "should parse '2 + 3 / 4;'" do
    tokens = Lexer.new("2 + 3 / 4;").scan_tokens
    result = Parser.new(tokens).parse_program[0].as(ExprStatement).expr
    expected = BinaryExprPlus.new(
      NumberLiteralExpr.new(2),
      BinaryExprDiv.new(
        NumberLiteralExpr.new(3),
        NumberLiteralExpr.new(4)
      )
    )
    result.should eq expected
  end

  it "should parse '(2 + 3) / 4;'" do
    tokens = Lexer.new("(2 + 3) / 4;").scan_tokens
    result = Parser.new(tokens).parse_program[0].as(ExprStatement).expr
    expected = BinaryExprDiv.new(
      BinaryExprPlus.new(
        NumberLiteralExpr.new(2),
        NumberLiteralExpr.new(3)),
      NumberLiteralExpr.new(4)
    )
    result.should eq expected
  end

  it "should parse '0xC0DE + 0b1010;'" do
    tokens = Lexer.new("0xC0DE + 0b1010;").scan_tokens
    result = Parser.new(tokens).parse_program[0].as(ExprStatement).expr
    expected = BinaryExprPlus.new(
      NumberLiteralExpr.new(49374),
      NumberLiteralExpr.new(10)
    )
    result.should eq expected
  end

  it "should parse '2 + @#!-7;'" do
    tokens = Lexer.new("2 + @#!-7;").scan_tokens
    result = Parser.new(tokens).parse_program[0].as(ExprStatement).expr
    expected =
      BinaryExprPlus.new(
        NumberLiteralExpr.new(2),
        UnaryExprToString.new(
          UnaryExprToNumber.new(
            UnaryExprNegation.new(
              UnaryExprMinus.new(
                NumberLiteralExpr.new(7),
              )
            )
          )
        )
      )
    result.should eq expected
  end

  it "should parse '1 \\ 2 / 3 \\ 4;'" do
    tokens = Lexer.new("1 \\ 2 / 3 \\ 4;").scan_tokens
    result = Parser.new(tokens).parse_program[0].as(ExprStatement).expr
    expected = BinaryExprDivInv.new(
      NumberLiteralExpr.new(1),
      BinaryExprDivInv.new(
        BinaryExprDiv.new(
          NumberLiteralExpr.new(2),
          NumberLiteralExpr.new(3)
        ),
        NumberLiteralExpr.new(4)
      )
    )
    result.should eq expected
  end

  it "should parse '1 & 2 | 3 | 4 & 5;'" do
    tokens = Lexer.new("1 & 2 | 3 | 4 & 5;").scan_tokens
    result = Parser.new(tokens).parse_program[0].as(ExprStatement).expr
    expected = BinaryExprOr.new(
      BinaryExprOr.new(
        BinaryExprAnd.new(NumberLiteralExpr.new(1), NumberLiteralExpr.new(2)),
        NumberLiteralExpr.new(3),
      ),
      BinaryExprAnd.new(NumberLiteralExpr.new(4), NumberLiteralExpr.new(5)),
    )
    result.should eq expected
  end

  it "should parse '1 > 2 | 3 <= 4;'" do
    tokens = Lexer.new("1 > 2 | 3 <= 4;").scan_tokens
    result = Parser.new(tokens).parse_program[0].as(ExprStatement).expr
    expected = BinaryExprOr.new(
      BinaryExprGt.new(NumberLiteralExpr.new(1), NumberLiteralExpr.new(2)),
      BinaryExprLe.new(NumberLiteralExpr.new(3), NumberLiteralExpr.new(4)),
    )
    result.should eq expected
  end

  it "should parse '1 ++ 2 ++ 3;'" do
    tokens = Lexer.new("1 ++ 2 ++ 3;").scan_tokens
    result = Parser.new(tokens).parse_program[0].as(ExprStatement).expr
    expected = BinaryExprConcat.new(
      BinaryExprConcat.new(NumberLiteralExpr.new(1), NumberLiteralExpr.new(2)),
      NumberLiteralExpr.new(3),
    )
    result.should eq expected
  end

  it "should parse '2 ^ 3 ^ 4;'" do
    tokens = Lexer.new("2 ^ 3 ^ 4;").scan_tokens
    result = Parser.new(tokens).parse_program[0].as(ExprStatement).expr
    expected = BinaryExprExpt.new(
      NumberLiteralExpr.new(2),
      BinaryExprExpt.new(NumberLiteralExpr.new(3), NumberLiteralExpr.new(4)),
    )
    result.should eq expected
  end

  it "should parse '1.a(2, 3 + 4).b();'" do
    tokens = Lexer.new("1.a(2, 3 + 4).b();").scan_tokens
    result = Parser.new(tokens).parse_program[0].as(ExprStatement).expr
    expected = FunctionCallExpr.new(
      ObjectAccessExpr.new(
        FunctionCallExpr.new(
          ObjectAccessExpr.new(NumberLiteralExpr.new(1), "a"),
          [
            NumberLiteralExpr.new(2),
            BinaryExprPlus.new(NumberLiteralExpr.new(3), NumberLiteralExpr.new(4)),
          ],
        ),
        "b"
      ),
      [] of Expr,
    )
    result.should eq expected
  end

  it "should parse 'a.b + c * d;'" do
    tokens = Lexer.new("a.b + c * d;").scan_tokens
    result = Parser.new(tokens).parse_program[0].as(ExprStatement).expr
    expected = BinaryExprPlus.new(
      ObjectAccessExpr.new(VariableExpr.new("a"), "b"),
      BinaryExprMult.new(VariableExpr.new("c"), VariableExpr.new("d")),
    )
    result.should eq expected
  end

  it "should parse 'a + b; 1 + 2;'" do
    tokens = Lexer.new("a + b; 1 + 2;").scan_tokens
    result = Parser.new(tokens).parse_program
    expected = [
      ExprStatement.new(
        BinaryExprPlus.new(VariableExpr.new("a"), VariableExpr.new("b"))
      ),
      ExprStatement.new(
        BinaryExprPlus.new(NumberLiteralExpr.new(1), NumberLiteralExpr.new(2))
      ),
    ]
    result.zip?(expected) do |res, exp|
      res.should eq exp
    end
  end

  it "should parse 'var x = 1 + 2;'" do
    tokens = Lexer.new("var x = 1 + 2;").scan_tokens
    result = Parser.new(tokens).parse_program[0].as(VariableDeclarationStatement)
    expected = VariableDeclarationStatement.new(
      "x",
      BinaryExprPlus.new(NumberLiteralExpr.new(1), NumberLiteralExpr.new(2)),
    )
    result.should eq expected
  end

  it "should parse '\"abc{ 1 + 2 }def\";'" do
    tokens = Lexer.new("\"abc{ 1 + 2 }def\";").scan_tokens
    result = Parser.new(tokens).parse_program[0].as(ExprStatement).expr
    expected = StringLiteralExpr.new([
      StringLiteralFragment.new("abc"),
      StringInterpolationFragment.new(
        BinaryExprPlus.new(NumberLiteralExpr.new(1), NumberLiteralExpr.new(2))
      ),
      StringLiteralFragment.new("def"),
    ])
    result.should eq expected
  end

  it "should parse '\"abc{ \"def{ 1 + 2 }\" ++ \"ghi\" }jkl\";'" do
    tokens = Lexer.new("\"abc{ \"def{ 1 + 2 }\" ++ \"ghi\" }jkl\";").scan_tokens
    result = Parser.new(tokens).parse_program[0].as(ExprStatement).expr
    expected = StringLiteralExpr.new([
      StringLiteralFragment.new("abc"),
      StringInterpolationFragment.new(
        BinaryExprConcat.new(
          StringLiteralExpr.new([
            StringLiteralFragment.new("def"),
            StringInterpolationFragment.new(
              BinaryExprPlus.new(NumberLiteralExpr.new(1), NumberLiteralExpr.new(2))
            ),
          ]),
          StringLiteralExpr.new([StringLiteralFragment.new("ghi")] of StringFragment)
        ),
      ),
      StringLiteralFragment.new("jkl"),
    ])
    result.should eq expected
  end
end
