#!/usr/bin/env ruby

# Author: Edgar Garcia
# This notice along with part of this code was lifted from delete_policy_ds.rb as written by Mike Stroming

# BE CAREFUL!!!
# This script reads a file that has a list of Fedora pids (one per line)
# and removes a datastream.
# Make sure to set the config variables!
require 'logger'
require 'fileutils'
require 'net/http'

# Configs
@folder_path = '/usr/local/src/dil_hydra/'
@pids_file_path = "#{@folder_path}pid.txt"
@fedora_url = "http://localhost:8983/fedora/objects/"
@fedora_username = 'fedoraAdmin'
@fedora_password = 'fedoraAdmin'
@missing_ds = {}
@img_ds_missing = []
@vra_ds_missing = []
@rels_ext_ds_missing = []
#log for every missing datastream for each object
@missing_ds_aggregate_logger = Logger.new('/usr/local/src/dil_hydra/lib/missing_ds_aggregate.log')
#log for pids that have a missing datastream
@missing_ds_pid_logger = Logger.new('/usr/local/src/dil_hydra/lib/missing_ds_pids.log')
#log for pids that are complete objects
@complete_object_pid_logger = Logger.new('/usr/local/src/dil_hydra/lib/complete_pids.log')
@error_logger = Logger.new('/usr/local/src/dil_hydra/lib/audit_errors.log')
#img_ds = ["ARCHV-IMG", "DELIV-IMG", "DELIV-OPS", "ARCHV-EXIF", "ARCHV-TECHMD", "DELIV-TECHMD"]
#other_ds = ["VRA", "DC", "rightsMetadata"]
@all_ds = ["RELS-EXT", "ARCHV-IMG", "DELIV-IMG", "DELIV-OPS", "ARCHV-EXIF", "ARCHV-TECHMD", "DELIV-TECHMD", "VRA", "DC", "rightsMetadata"]
@records = {}


# Get the accession number from the content of the VRA datastream.
# It's extracted from a node that looks like this:
#<vra:location>
#  <vra:refid source="DIL">inu:dil-d42f25cc-deb2-4fdc-b41b-616291578c26</vra:refid>
#  <vra:refid source="Voyager">16245</vra:refid>
#</vra:location>
# This method uses string manipulation instead of regex and xml parsing for performance
def get_accession_nbr(pid)
  uri = URI.parse("#{@fedora_url}#{pid}/datastreams/VRA/content")
  http = Net::HTTP.new(uri.host, uri.port)
  #build request
  request = Net::HTTP::Get.new(uri.request_uri)
  #add auth
  request.basic_auth(@fedora_username, @fedora_password)
  #run the request
  response = http.request(request)
  if response.code.eql? "200"
    vra = response.body if !response.body.nil?
    #this should be easier to follow than a regex and faster than using an xml parser
    #get the index of the start of the Voyager node and add the nbr of characters to it to get to the end
    #of the string
    node_start = "<vra:refid source=\"Voyager\">"
    node_end= "</vra:refid>"
    index_start_node = vra.index(node_start) + node_start.length
    index_end_node = vra.index(node_end, index_start_node) - 1
    accession_nbr = vra[index_start_node..index_end_node]
  end
end

begin

  #For each line in file, check the datastreams
  File.readlines(@pids_file_path).each do |pid|
    begin
      object_logged = false
      #remove newline
      pid.gsub!(/\n/,'')

      #trim whitespace
      pid.strip!

      #fedora_object = ActiveFedora::Base.find(pid, :cast => true)
      
      #ALL DATASTREAMS
      @all_ds.each do |datastream|
         #build uri
         uri = URI.parse("#{@fedora_url}#{pid}/datastreams/#{datastream}")
         http = Net::HTTP.new(uri.host, uri.port)
         #build request
         request = Net::HTTP::Get.new(uri.request_uri)
         #add auth
         request.basic_auth(@fedora_username, @fedora_password)
         #run the request
         response = http.request(request)
         
         #if the datastream is does not exist, log
         if response.code.eql? "404" or response.code.eql? "500"
            if object_logged 
               @missing_ds_aggregate_logger.debug("#{pid}:#{datastream} 404")
            else
               #get accession nbr to add to log
               accession_nbr = get_accession_nbr(pid)
               #log to aggregate log and pid log
               @missing_ds_aggregate_logger.debug("#{pid}:#{datastream} 404")
               @missing_ds_pid_logger.debug("#{pid}|#{accession_nbr}")
            end
            object_logged = true
         end
       end
       
       if !object_logged
         @complete_object_pid_logger.debug("#{pid}")
       end
     
      puts get_accession_nbr(pid)
       
      #if img_ds?(img)
       # img_ds_missing << pid
      #end

      # Check for the other DC'S
      #if !img.datastreams["VRA"].present?
       # vra_ds_missing << pid
      #end

      #if !img.datastreams["RELS-EXT"].present?
        #rels_ext_ds_missing << pid
     # end

      # Check for missing work.
    rescue StandardError => s
      @error_logger.error(s.message)
    rescue Exception => e
      @error_logger.error(e.message)
    end
    
  end

rescue StandardError => s
  @error_logger.error(s.message)
rescue Exception => e
  @error_logger.error(e.message)
    
end

#def image_ds?(img)
 # img_ds = ["DELIV-OPS", "ARCHV-IMG", "ARCHV-EXIF", "ARCHV-TECHMD", "DELIV-IMG", "DELIV-TECHMD"]

  #img_ds.each do |ds|
  #  if !img.datastreams[ds].present?
    #  return false
    #end
  #end
  #true
#end