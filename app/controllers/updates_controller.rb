class UpdatesController < ApplicationController
  # GET /updates
  # GET /updates.json
  def index
    @updates = Update.all
    @commits = (@updates.collect {|update| update.commits }).reduce Hash.new, :merge
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @updates }
    end
  end

  # GET /updates/1
  # GET /updates/1.json
  def show
    @update = Update.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @update }
    end
  end

  # GET /updates/new
  # GET /updates/new.json
  def new
    @update = Update.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @update }
    end
  end

  # GET /updates/1/edit
  def edit
    @update = Update.find(params[:id])
  end

  # POST /updates
  # POST /updates.json
  def create
    push = JSON.parse(params[:payload])
    @update = Update.new
    @update.after = push["after"]
    @update.before = push["before"]
    @update.commits = push["commits"]
    @update.ref = push["ref"]
    if !Update.allowed_ips.include?(request.remote_ip)
      Update.error_proc({ result: "ILLEGAL IP OF #{request.remote_ip}", command: "WOOOOOOOO"})
      format.html { render action: "index", notice: '', status: 403 }
      format.json { render json: @updates, status: 403 }
    else
      @update.commits = convert_commits @update.commits
      @update.apply_update
      respond_to do |format|
        if @update.save
          format.html { redirect_to @update, notice: 'Update was successfully created.' }
          format.json { render json: @update, status: :created, location: @update }
        else
          format.html { render action: "new" }
          format.json { render json: @update.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # PUT /updates/1
  # PUT /updates/1.json
  def update
    @update = Update.find(params[:id])

    respond_to do |format|
      if @update.update_attributes(params[:update])
        format.html { redirect_to @update, notice: 'Update was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @update.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /updates/1
  # DELETE /updates/1.json
  def destroy
    @update = Update.find(params[:id])
    @update.destroy

    respond_to do |format|
      format.html { redirect_to updates_url }
      format.json { head :no_content }
    end
  end


  def self.convert_commits(commits)
    if commits.class.name == "Hash"
      commits.each do |key, value|
        value = {"modified"=>[], "added"=>[], "removed"=>[], "parents"=>[]}.merge value
        value.symbolize_keys!
        do_command "git rev-list --parents -n 1 #{key}"
        value[:parents] = ShellCommand.last_result["result"].split(' ').collect { |val| val if val != key }.reject{|x| x == nil }
        commits[key] = value  
      end
      return commits
    end
    hash = {}
    commits.each do |commit|
      id = commit["id"]
      hash[id] = {"modified"=>[], "added"=>[], "removed"=>[], "parents"=>[]}.merge commit
      if hash[id][parents].length == 0
        do_command "git rev-list --parents -n 1 #{id}"
        hash[id]["parents"] = ShellCommand.last_result["result"].split(' ').collect { |val| val if val != id }.reject{|x| x == nil }
      end
      hash[id].except!("id").symbolize_keys!
    end
    return hash
  end
end
