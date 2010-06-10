require File.dirname(__FILE__) + '/abstract_unit'
include ActsAsIndexed

class ConfigurationTest < ActiveSupport::TestCase  
  
  def test_default_index_file_should_be_set
    assert_equal [RAILS_ROOT, 'index'], config.index_file
  end
  
  def test_default_index_file_depth_should_be_set
    assert_equal 3, config.index_file_depth
  end

  def test_default_min_word_size_should_be_set
    assert_equal 3, config.min_word_size
  end
  
  def test_index_file_should_be_writeable
    config.index_file = [RAILS_ROOT, 'my_index']
    assert_equal [RAILS_ROOT, 'my_index'], config.index_file
  end
  
  def test_index_file_depth_should_be_writeable
    config.index_file_depth = 5
    assert_equal 5, config.index_file_depth
  end
  
  def test_index_file_depth_should_raise_on_lower_than_1_value
    assert_nothing_raised(ArgumentError) {  config.index_file_depth = 1  }
    
    e = assert_raise(ArgumentError) { config.index_file_depth = 0 }
    assert_equal 'index_file_depth cannot be less than one (1)', e.message
    
    assert_raise(ArgumentError) { config.index_file_depth = -12 }
  end
  
  def test_min_word_size_should_be_writeable
    config.min_word_size = 7
    assert_equal 7, config.min_word_size
  end

  def test_min_word_size_should_raise_on_lower_than_1_value
    assert_nothing_raised(ArgumentError) {  config.min_word_size = 1  }

    e = assert_raise(ArgumentError) { config.min_word_size = 0 }
    assert_equal 'min_word_size cannot be less than one (1)', e.message

    assert_raise(ArgumentError) { config.min_word_size = -12 }
  end
  
  private
  
  def config
    @config ||=ActsAsIndexed::Configuration.new
  end
  
end