require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe PortableContacts::Client do
  
  def access_token
    @access_token ||= mock("accesstoken")
  end
  
  before(:each) do
    @client = PortableContacts::Client.new "http://sample.com/portable_contacts", access_token
  end
  
  ["/@me/@all", "/@me/@all/(id)", "/@me/@self"].each do |path|
    
    it "should generate url for #{path}" do
      @client.send( :url_for, path).should=="http://sample.com/portable_contacts#{path}"
    end
    
  end
    
  it "should return empty string for no options" do
    @client.send(:options_for).should==""
  end
  
  describe "fields" do
    it "should handle all" do
      @client.send(:options_for, :fields=>:all).should=="?fields=@all"
    end

    it "should handle single field" do
      @client.send(:options_for, :fields=>:name).should=="?fields=name"
    end
    
    it "should handle array of fields" do
      @client.send(:options_for, :fields=>[:name,:emails,:nickname,:id]).should=="?fields=name,emails,nickname,id"      
    end

  end
  
  describe "filtering" do
    
    it "should handle default operation" do
      @client.send(:options_for, :filter=>{:by=>:name,:value=>"Bob"}).should=="?filterBy=name&filterOp=equals&filterValue=Bob"
    end
    
    ["displayName","id","nickname"].each do |field|
      ["equals", "contains", "startsWith", "present"].each do |op|
        
        it "should create filter for #{field} with #{op}" do
          @client.send(:options_for, :filter=>{:by=>field, :op=>op, :value=>"bb"}).should=="?filterBy=#{field}&filterOp=#{op}&filterValue=bb"          
        end

      end
    end
  end

  describe "sorting" do
    
    it "should handle straight sort" do
      @client.send(:options_for, :sort=>:name).should=="?sortBy=name"
    end

    it "should handle sort as a hash" do
      @client.send(:options_for, :sort=>{:by=>:name}).should=="?sortBy=name"
    end

    it "should handle sort as a hash" do
      @client.send(:options_for, :sort=>{:by=>:name,:order=>:descending}).should=="?sortBy=name&sortOrder=descending"
    end
    
  end
  
  describe "paging" do
    
    it "should handle count" do
      @client.send(:options_for, :count=>133).should=="?count=133"
    end

    it "should handle startIndex" do
      @client.send(:options_for, :start_index=>20).should=="?startIndex=20"
    end

    it "should handle count with startIndex" do
      @client.send(:options_for, :count=>10,:start_index=>40).should=="?count=10&startIndex=40"
    end

  end
  
  it "should handle all parameters at once" do
    @client.send(:options_for, 
      :fields=>[:name,:emails,:nickname,:id],
      :filter=>{:by=>:name,:value=>"Bob"},
      :sort=>{:by=>:name,:order=>:descending},
      :count=>10,:start_index=>40).should=="?count=10&fields=name,emails,nickname,id&filterBy=name&filterOp=equals&filterValue=Bob&sortBy=name&sortOrder=descending&startIndex=40"
  end

  describe "Rails Specific" do
    require 'activesupport'

    it "should handle all parameters at once with string keys" do    
      @client.send(:options_for, 
      'fields'=>['name','emails','nickname','id'],
      'filter'=>{'by'=>'name','value'=>"Bob"},
      'sort'=>{'by'=>'name','order'=>'descending'},
      'count'=>10,'start_index'=>40).should=="?count=10&fields=name,emails,nickname,id&filterBy=name&filterOp=equals&filterValue=Bob&sortBy=name&sortOrder=descending&startIndex=40"
    end
  end

  describe "parsing" do
    
    def parse_json_file(name)
      File.open File.join(File.dirname(__FILE__),'fixtures', name) do |f|
        JSON.parse f.read
      end
    end
    
    describe "single entry response" do
      before(:each) do
        @entry = @client.send(:single,parse_json_file('single.json'))
      end
      
      it "should contain displayName" do
        @entry.display_name.should=="Mork Hashimoto"
      end
      
      it "should contain tags" do
        @entry.tags.should == [
          "plaxo guy",
          "favorite"
        ]
      end
      
      it "should emails" do
        @entry.emails.should == [
          {
            "value"=> "mhashimoto-04@plaxo.com",
            "type"=> "work",
            "primary"=> "true"
          },
          {
            "value"=> "mhashimoto-04@plaxo.com",
            "type"=> "home"
          },
          {
            "value"=> "mhashimoto@plaxo.com",
            "type"=> "home"
          }
        ]
      end
      
      it "should have email" do
        @entry.email.should=="mhashimoto-04@plaxo.com"
      end
    end

    describe "multiple entries" do
      before(:each) do
        @entries = @client.send(:collection,parse_json_file('multiple.json'))
      end
      
      it "should have correct start index" do
        @entries.start_index.should == 10
      end
      
      it "should have correct per page" do
        @entries.per_page.should == 10
      end
      
      it "should have correct total entries" do
        @entries.total_entries.should == 12
      end
      
      it "should have 2 enties" do
        @entries.length.should==2
      end
      
      describe "first entry" do
        
        before(:each) do
          @entry=@entries.first
        end
        
        it "should have correct id" do
          @entry.id.should=="123"
        end
        
        it "should contain displayName" do
          @entry.display_name.should=="Minimal Contact"
        end
        
      end
      
      # The same as data in single entry
      describe "last entry" do
        
        before(:each) do
          @entry=@entries.last
        end
        it "should contain displayName" do
          @entry.display_name.should=="Mork Hashimoto"
        end
      
        it "should contain tags" do
          @entry.tags.should == [
            "plaxo guy",
            "favorite"
          ]
        end
      
        it "should emails" do
          @entry.emails.should == [
            {
              "value"=> "mhashimoto-04@plaxo.com",
              "type"=> "work",
              "primary"=> "true"
            },
            {
              "value"=> "mhashimoto-04@plaxo.com",
              "type"=> "home"
            },
            {
              "value"=> "mhashimoto@plaxo.com",
              "type"=> "home"
            }
          ]
        end
      
        it "should have email" do
          @entry.email.should=="mhashimoto-04@plaxo.com"
        end
      end
    end
  end
end
