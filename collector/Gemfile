source :rubygems

gem "rake"
gem "nats"
gem "vcap_common"
gem "vcap_logging"
gem "aws-sdk", :require => false
gem "dogapi", "~> 1.6.0"

group :test do
  gem "rspec"

  gem "ci_reporter"

  gem "rcov", :platforms => :ruby_18
  gem "rcov_analyzer", ">= 0.2", :platforms => :ruby_18

  gem "simplecov", :platforms => :ruby_19
  gem "simplecov-clover", :platforms => :ruby_19
  gem "simplecov-rcov", :platforms => :ruby_19
end
