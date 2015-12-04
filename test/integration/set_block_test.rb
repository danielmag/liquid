require 'test_helper'

class SetBlockTest < Minitest::Test
  include Twig

  def test_sets_block_content_in_variable
    assert_template_result("test string", "{% set 'var' %}test string{% endset %}{{var}}", {})
  end

  def test_set_with_hyphen_in_variable_name
    template_source = <<-END_TEMPLATE
    {% set this-thing %}Print this-thing{% endset %}
    {{ this-thing }}
    END_TEMPLATE
    template = Template.parse(template_source)
    rendered = template.render!
    assert_equal "Print this-thing", rendered.strip
  end

  def test_set_to_variable_from_outer_scope_if_existing
    template_source = <<-END_TEMPLATE
    {% set var = '' %}
    {% if true %}
    {% set var %}first-block-string{% endset %}
    {% endif %}
    {% if true %}
    {% set var %}test-string{% endset %}
    {% endif %}
    {{var}}
    END_TEMPLATE
    template = Template.parse(template_source)
    rendered = template.render!
    assert_equal "test-string", rendered.gsub(/\s/, '')
  end

  def test_assigning_from_set
    template_source = <<-END_TEMPLATE
    {% set first = '' %}
    {% set second = '' %}
    {% for number in (1..3) %}
    {% set first %}{{number}}{% endset %}
    {% set second = first %}
    {% endfor %}
    {{ first }}-{{ second }}
    END_TEMPLATE
    template = Template.parse(template_source)
    rendered = template.render!
    assert_equal "3-3", rendered.gsub(/\s/, '')
  end
end # setTest
