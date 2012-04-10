class NotesController < ApplicationController
  before_filter :authentication_check

  # GET /notes
  # GET /notes.json
  def index
    @notes = Note.find(:all, :order => "updated_at ASC")
#    @notes = Note.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @notes }
    end
  end

  # GET /notes/1
  # GET /notes/1.json
  def show
    @note = Note.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @note }
    end
  end

  # GET /notes/new
  # GET /notes/new.json
  def new
    @note = Note.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @note }
    end
  end

  # GET /notes/1/edit
  def edit
    @note = Note.find(params[:id])
  end

  # POST /notes
  # POST /notes.json
  def create
    @note = Note.new(params[:note])

    respond_to do |format|
      if @note.save
        format.html { redirect_to @note, :notice => 'Note was successfully created.' }
        format.json { render :json => @note, :status => :created }
      else
        format.html { render :action => "new" }
        format.json { render :json => @note.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /notes/1
  # PUT /notes/1.json
  def update
    @note = Note.find(params[:id])

    respond_to do |format|
      if @note.update_attributes(params[:note])
        format.html { redirect_to @note, :notice => 'Note was successfully updated.' }
        format.json { render :json => @note, :status => :ok }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @note.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /notes/1
  # DELETE /notes/1.json
  def destroy
    @note = Note.find(params[:id])
    @note.destroy

    respond_to do |format|
      format.html { redirect_to notes_url }
      format.json { head :ok }
    end
  end
end
