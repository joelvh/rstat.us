require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

class UpdateTest < MiniTest::Unit::TestCase

  include AcceptanceHelper

  def test_feed_render
    feed = Factory(:feed)

    updates = []
    5.times do
      updates << Factory(:update)
    end

    feed.updates = updates
    feed.save

    visit "/feeds/#{feed.id}.atom"

    updates.each do |update|
      assert_match page.body, /#{update.text}/
    end
  end

  def test_user_can_see_world
    u = Factory(:user)
    a = Factory(:authorization, :user => u)

    u2 = Factory(:user)
    update = Factory(:update)
    u2.feed.updates << update

    log_in(u, a.uid)

    visit "/updates"

    assert_match update.text, page.body
  end

  def test_user_makes_updates
    u = Factory(:user)
    a = Factory(:authorization, :user => u)
    update_text = "Testing, testing"
    params = {
      :text => update_text
    }
    log_in(u, a.uid)

    VCR.use_cassette('publish_update') do
      visit "/"
      fill_in 'update-textarea', :with => update_text
      click_button :'update-button'
    end

    assert_match page.body, /#{update_text}/
  end

  def test_user_can_make_short_update
    u = Factory(:user)
    a = Factory(:authorization, :user => u)
    update_text = "Q"
    params = {
      :text => update_text
    }
    log_in(u, a.uid)

    VCR.use_cassette('publish_short_update') do
      visit "/"
      fill_in 'update-textarea', :with => update_text
      click_button :'update-button'
    end

    refute_match page.body, /Your status is too short!/
  end

  def test_user_stays_on_same_route_after_post_update
    u = Factory(:user)
    a = Factory(:authorization, :user => u)

    log_in(u, a.uid)

    visit "/updates"
    fill_in "text", :with => "Teststring fuer die Ewigkeit ohne UTF-8 Charakter"
    VCR.use_cassette('publish_to_hub') {click_button "Share"}

    assert_match "/updates", page.current_url

    visit "/replies"
    fill_in "text", :with => "Bratwurst mit Pommes rot-weiss"
    VCR.use_cassette('publish_to_hub') {click_button "Share"}

    assert_match "/replies", page.current_url

    visit "/"
    fill_in "text", :with => "Buy a test string. Your name in this string for only 1 Euro/character"
    VCR.use_cassette('publish_to_hub') {click_button "Share"}

    assert_match "/", page.current_url
  end

  def test_twitter_user_sees_Post_to_message
    u = Factory(:user)
    a = Factory(:authorization, :user => u, :provider => "twitter")
    log_in(u, a.uid)
    visit "/updates"

    assert_match page.body, /Post to/
  end

  def test_facebook_user_sees_Post_to_message
    u = Factory(:user)
    a = Factory(:authorization, :user => u, :provider => "facebook")
    log_in_fb(u, a.uid)
    visit "/updates"

    assert_match page.body, /Post to/
  end

  def test_email_user_sees_no_Post_to_message
    u = Factory(:user)
    log_in_email(u)
    visit "/updates"

    refute_match page.body, /Post to/
  end
  
  def test_update_render
    update = Factory(:update)
    
    visit "/updates/#{update.id}"
    assert_match page.body, /#{update.text}/
  end
  
  def test_update_render_with_referral
    update = Factory(:update)
    update2 = Factory(:update)
    update2.referral_id = update.id
    update2.save
    
    visit "/updates/#{update2.id}"
    assert_match page.body, /#{update2.text}/
    assert_match page.body, /#{update.text}/
  end
  
  def test_updates_paginate_forward_only
    30.times do
      Factory(:update)
    end

    u = Factory(:user)
    log_in_email(u)
    visit "/updates"
    
    refute_match "Previous", page.body
    assert_match "Next", page.body
  end
  
  def test_updates_paginate_back_only
    u = Factory(:user)
    log_in_email(u)
    
    30.times do
      Factory(:update)
    end
    
    visit "/updates"
    click_link "next_button"
    
    assert_match "Previous", page.body
    refute_match "Next", page.body
  end
  
  def test_updates_paginate
    54.times do
      Factory(:update)
    end

    u = Factory(:user)
    log_in_email(u)
    visit "/updates"
    click_link "next_button"
    
    assert_match "Previous", page.body
    assert_match "Next", page.body
  end
end
