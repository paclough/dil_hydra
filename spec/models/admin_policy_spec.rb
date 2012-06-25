require 'spec_helper'

describe AdminPolicy do
  its(:defaultRights) { should be_kind_of Hydra::Datastream::RightsMetadata}
  its(:rightsMetadata) { should be_kind_of Hydra::Datastream::RightsMetadata}
  its(:descMetadata) { should be_kind_of ActiveFedora::QualifiedDublinCoreDatastream}

  describe "when setting attributes" do
    before do
      subject.title = "My title" 
      subject.description = "My description" 
      subject.license_title = "My license" 
      subject.license_description = "My license desc" 
      subject.license_url = "My url" 
    end
    its(:title) { should == "My title"}
    its(:description) { should == "My description"}
    its(:license_title) { should == "My license"}
    its(:license_description) { should == "My license desc"}
    its(:license_url) { should == "My url"}
  end
    


end