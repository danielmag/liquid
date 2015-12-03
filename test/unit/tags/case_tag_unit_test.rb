require 'test_helper'

class CaseTagUnitTest < Minitest::Test
  include Twig

  def test_case_nodelist
    template = Twig::Template.parse('{% case var %}{% when true %}WHEN{% else %}ELSE{% endcase %}')
    assert_equal ['WHEN', 'ELSE'], template.root.nodelist[0].nodelist
  end
end
