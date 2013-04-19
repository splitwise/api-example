class OctopiController < ApplicationController
  # GET /octopi
  # GET /octopi.json
  def index
    @octopi = Octopus.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @octopi }
    end
  end

  # GET /octopi/1
  # GET /octopi/1.json
  def show
    @octopus = Octopus.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @octopus }
    end
  end

  # GET /octopi/new
  # GET /octopi/new.json
  def new
    @octopus = Octopus.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @octopus }
    end
  end

  # GET /octopi/1/edit
  def edit
    @octopus = Octopus.find(params[:id])
  end

  # POST /octopi
  # POST /octopi.json
  def create
    @octopus = Octopus.new(params[:octopus])

    respond_to do |format|
      if @octopus.save
        format.html { redirect_to @octopus, notice: 'Octopus was successfully created.' }
        format.json { render json: @octopus, status: :created, location: @octopus }
      else
        format.html { render action: "new" }
        format.json { render json: @octopus.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /octopi/1
  # PUT /octopi/1.json
  def update
    @octopus = Octopus.find(params[:id])

    respond_to do |format|
      if @octopus.update_attributes(params[:octopus])
        format.html { redirect_to @octopus, notice: 'Octopus was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @octopus.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /octopi/1
  # DELETE /octopi/1.json
  def destroy
    @octopus = Octopus.find(params[:id])
    @octopus.destroy

    respond_to do |format|
      format.html { redirect_to octopi_url }
      format.json { head :no_content }
    end
  end
end
