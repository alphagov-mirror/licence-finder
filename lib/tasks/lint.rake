desc "Run govuk-lint with similar params to CI"
task "lint" do
  sh "bundle exec rubocop --format clang app spec lib"
end
