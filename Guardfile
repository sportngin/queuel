# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'bundler' do
  watch('Gemfile')
  watch(/^.+\.gemspec/)
end

guard :cane do
  watch(%r{^lib/.+\.rb$})
end

guard 'rspec',
  all_on_start: true,
  keep_failed: true,
  rvm: ["1.9.3-p392@queuel"] do
  # would like to add "jruby-1.7.3@queuel", "rbx-head@queuel"
  watch(%r{^spec/.+\.rb$})                  { "spec" }
  watch(%r{^lib/queuel/base/(.+)\.rb$})     { |m| ["spec/lib/queuel/iron_mq/#{m[1]}_spec.rb", "spec/lib/queuel/null/#{m[1]}_spec.rb"] }
  watch(%r{^lib/(.+)\.rb$})                 { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')              { "spec" }
end
