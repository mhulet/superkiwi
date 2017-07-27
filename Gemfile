source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

ruby "~> 2.3.0"

gem "rails",                    "~> 5.1.2"
gem "pg",                       "~> 0.21.0"
gem "puma",                     "~> 3.7"

gem "awesome_print"
gem "coffee-rails",             "~> 4.2"
gem "devise",                   "~> 4.3.0"
gem "kaminari-bootstrap"
gem "sass-rails",               "~> 5.0"
gem "shopify_api",              "~> 4.9.0"
gem "sidekiq",                  "~> 5.0.4"
gem "simple_form",              "~> 3.5.0"
gem "slim",                     "~> 3.0.8"
gem "turbolinks",               "~> 5"
gem "uglifier",                 ">= 1.3.0"

group :development, :test do
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  gem "better_errors"
  gem "listen",                 ">= 3.0.5", "< 3.2"
  gem "spring"
  gem "spring-watcher-listen",  "~> 2.0.0"
  gem "web-console",            ">= 3.3.0"
end

group :production do
  gem "heroku-deflater"
  gem "rails_12factor"
end
