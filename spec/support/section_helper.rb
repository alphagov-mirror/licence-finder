module SectionHelper
  def selector_of_section(section_name)
    case section_name
    when "completed questions"
      [:css, ".done-questions"]
    when /^completed question (\d+)$/
      # [:xpath, "//*[contains(@class, 'done-questions')]//li[contains(@class, 'done')][.//*[contains(@class, 'gem-c-heading')][text() = '#{$1}']]"]
      [:xpath, "//*[contains(@class, 'done-questions')]//li[contains(@class, 'done')][.//*[contains(@class, 'gem-c-heading')][starts-with(text(), '#{Regexp.last_match(1)}.')]]"]

    when "current question"
      [:css, ".step.current"]

    when "upcoming questions"
      [:css, ".upcoming-questions"]

    when "outcome"
      [:css, "article.outcome"]

    when /^list item containing (.*)$/
      [:xpath, ".//li[contains(., '#{Regexp.last_match(1)}')]"]
    else
      raise "Can't find mapping from \"#{section_name}\" to a section."
    end
  end

  def within_section(section_name, &block)
    within(*selector_of_section(section_name), &block)
  end
end

RSpec.configuration.include SectionHelper, type: :request
