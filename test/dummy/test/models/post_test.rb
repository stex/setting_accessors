require_relative '../../../test_helper'

class PostTest < ActiveSupport::TestCase
  context 'JSON serialization' do
    setup do
      @post = Post.new(:title => 'a post', :text => 'a content')
    end

    should 'work without having any setting_accessors defined' do
      assert @post.as_json
    end

    should 'contain all original public attributes' do
      [:title, :text, :id, :created_at, :updated_at].each do |attr|
        assert_includes @post.as_json.keys, attr.to_s
      end
    end
  end
end
