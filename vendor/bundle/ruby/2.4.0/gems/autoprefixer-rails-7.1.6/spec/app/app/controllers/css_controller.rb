class CssController < ApplicationController
  def test
    file = params[:exact_file] || params[:file] + '.css'
    render plain: Rails.application.assets[file].to_s.gsub(/;(\s})/, '\1')
  end
end
