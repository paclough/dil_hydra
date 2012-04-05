class UploadsController < ApplicationController

  include Hydra::AssetsControllerHelper
  include Hydra::FileAssetsHelper  
  include Hydra::RepositoryController  
  include Blacklight::SolrHelper
 
  skip_before_filter :verify_authenticity_token #TODO Bad idea. Just restrict this to the methods that need it (update_status?).
  before_filter :authenticate_user!, :only=>[:index, :create]
  #TODO ensure that only our script is calling update_status

  def index
    respond_to do |format|
      format.json {
        #TODO find_by_solr could be faster 
        @multiresimages = selected_files.map {|pid| Multiresimage.find(pid)}
        render :json=>@multiresimages.map(&:to_jq_upload)
      }
      format.html
    end
  end

  def create
    session[:files] ||= []
    @image = Multiresimage.create()
    @image.attach_file(params[:files])
    @image.apply_depositor_metadata(current_user.email)
    @image.save!
    session[:files] << @image.pid 
    respond_to do |format|
      format.json {  
        render :json => [@image.to_jq_upload].to_json			
      }
    end

  end

  def enqueue
    selected_files.each do |pid|
      @image_processing_request = ImageProcessingRequest.create!(:status => 'NEW', :pid=>pid, :email => 'm-stroming@northwestern.edu')
      @image_processing_request.enqueue
    end
      
    render :nothing => true
  end
  
  def update_status
    logger.debug("Entering update_status")
    
    logger.debug("Retrieve af model")
    image_processing_request = ImageProcessingRequest.find(params[:request_id])

    image = Multiresimage.find(image_processing_request.pid)
    # Get  SVG datastream
    logger.debug("Get svg datastream")
    new_svg_ds = image.datastreams["DELIV-OPS"] 

    logger.debug("Add image params")
    new_svg_ds.add_image_parameters(params[:image_path], params[:width], params[:height])
    #new_svg_ds.add_image_parameters("test", "100", "100")
    
    # Add image and VRA behavior via their cmodels
    logger.debug("Add VRACModel relationship")
    image.add_relationship(:has_model, "info:fedora/inu:VRACModel")
    logger.debug("Add imageCModel relationship")
    image.add_relationship(:has_model, "info:fedora/inu:imageCModel")
    logger.debug("Save new image")
    image.save()
    logger.debug("Image saved")
     
    image_processing_request.update_attribute(:status, "VALIDATED" + params[:status])
    
    render :nothing => true
  end


  private 

  def selected_files
    session[:files] ||= []
  end
  
  
end
