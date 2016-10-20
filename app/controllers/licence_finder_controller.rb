require 'services'

class LicenceFinderController < ApplicationController
  SEPARATOR = '_'.freeze
  QUESTIONS = [
    'What is your activity or business?',
    'What would you like to do?',
    'Where will you be located?',
  ].freeze
  ACTIONS = %w(sectors activities business_location).freeze

  # These are the correlation_ids
  # POPULAR_LICENCE_IDS = %w(1083741799 1083741393 1084158580 1075329003 1084062657 1075429257 1083741306)
  # These are the legal_ref_ids (mapped from the correlation_ids above)
  # POPULAR_LICENCE_IDS = %w(1620001 1040001 590001 1520001 1520002 1160001 1170001)
  # These are the gds_ids (mapped from the legal_ref_ids above)
  POPULAR_LICENCE_IDS = %w(1071-5-1 1071-3-1 390-7-1 521-5-1 521-3-1 860-5-1 860-3-1).freeze

  before_filter :load_artefact
  before_filter :extract_and_validate_sector_ids, except: [:start, :sectors, :browse_sector_index, :browse_sector, :browse_sector_child, :browse_sector_grandchild]
  before_filter :extract_and_validate_activity_ids, except: [:start, :sectors, :sectors_submit, :activities, :browse_sector_index, :browse_sector, :browse_sector_child, :browse_sector_grandchild]
  before_filter :set_expiry
  before_filter :setup_navigation_helpers

  def start
    setup_popular_licences
  end

  def sectors
    @picked_sectors = Sector.find_by_public_ids(extract_ids(:sector)).ascending(:name).to_a
    @sectors = if params[:q].present?
                 $search.search(params[:q])
               else
                 []
               end
    setup_questions
  end

  def activities
    @sectors = Sector.find_by_public_ids(@sector_ids)
    @activities = Activity.find_by_sectors(@sectors).ascending(:name)
    @picked_activities = Activity.find_by_public_ids(extract_ids(:activity)).order_by(name: :asc).to_a
    setup_questions [@sectors]
  end

  def business_location
    @sectors = Sector.find_by_public_ids(@sector_ids)
    @activities = Activity.find_by_public_ids(@activity_ids)
    setup_questions [@sectors, @activities]
  end

  # is this action necessary?
  def business_location_submit
    next_params = { sectors: @sector_ids.join(SEPARATOR), activities: @activity_ids.join(SEPARATOR) }
    if %w(england scotland wales northern_ireland).include? params[:location]
      redirect_to({ action: 'licences', location: params[:location] }.merge(next_params))
    else
      redirect_to({ action: 'business_location' }.merge(next_params))
    end
  end

  def licences
    @sectors = Sector.find_by_public_ids(@sector_ids)
    @activities = Activity.find_by_public_ids(@activity_ids)
    @location = params[:location]
    licences = Licence.find_by_sectors_activities_and_location(@sectors, @activities, params[:location])
    @licences = LicenceFacade.create_for_licences(licences)
    setup_questions [@sectors, @activities, [@location.titleize]]
  end

  def browse_sector_index
    @current_sector = nil
    @parent_sector = nil

    @child_sectors = []
    @grandchild_sectors = []

    @sectors = Sector.find_layer1_sectors.ascending(:name).to_a

    render "browse_sectors"
  end

  def browse_sector
    # return list of children of "sector"
    @current_sector = Sector.find_by_public_id(params[:sector])
    @parent_sector = nil

    @sectors = Sector.find_layer1_sectors.ascending(:name).to_a
    @child_sectors = @current_sector.children.ascending(:name).to_a
    @grandchild_sectors = []

    render "browse_sectors"
  end

  def browse_sector_child
    # return list of children of "sector"
    @current_sector = Sector.find_by_public_id(params[:sector])
    @parent_sector = Sector.find_by_public_id(params[:sector_parent])

    @sectors = Sector.find_layer1_sectors.ascending(:name).to_a
    @child_sectors = @parent_sector.children.ascending(:name).to_a
    @grandchild_sectors = @current_sector.children.ascending(:name).to_a

    render "browse_sectors"
  end

protected

  def setup_questions(answers = [])
    @current_question_number = answers.size + 1
    @completed_questions = QUESTIONS[0...(@current_question_number - 1)].zip(answers, ACTIONS)
    @current_question = QUESTIONS[@current_question_number - 1]
    @upcoming_questions = QUESTIONS[@current_question_number..-1]
  end

  def extract_and_validate_sector_ids
    # FIXME: the downstream router doesn't allow custom 404s, so
    # this won't show anything useful in production.
    @sector_ids = extract_ids(:sector)
    if @sector_ids.empty?
      render status: :not_found, text: ""
    end
  end

  def extract_and_validate_activity_ids
    @activity_ids = extract_ids(:activity)
    if @activity_ids.empty?
      render status: :not_found, text: ""
    end
  end

  def extract_ids(param_base)
    ids = []
    if params[param_base.to_s.pluralize].present?
      ids += params[param_base.to_s.pluralize].split(SEPARATOR).map(&:to_i).reject { |n| n < 1 }
    end
    ids.sort
  end

  def load_artefact
    @artefact = Services.content_api.artefact(APP_SLUG)
  rescue GdsApi::HTTPNotFound, GdsApi::HTTPGone
    Rails.logger.warn "No artefact for licence-finder application: #{APP_SLUG}"
    @artefact = nil
  end

  def setup_navigation_helpers
    @content_item = Services.content_store.content_item("/licence-finder").to_hash

    # Remove the organisations from the content item - this will prevent the
    # govuk:analytics:organisations meta tag from being generated until there is
    # a better way of doing this.
    if @content_item["links"]
      @content_item["links"].delete("organisations")
    end

    @navigation_helpers = GovukNavigationHelpers::NavigationHelper.new(@content_item)
    section_name = @content_item.dig("links", "parent", 0, "links", "parent", 0, "title")
    if section_name
      @meta_section = section_name.downcase
    end
  end

  def setup_popular_licences
    licences = POPULAR_LICENCE_IDS.map { |id| Licence.find_by_gds_id(id) }.compact
    @popular_licences = LicenceFacade.create_for_licences(licences).select(&:published?).first(3)
  end
end
