require 'test_helper'

class IfTagUnitTest < Minitest::Test
  def test_if_nodelist
    template = Twig::Template.parse('{% if true %}IF{% else %}ELSE{% endif %}')
    assert_equal ['IF', 'ELSE'], template.root.nodelist[0].nodelist
  end
end
