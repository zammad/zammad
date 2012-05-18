class TranslationsController < ApplicationController
  before_filter :authentication_check, :except => [:load]

  # GET /translations/:lang
  def load
    translations = Translation.where( :locale => params[:locale] )

    list = []
    translations.each { |item|
      data = [
        item.id,
        item.source,
        item.target,
      ]
      list.push data
    }

    render :json => list
  end

  # GET /translations
  def index
    @translations = Translation.all

    render :json => @translations
  end

  # GET /translations/1
  def show
    @translation = Translation.find(params[:id])

    render :json => @translation
  end

  # POST /translations
  def create
    @translation = Translation.new(params[:translation])

    if @translation.save
      render :json => @translation, :status => :created
    else
      render :json => @translation.errors, :status => :unprocessable_entity
    end
  end

  # PUT /translations/1
  def update
    @translation = Translation.find(params[:id])

    if @translation.update_attributes(params[:translation])
      render :json => @translation, :status => :ok
    else
      render :json => @translation.errors, :status => :unprocessable_entity
    end
  end

  # DELETE /translations/1
  def destroy
    @translation = Translation.find(params[:id])
    @translation.destroy

    head :ok
  end
end
