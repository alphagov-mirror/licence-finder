require 'capybara'

# Make sure Capybara doesn't automatically refresh the page
Capybara.automatic_reload = false

describe "Sector browse page" do
  before(:each) do
    @s1 = FactoryGirl.create(:sector, layer: 1, name: 'First top level')
    @s2 = FactoryGirl.create(:sector, layer: 2, name: 'First child', parents: [@s1])
    @s3 = FactoryGirl.create(:sector, layer: 3, name: 'First grand child', parents: [@s2])
    @s4 = FactoryGirl.create(:sector, layer: 2, name: 'Second child', parents: [@s1])
    @s5 = FactoryGirl.create(:sector, layer: 3, name: 'Second grand child', parents: [@s4])
    @s6 = FactoryGirl.create(:sector, layer: 1, name: 'Second top level')
  end

  specify "when browsing the main sectors page" do
    visit "/#{APP_SLUG}/browse-sectors"

    within "#sector-navigation" do
      expect(page).to have_css "li>a"
      expect(page).to have_content @s1.name
      expect(page).to have_content @s6.name
      expect(page).not_to have_content @s3.name
    end
  end

  specify "clicking through drills down the tree" do
    visit "/#{APP_SLUG}/browse-sectors"

    click_on @s1.name

    expect(page).to have_content @s2.name

    click_on @s2.name

    expect(page).to have_content @s3.name
  end

  specify "viewing a deeper URL has the correct content" do
    visit "/#{APP_SLUG}/browse-sectors/#{@s1.public_id}"

    expect(page).to have_content @s2.name
  end

  specify "sectors can be added from browse page" do
    visit "/#{APP_SLUG}/browse-sectors/#{@s1.public_id}/#{@s2.public_id}"

    click_on "Add"

    within '.picked-items' do
      expect(page).to have_content @s3.name
    end
  end

  specify "clicking on sectors fetches children", :js => true do
    visit "/#{APP_SLUG}/browse-sectors"

    expect(page).to have_content @s1.name
    expect(page).not_to have_content @s2.name

    within "#sector-navigation" do
      click_on @s1.name
    end

    expect(page).to have_content @s2.name
    expect(page).not_to have_content @s3.name

    within "#sector-navigation" do
      click_on @s2.name
    end

    expect(page).to have_content @s3.name
  end

  specify "clicking on sibling sectors collapses other sectors", :js => true do
    visit "/#{APP_SLUG}/browse-sectors"

    click_on @s1.name # first top level
    click_on @s2.name # first child
    click_on @s4.name # second child
    expect(page).to have_content @s5.name # second grand child
    expect(page).not_to have_content @s3.name # first grand child
  end

  specify "clicking on an open sector closes its children", :js => true do
    visit "/#{APP_SLUG}/browse-sectors"

    click_on @s1.name
    click_on @s2.name
    expect(page).to have_content @s3.name

    click_on @s2.name
    expect(page).not_to have_content @s3.name
  end

  specify "granchild sectors will have rel=\"nofollow\" attributes on 'Add' links", :js => true do
    visit "/#{APP_SLUG}/browse-sectors"

    click_on @s1.name
    expect(page).to have_content @s2.name

    click_on @s2.name
    expect(page).to have_content @s3.name

    all("a.add").each { |a| assert_equal "nofollow", a[:rel] }
  end
end
