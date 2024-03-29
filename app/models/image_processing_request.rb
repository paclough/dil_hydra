class ImageProcessingRequest < ActiveRecord::Base
  require "net/http"
  require "uri"

  validates :status, :presence => true
  validates :email, :presence => true
  validates :pid, :presence => true


  def enqueue
    image = begin
      Multiresimage.find(pid)
    rescue ActiveFedora::ObjectNotFoundError
      update_attribute(:status, "Not found")
      return
    end
    
    new_filepath = image.write_out_raw
    #if filename has spaces, replace with _
    #the "raw" datastream maintained by Fedora isn't affected by this file move, only the messaging server getting the file for file upload
    if (new_filepath.include? ' ')
      FileUtils.mv(new_filepath, new_filepath.gsub(' ', '_'))
      new_filepath.gsub!(' ', '_')
    end
    #create file on server from Fedora object datastream

    # new_filepath= File.join(DIL::Application.config.processing_file_path, "#{file.pid.gsub(":","")}.jpg")
    # 
    # Net::HTTP.start("127.0.0.1", 8983) { |http|
    #   resp = http.get("/fedora/objects/" + file.pid + "/datastreams/raw/content")
    #   logger.debug("response:" + resp.to_s) 
    #   open(new_filepath ,"wb") { |new_file|
    #     new_file.write(resp.body)
    #   }
    # }
    # 
    # FileUtils.chmod(0755, new_filepath)
      


    # TODO Can we replace the cgi-bin with stomp?
    # call CGI script with file location (path, name and id)
      cgi_url = "#{DIL_CONFIG['dil_upload_cgi_url']}?image_path=#{new_filepath}&request_id=#{id.to_s}&pid=#{pid}"
	  logger.debug("cgi url: " + cgi_url)
	  # response will be status of script that puts JMS message in queue
	  logger.debug("Before CGI call")
	  cgi_response = Net::HTTP.get_response(URI.parse(cgi_url)).body
	  logger.debug("After CGI call")
	  logger.debug("response:" + cgi_response)
	 
	  #cgi_response = nil
	  if cgi_response.nil?
      logger.debug("cgi_response is null")
	  else
	    status = "JMS" + cgi_response
	    logger.debug("Update status to: " + status)
	    #update status column in table
      update_attribute(:status, status)
    end
    

  end
end
