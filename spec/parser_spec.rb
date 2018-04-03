require 'spec_helper'

describe Parser do
  before :all do
    @parser = Parser.new "test_sample.log"
  end

  describe "it should return correct data" do
    it "should return the correct count of GET /api/users/{user_id}/count_pending_messages" do
      expect(@parser.count_pending_msgs).to eq(19)
    end

    it "should return the correct count of GET /api/users/{user_id}/get_messages" do
      expect(@parser.get_msgs).to eq(1)
    end

    it "should return the correct count of GET /api/users/{user_id}/get_friends_progress:" do
      expect(@parser.get_friend_prog).to eq(6)
    end

    it "should return the correct count of GET /api/users/{user_id}/get_friends_score" do
      expect(@parser.get_friend_score).to eq(12)
    end

    it "should return the correct count of POST /api/users/{user_id}" do
      expect(@parser.post_users).to eq(23)
    end

    it "should return the correct count of GET /api/users/{user_id}" do
      expect(@parser.get_users).to eq(3)
    end

    it "should return the correct Mean of Response Time" do
      expect(@parser.mean).to eq(67)
    end

    it "should return the correct Median of Response Time" do
      expect(@parser.median).to eq(32)
    end

    it "should return the correct Mode of Response Time" do
      expect(@parser.modes).to eq([19])
    end

    it "should return the correct count of max dyno that responded" do
      expect(@parser.max_dyno).to eq('web.12')
    end
  end
end
