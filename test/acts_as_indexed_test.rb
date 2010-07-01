require File.dirname(__FILE__) + '/abstract_unit'

class ActsAsIndexedTest < ActiveSupport::TestCase
  fixtures :posts

  def teardown
    destroy_index
  end

  def test_adds_to_index
    original_post_count = Post.count
    assert_equal [], Post.find_with_index('badger')
    p = Post.new(:title => 'badger', :body => 'Thousands of them!')
    assert p.save
    assert_equal original_post_count+1, Post.count
    assert_equal [p.id], Post.find_with_index('badger',{},{:ids_only => true})
  end

  def test_removes_from_index
    original_post_count = Post.count
    assert_equal [posts(:wikipedia_article_4).id], Post.find_with_index('album',{},{:ids_only => true})
    assert Post.find(posts(:wikipedia_article_4).id).destroy
    assert_equal [], Post.find_with_index('album',{},{:ids_only => true})
    assert_equal original_post_count-1, Post.count
  end

  def test_search_returns_posts
    Post.find_with_index('album').each do |p|
      assert_equal Post, p.class
    end
  end

  def test_scoped_search_returns_posts
    Post.with_query('album').each do |p|
      assert_equal Post, p.class
    end
  end

  def test_search_returns_post_ids
    Post.find_with_index('album',{},{:ids_only => true}).each do |pid|
      assert p = Post.find(pid)
      assert_equal Post, p.class
    end
  end

  # After a portion of a record has been removed
  # the portion removes should no longer be in the index.
  def test_updates_index
    p = Post.create(:title => 'A special title', :body => 'foo bar bla bla bla')
    assert Post.find_with_index('title',{},{:ids_only => true}).include?(p.id)
    p.update_attributes(:title => 'No longer special')
    assert !Post.find_with_index('title',{},{:ids_only => true}).include?(p.id)
  end

  def test_simple_queries
    assert_equal [],  Post.find_with_index(nil)
    assert_equal [],  Post.find_with_index('')
    assert_equal [5, 6],  Post.find_with_index('ship',{},{:ids_only => true}).sort
    assert_equal [6],  Post.find_with_index('foo',{},{:ids_only => true})
    assert_equal [6],  Post.find_with_index('foo ship',{},{:ids_only => true})
    assert_equal [6],  Post.find_with_index('ship foo',{},{:ids_only => true})
  end

  def test_scoped_simple_queries
    assert_equal [],  Post.find_with_index(nil)
    assert_equal [],  Post.with_query('')
    assert_equal [5, 6],  Post.with_query('ship').map(&:id).sort
    assert_equal [6],  Post.with_query('foo').map(&:id)
    assert_equal [6],  Post.with_query('foo ship').map(&:id)
    assert_equal [6],  Post.with_query('ship foo').map(&:id)
  end

  def test_negative_queries
    assert_equal [5, 6],  Post.find_with_index('crane',{},{:ids_only => true}).sort
    assert_equal [5],  Post.find_with_index('crane -foo',{},{:ids_only => true})
    assert_equal [5],  Post.find_with_index('-foo crane',{},{:ids_only => true})
    assert_equal [],  Post.find_with_index('-foo') #Edgecase
  end

  def test_scoped_negative_queries
    assert_equal [5, 6],  Post.with_query('crane').map(&:id).sort
    assert_equal [5],  Post.with_query('crane -foo').map(&:id)
    assert_equal [5],  Post.with_query('-foo crane').map(&:id)
    assert_equal [],  Post.with_query('-foo') #Edgecase
  end

  def test_quoted_queries
    assert_equal [5],  Post.find_with_index('"crane ship"',{},{:ids_only => true})
    assert_equal [6],  Post.find_with_index('"crane big"',{},{:ids_only => true})
    assert_equal [],  Post.find_with_index('foo "crane ship"')
    assert_equal [],  Post.find_with_index('"crane badger"')
  end

  def test_scoped_quoted_queries
    assert_equal [5],  Post.with_query('"crane ship"').map(&:id)
    assert_equal [6],  Post.with_query('"crane big"').map(&:id)
    assert_equal [],  Post.with_query('foo "crane ship"')
    assert_equal [],  Post.with_query('"crane badger"')
  end

  def test_negative_quoted_queries
    assert_equal [6],  Post.find_with_index('crane -"crane ship"',{},{:ids_only => true})
    assert_equal [],  Post.find_with_index('-"crane big"',{},{:ids_only => true}) # Edgecase
  end

  def test_scoped_negative_quoted_queries
    assert_equal [6],  Post.with_query('crane -"crane ship"').map(&:id)
    assert_equal [],  Post.with_query('-"crane big"') # Edgecase
  end

  def test_start_quoted_queries
    assert_equal [5],  Post.find_with_index('^"crane ship"',{},{:ids_only => true})
    assert_equal [5],  Post.find_with_index('^"crane shi"',{},{:ids_only => true})
    assert_equal [5],  Post.find_with_index('^"crane sh"',{},{:ids_only => true})
    assert_equal [5],  Post.find_with_index('^"crane s"',{},{:ids_only => true})
    assert_equal [6,5],  Post.find_with_index('^"crane "',{},{:ids_only => true})
    assert_equal [6,5],  Post.find_with_index('^"crane"',{},{:ids_only => true})
    assert_equal [6,5],  Post.find_with_index('^"cran"',{},{:ids_only => true})
    assert_equal [6,5],  Post.find_with_index('^"cra"',{},{:ids_only => true})
    assert_equal [6,5,4],  Post.find_with_index('^"cr"',{},{:ids_only => true})
    assert_equal [6,5,4,3,2,1], Post.find_with_index('^"c"',{},{:ids_only => true})
  end

  def test_find_options
    all_results = Post.find_with_index('crane',{},{:ids_only => true})
    first_result = Post.find_with_index('crane',{:limit => 1})

    assert_equal 1, first_result.size
    assert_equal all_results.first, first_result.first.id

    second_result = Post.find_with_index('crane',{:limit => 1, :offset => 1})
    assert_equal 1, second_result.size
    assert_equal all_results[1], second_result.first.id
  end

  # When a atom already in a record is duplicated, it removes 
  # all records with that same atom from the index.
  def test_update_record_bug
    assert_equal 2, Post.find_with_index('crane',{},{:ids_only => true}).size
    p = Post.find(6)
    assert p.update_attributes(:body => p.body + ' crane')
    assert_equal 2, Post.find_with_index('crane',{},{:ids_only => true}).size
    assert_equal 2, Post.find_with_index('ship',{},{:ids_only => true}).size
  end
  
end
