require 'spec_helper'

describe Proposal do
  
  before(:each) do
    Delayed::Job.delete_all 
        
    stub_constitution!  
    stub_organisation!
    stub_voting_systems!
    default_member_class
    
    @member = @organisation.members.make(:member_class => @default_member_class)
    
    @mail = mock('mail', :deliver => nil)
    
    ProposalMailer.stub!(:notify_creation).and_return(@mail)
    DecisionMailer.stub!(:notify_new_decision).and_return(@mail)
  end

  it "should close early proposals" do
    member_0, member_1, member_2 = @organisation.members.make_n(3, :member_class => @default_member_class)
    member_3, member_4 = @organisation.members.make_n(2, :created_at => Time.now + 1.day, :member_class => @default_member_class)
    
    proposal = @organisation.proposals.create!(:proposer_member_id => member_1.id, :title => 'test')            
    [member_0, member_1, member_2].each { |m| m.cast_vote(:for, proposal.id)}
    
    lambda {
      @organisation.proposals.close_early_proposals.should include(proposal)
    }.should change(Decision, :count).by(1)
    
    proposal.decision.should_not be_nil    
  end
  
  it "should close due proposals" do    
    proposal = @organisation.proposals.make(:proposer_member_id => @member.id, :close_date=>Time.now - 1.day)            
    @organisation.proposals.close_due_proposals.should include(proposal)
    
    proposal.reload
    proposal.should be_closed     
  end
  
  it "should send out an email to each member after a Proposal has been made" do
    @organisation.members.count.should >0
    lambda do
      @organisation.proposals.make(:proposer => @member)
    end.should change { Delayed::Job.count }.by(1)

    job = Delayed::Job.first
    job.payload_object.class.should   == Delayed::PerformableMethod
    job.payload_object.method.should  == :send_email_without_send_later
    job.payload_object.args.should    == []
  end
  
  # FIXME Decision internals should be in the Decision spec, not here
  it "should send out an email to each member after a Decision has been made" do
     @organisation.members.count.should >0

     lambda do
       p = @organisation.proposals.make(:proposer => @member)
       p.stub!(:passed?).and_return(true)
       p.close!
     end.should change { Delayed::Job.count }.by(2) #Decision + proposal
  end
  
  describe "to_event" do
    it "should list open proposals as 'proposal's" do
      @organisation.proposals.make(:open => true, :accepted => false).to_event[:kind].should == :proposal
    end
    
    it "should list closed, accepted proposals as 'proposal's" do
      @organisation.proposals.make(:open => false, :accepted => true).to_event[:kind].should == :proposal
    end
    
    it "should list closed, rejected proposals as 'failed proposal's" do
      proposal = @organisation.proposals.make(:accepted => false)
      proposal.open = false
      proposal.save
      proposal.open?.should be_false
      
      proposal.to_event[:kind].should == :failed_proposal
    end
  end
  
  describe "vote counting" do
    before(:each) do
      @proposal = @organisation.proposals.create
      3.times{Vote.create(:proposal => @proposal, :for => true)}
      4.times{Vote.create(:proposal => @proposal, :for => false)}
    end
    
    it "should count the for votes" do
      @proposal.votes_for.should == 3
    end
    
    it "should count the against votes" do
      @proposal.votes_against.should == 4
    end
  end
end
