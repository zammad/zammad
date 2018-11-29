require "spec_helper"

describe String do

  describe "#snakecase" do
    it "lowercases one word CamelCase" do
      expect("Merb".snakecase).to eq("merb")
    end

    it "makes one underscore snakecase two word CamelCase" do
      expect("MerbCore".snakecase).to eq("merb_core")
    end

    it "handles CamelCase with more than 2 words" do
      expect("SoYouWantContributeToMerbCore".snakecase).to eq("so_you_want_contribute_to_merb_core")
    end

    it "handles CamelCase with more than 2 capital letter in a row" do
      expect("CNN".snakecase).to eq("cnn")
      expect("CNNNews".snakecase).to eq("cnn_news")
      expect("HeadlineCNNNews".snakecase).to eq("headline_cnn_news")
    end

    it "does NOT change one word lowercase" do
      expect("merb".snakecase).to eq("merb")
    end

    it "leaves snake_case as is" do
      expect("merb_core".snakecase).to eq("merb_core")
    end
  end

end
