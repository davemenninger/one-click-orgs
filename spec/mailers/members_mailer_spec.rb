require 'spec_helper'

describe MembersMailer do
  before :each do
    stub_constitution!
    stub_organisation!
    
    @member = @organisation.members.make
    @new_password = "foo"
  end
  
  describe "notify_new_password" do
    before do
      @mail = MembersMailer.notify_new_password(@member, @new_password)
    end
      
    it "should include welcome phrase and password in email text" do    
      @mail.body.should =~ /Dear #{@member.name}/
      @mail.body.should =~ /#{@new_password}/            
    end
  
    it "should include login link in email text" do
      @mail.body.should =~ %r{http://test.oneclickorgs.com/login}            
    end
  end
  
  describe "welcome_new_member" do
    before do
      @mail = MembersMailer.welcome_new_member(@member, @new_password)
    end
    
    it "should include welcome phrase and password in email text" do          
      @mail.body.should =~ /Dear #{@member.name}/
      @mail.body.should =~ /#{@new_password}/            
    end
  
    it "should include login link in email text" do
      @mail.body.should =~ %r{http://test.oneclickorgs.com/login}            
    end
  end
end
