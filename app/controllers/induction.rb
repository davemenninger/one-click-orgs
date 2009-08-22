class Induction < Application
  layout :induction
  
  skip_before :ensure_organisation_active
  
  # UNDER CONSTRUCTION
  
  before :ensure_organisation_under_construction, :exclude => [:confirm_agenda, :founding_meeting, :confirm_founding_meeting, :restart_induction]

  def founder
    @founder = Member.first || Member.new
    render
  end
  
  def create_founder
    @founder = Member.first || Member.new
    @founder.attributes = params[:member]
    @founder.save
    redirect(url(:action => 'organisation_details'))
  end
  
  def organisation_details
    @organisation_name = (Clause.get_current('organisation_name') ? Clause.get_current('organisation_name').text_value : nil)
    @objectives = (Clause.get_current('objectives') ? Clause.get_current('objectives').text_value : nil)
    @assets = (Clause.get_current('assets') ? Clause.get_current('assets').boolean_value : true)
    # @assets = (@assets? "checked" : nil)
    render
  end
  
  def create_organisation_details
    organisation_name = Clause.get_current('organisation_name') || Clause.new(:name => 'organisation_name')
    organisation_name.text_value = params[:organisation_name]
    organisation_name.save
    
    objectives = Clause.get_current('objectives') || Clause.new(:name => 'objectives')
    objectives.text_value = params[:objectives]
    objectives.save
    
    assets = Clause.get_current('assets') || Clause.new(:name => assets)
    assets.boolean_value = params[:assets]
    assets.save
    
    redirect(url(:action => 'members'))
  end
  
  def members
    # Find the first five members after the founding member,
    # creating new empty members as necessary.
    @members = Member.all
    @members.shift
    while @members.length < 5 do
      @members.push(Member.new)
    end
    render
  end
  
  def create_members
    params[:members].each_value do |member_params|
      if !member_params[:name].blank? && !member_params[:email].blank?
        if member_params[:id].blank?
          member = Member.new
          member.new_password!
        else
          member = Member.get!(member_params[:id])
        end
        member.name = member_params[:name]
        member.email = member_params[:email]
        member.save
      elsif !member_params[:id].blank?
        # We get here if the name and email fields have been cleared
        # for a memeber that's already been saved to the database.
        # Treat this as a deletion.
        Member.get!(member_params[:id]).destroy
      end
    end
    redirect(url(:action => 'voting_settings'))
  end
  
  def voting_settings
    @voting_period = (Clause.get_current('voting_period') ? Clause.get_current('voting_period').integer_value : 259200)
    @general_voting_system = (Clause.get_current('general_voting_system') ? Clause.get_current('general_voting_system').text_value : "RelativeMajority")
    @membership_voting_system = (Clause.get_current('membership_voting_system') ? Clause.get_current('membership_voting_system').text_value : "AbsoluteTwoThirdsMajority")
    @constitution_voting_system = (Clause.get_current('constitution_voting_system') ? Clause.get_current('constitution_voting_system').text_value : "AbsoluteTwoThirdsMajority")
    render
  end
  
  def create_voting_settings
    voting_period = Clause.get_current('voting_period') || Clause.new(:name => 'voting_period')
    voting_period.integer_value = params[:voting_period]
    voting_period.save
    
    general_voting_system = Clause.get_current('general_voting_system') || Clause.new(:name => 'general_voting_system')
    general_voting_system.text_value = params[:general_voting_system]
    general_voting_system.save
    
    membership_voting_system = Clause.get_current('membership_voting_system') || Clause.new(:name => 'membership_voting_system')
    membership_voting_system.text_value = params[:membership_voting_system]
    membership_voting_system.save
    
    constitution_voting_system = Clause.get_current('constitution_voting_system') || Clause.new(:name => 'constitution_voting_system')
    constitution_voting_system.text_value = params[:constitution_voting_system]
    constitution_voting_system.save
    
    redirect(url(:action => 'preview_constitution'))
  end
  
  def preview_constitution
    set_up_instance_variables_for_constitution_view
    render
  end
  
  def founding_meeting_details
    @founding_meeting_date = Clause.get_current('founding_meeting_date') ? Clause.get_current('founding_meeting_date').text_value : nil
    @founding_meeting_time = Clause.get_current('founding_meeting_time') ? Clause.get_current('founding_meeting_time').text_value : nil
    @founding_meeting_location = Clause.get_current('founding_meeting_location') ? Clause.get_current('founding_meeting_location').text_value : nil
    render
  end
  
  def create_founding_meeting_details
    founding_meeting_date = Clause.get_current('founding_meeting_date') || Clause.new(:name => 'founding_meeting_date')
    founding_meeting_date.text_value = params[:date]
    founding_meeting_date.save
    
    founding_meeting_time = Clause.get_current('founding_meeting_time') || Clause.new(:name => 'founding_meeting_time')
    founding_meeting_time.text_value = params[:time]
    founding_meeting_time.save
    
    founding_meeting_location = Clause.get_current('founding_meeting_location') || Clause.new(:name => 'founding_meeting_location')
    founding_meeting_location.text_value = params[:location]
    founding_meeting_location.save
    
    redirect(url(:action => 'preview_agenda'))
  end
  
  def preview_agenda
    render
  end
    
  # Sends the constitution and agenda to founding members,
  # and moves the organisation to 'pending' state.
  def confirm_agenda
  end
  
  # PENDING STATE
  
  before :ensure_organisation_pending, :only => [:confirm_agenda, :founding_meeting, :confirm_founding_meeting, :restart_induction]
  
  # Form to confirm that the founding meeting happened,
  # and select which founding members voted in favour.
  def founding_meeting
    render
  end
  
  # Remove any founding members that did not vote in favour,
  # and move organisation to 'active' state.
  def confirm_founding_meeting
  end
  
  # Moves the organisation back from 'pending' state, to
  # allow editing of org details.
  def restart_induction
  end

private

  def ensure_organisation_under_construction
    if Organisation.pending?
      throw :halt, redirect(url(:action => 'founding_meeting'))
    elsif Organisation.active?
      throw :halt, redirect(url(:controller => 'one_click', :action => 'control_centre'))
    end
  end
  
  def ensure_organisation_pending
    if Organisation.under_construction?
      throw :halt, redirect(url(:action => 'founder'))
    elsif Organisation.active?
      throw :halt, redirect(url(:controller => 'one_click', :action => 'control_centre'))
    end
  end

end
