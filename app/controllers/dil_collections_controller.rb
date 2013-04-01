class DilCollectionsController < ApplicationController
  
  include DIL::PidMinter
  
  def create
    authorize!(:create, DILCollection)
	  #make sure collection's name isn't a reserved name for Uploads and Details collections
	  if params[:dil_collection][:title].downcase == DIL_CONFIG['dil_uploads_collection'].downcase || params[:dil_collection][:title].downcase == DIL_CONFIG['dil_details_collection'].downcase
	    flash[:alert] = "Cannot use that collection name. That name is reserved."
	  else	
	    edit_users_array = DIL_CONFIG['admin_staff'] | Array.new([current_user.user_key])
	    @dil_collection = DILCollection.new(:pid=>mint_pid("dil-local"))
		@dil_collection.apply_depositor_metadata(current_user.user_key)
		@dil_collection.edit_users = edit_users_array
		@dil_collection.set_collection_type('dil_collection')
		@dil_collection.descMetadata.title = params[:dil_collection][:title]
		@dil_collection.save!
	  end
	  redirect_to :back
  end

  def update
    @collection = DILCollection.find(params[:id])
    authorize! :update, @collection
    read_groups = params[:dil_collection].delete(:read_groups)
    if read_groups.present?
      eligible = current_user.owned_groups.map(&:code)
      @collection.set_read_groups(read_groups, current_user.owned_groups.map(&:code))
    end
    @collection.update_attributes(params[:dil_collection])
    if @collection.save
      flash[:notice] = "Saved changes to #{@collection.title}"
    else
      flash[:alert] = "Failed to save your changes!"
    end
    redirect_to edit_dil_collection_path(@collection)
  end
 
  def add
    @collection = DILCollection.find(params[:id])
    authorize! :edit, @collection
    @fedora_object = ActiveFedora::Base.find(params[:member_id], :cast=>true)
    authorize! :show, @fedora_object
    @collection.insert_member(@fedora_object)
    render :nothing => true
  end
  
  #remove an image or subcollection from the collection
  def remove
    member_index = params[:member_index];
    collection = DILCollection.find(params[:id])
    authorize! :update, collection
    collection.remove_member_by_pid(params[:pid])
    
    redirect_to edit_dil_collection_path(collection)
  end
  
  #delete the collection
  def destroy
    begin
      collection = DILCollection.find(params[:id])
      authorize! :destroy, collection
    
      #remove all images from collection
      collection.multiresimages.each do |image|
        collection.remove_member_by_pid(image.pid)
      end
    
      #remove all subcollections from collection
      collection.subcollections.each do |subcollection|
        collection.remove_member_by_pid(subcollection.pid)
      end
      
      #remove collection from parent collections
      collection.parent_collections.each do |parent_collection|
        parent_collection.remove_member_by_pid(collection.pid)
      end
      
      #delete the DILCollection object
      collection.delete
      flash[:notice] = "Image Group deleted"
    
    rescue Exception => e
      flash[:error] = "Error deleting Image Group"
      logger.debug("ERROR ERROR #{e.to_s}")
    
    ensure 
      redirect_to catalog_index_path
    end
  
  end
  
  #move a member item in a collection from original position to new position
  def move
    collection = DILCollection.find(params[:id])
    authorize! :update, collection
	ds = collection.datastreams["members"]
    
    #call the move_member method within mods_collection_members
    ds.move_member(params[:from_index], params[:to_index])
    collection.save!
	render :nothing => true
  end
  
  def show
    @collection = DILCollection.find(params[:id])
    authorize! :show, @collection
    if can?(:edit, @collection)
      render :action => 'edit', :id => params[:id]
    end
    
  end
  
  def edit
    @collection = DILCollection.find(params[:id])
    authorize! :edit, @collection
  end
  
  def export
    @collection = DILCollection.find(params[:id])
    authorize! :update, @collection
    #read_groups = params[:dil_collection].delete(:read_groups)
    #if read_groups.present?
      #eligible = current_user.owned_groups.map(&:code)
      #@collection.set_read_groups(read_groups, current_user.owned_groups.map(&:code))
    #end
    
    export_xml = @collection.export_image_info_as_xml(current_user.email)
    #export_xml << current_user.email
    logger.debug("export_xml: " + export_xml)
	# response will be status of script that puts message in queue
	logger.debug("Before CGI call for export")
	post_args = {'xml' => export_xml}
	cgi_response = Net::HTTP.post_form(URI.parse(DIL_CONFIG['dil_ppt_cgi_url']), 'collection_xml' => export_xml).body
	logger.debug("After CGI call for export")
	logger.debug("response:" + cgi_response)

    flash[:notice] = "Image Group exported.  Please check your Northwestern University email account for a link to your presentation."
    
    redirect_to edit_dil_collection_path(@collection)
  end
  
  
  
  #This will return all the subcollections of the collection
  def get_subcollections
    begin 
      collection = DILCollection.find(params[:id])
      authorize! :show, collection
    
      #get the json
      return_json = collection.get_subcollections_json
    
    rescue Exception => e
      #error
      return_json = "Exception"
      logger.debug("get_subcollections exception: #{e.to_s}")
        
    ensure #this will get called even if an exception was raised
      respond_to do |format|
        #This wasn't working quite right, so just storing JSON in a variable instead of using .to_json
        #format.json { render :layout =>  false, :json => collection.to_json(:methods=>:get_subcollections) }
        format.json { render :layout =>  false, :json => return_json}
      end  
    
    end
  end
  
end
