class OverviewsController < ApplicationController
  before_filter :authentication_check

  # GET /overviews
  # GET /overviews.json
  def index
    @overviews = Overview.all

    respond_to do |format|
      format.json { render :json => @overviews }
    end
  end

  # GET /overviews/1
  # GET /overviews/1.json
  def show
    @overview = Overview.find(params[:id])

    respond_to do |format|
      format.json { render :json => @overview }
    end
  end

  # GET /overviews/new
  # GET /overviews/new.json
  def new
    @overview = Overview.new

    respond_to do |format|
      format.json { render :json => @overview }
    end
  end

  # GET /overviews/1/edit
  def edit
    @overview = Overview.find(params[:id])
  end

  # POST /overviews
  # POST /overviews.json
  def create
    @overview = Overview.new(params[:overview])

    respond_to do |format|
      if @overview.save
        format.json { render :json => @overview, :status => :created }
      else
        format.json { render :json => @overview.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /overviews/1
  # PUT /overviews/1.json
  def update
    @overview = Overview.find(params[:id])

    respond_to do |format|
      if @overview.update_attributes(params[:overview])
        format.json { render :json => @overview, :status => :ok }
      else
        format.json { render :json => @overview.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /overviews/1
  # DELETE /overviews/1.json
  def destroy
    @overview = Overview.find(params[:id])
    @overview.destroy

    respond_to do |format|
      format.json { head :ok }
    end
  end
end
