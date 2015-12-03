require 'test_helper'

class ErrorDrop < Twig::Drop
  def standard_error
    raise Twig::StandardError, 'standard error'
  end

  def argument_error
    raise Twig::ArgumentError, 'argument error'
  end

  def syntax_error
    raise Twig::SyntaxError, 'syntax error'
  end

  def exception
    raise Exception, 'exception'
  end

end

class ErrorHandlingTest < Minitest::Test
  include Twig

  def test_templates_parsed_with_line_numbers_renders_them_in_errors
    template = <<-TWIG
      Hello,

      {{ errors.standard_error }} will raise a standard error.

      Bla bla test.

      {{ errors.syntax_error }} will raise a syntax error.

      This is an argument error: {{ errors.argument_error }}

      Bla.
    TWIG

    expected = <<-TEXT
      Hello,

      Twig error (line 3): standard error will raise a standard error.

      Bla bla test.

      Twig syntax error (line 7): syntax error will raise a syntax error.

      This is an argument error: Twig error (line 9): argument error

      Bla.
    TEXT

    output = Twig::Template.parse(template, line_numbers: true).render('errors' => ErrorDrop.new)
    assert_equal expected, output
  end

  def test_standard_error
    template = Twig::Template.parse( ' {{ errors.standard_error }} '  )
    assert_equal ' Twig error: standard error ', template.render('errors' => ErrorDrop.new)

    assert_equal 1, template.errors.size
    assert_equal StandardError, template.errors.first.class
  end

  def test_syntax
    template = Twig::Template.parse( ' {{ errors.syntax_error }} '  )
    assert_equal ' Twig syntax error: syntax error ', template.render('errors' => ErrorDrop.new)

    assert_equal 1, template.errors.size
    assert_equal SyntaxError, template.errors.first.class
  end

  def test_argument
    template = Twig::Template.parse( ' {{ errors.argument_error }} '  )
    assert_equal ' Twig error: argument error ', template.render('errors' => ErrorDrop.new)

    assert_equal 1, template.errors.size
    assert_equal ArgumentError, template.errors.first.class
  end

  def test_missing_endtag_parse_time_error
    assert_raises(Twig::SyntaxError) do
      Twig::Template.parse(' {% for a in b %} ... ')
    end
  end

  def test_unrecognized_operator
    with_error_mode(:strict) do
      assert_raises(SyntaxError) do
        Twig::Template.parse(' {% if 1 =! 2 %}ok{% endif %} ')
      end
    end
  end

  def test_lax_unrecognized_operator
    template = Twig::Template.parse(' {% if 1 =! 2 %}ok{% endif %} ', :error_mode => :lax)
    assert_equal ' Twig error: Unknown operator =! ', template.render
    assert_equal 1, template.errors.size
    assert_equal Twig::ArgumentError, template.errors.first.class
  end

  def test_with_line_numbers_adds_numbers_to_parser_errors
    err = assert_raises(SyntaxError) do
      template = Twig::Template.parse(%q{
          foobar

          {% "cat" | foobar %}

          bla
        },
        :line_numbers => true
      )
    end

    assert_match /Twig syntax error \(line 4\)/, err.message
  end

  def test_parsing_warn_with_line_numbers_adds_numbers_to_lexer_errors
    template = Twig::Template.parse(%q{
        foobar

        {% if 1 =! 2 %}ok{% endif %}

        bla
      },
      :error_mode => :warn,
      :line_numbers => true
    )

    assert_equal ['Twig syntax error (line 4): Unexpected character = in "1 =! 2"'],
      template.warnings.map(&:message)
  end

  def test_parsing_strict_with_line_numbers_adds_numbers_to_lexer_errors
    err = assert_raises(SyntaxError) do
      Twig::Template.parse(%q{
          foobar

          {% if 1 =! 2 %}ok{% endif %}

          bla
        },
        :error_mode => :strict,
        :line_numbers => true
      )
    end

    assert_equal 'Twig syntax error (line 4): Unexpected character = in "1 =! 2"', err.message
  end

  def test_syntax_errors_in_nested_blocks_have_correct_line_number
    err = assert_raises(SyntaxError) do
      Twig::Template.parse(%q{
          foobar

          {% if 1 != 2 %}
            {% foo %}
          {% endif %}

          bla
        },
        :line_numbers => true
      )
    end

    assert_equal "Twig syntax error (line 5): Unknown tag 'foo'", err.message
  end

  def test_strict_error_messages
    err = assert_raises(SyntaxError) do
      Twig::Template.parse(' {% if 1 =! 2 %}ok{% endif %} ', :error_mode => :strict)
    end
    assert_equal 'Twig syntax error: Unexpected character = in "1 =! 2"', err.message

    err = assert_raises(SyntaxError) do
      Twig::Template.parse('{{%%%}}', :error_mode => :strict)
    end
    assert_equal 'Twig syntax error: Unexpected character % in "{{%%%}}"', err.message
  end

  def test_warnings
    template = Twig::Template.parse('{% if ~~~ %}{{%%%}}{% else %}{{ hello. }}{% endif %}', :error_mode => :warn)
    assert_equal 3, template.warnings.size
    assert_equal 'Unexpected character ~ in "~~~"', template.warnings[0].to_s(false)
    assert_equal 'Unexpected character % in "{{%%%}}"', template.warnings[1].to_s(false)
    assert_equal 'Expected id but found end_of_string in "{{ hello. }}"', template.warnings[2].to_s(false)
    assert_equal '', template.render
  end

  def test_warning_line_numbers
    template = Twig::Template.parse("{% if ~~~ %}\n{{%%%}}{% else %}\n{{ hello. }}{% endif %}", :error_mode => :warn, :line_numbers => true)
    assert_equal 'Twig syntax error (line 1): Unexpected character ~ in "~~~"', template.warnings[0].message
    assert_equal 'Twig syntax error (line 2): Unexpected character % in "{{%%%}}"', template.warnings[1].message
    assert_equal 'Twig syntax error (line 3): Expected id but found end_of_string in "{{ hello. }}"', template.warnings[2].message
    assert_equal 3, template.warnings.size
    assert_equal [1,2,3], template.warnings.map(&:line_number)
  end

  # Twig should not catch Exceptions that are not subclasses of StandardError, like Interrupt and NoMemoryError
  def test_exceptions_propagate
    assert_raises Exception do
      template = Twig::Template.parse('{{ errors.exception }}')
      template.render('errors' => ErrorDrop.new)
    end
  end
end
