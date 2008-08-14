require 'erb'
require 'spec/runner/formatter/base_text_formatter'

module Spec
  module Runner
    module Formatter
      module Story
        class HtmlFormatter < BaseTextFormatter
          include ERB::Util
          
          def initialize(options, where)
            super
            @previous_type = nil
            @scenario_text = ""
            @story_text = ""
            @scenario_failed = false
            @story_failed = false

            @successful_scenario_count = 0
            @pending_scenario_count = 0
            @failed_scenarios = []
            @pending_steps = []
          end
          
          def run_started(count)
            @count = count
            @output.puts <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html 
  PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
  <head>
    <title>Stories</title>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta http-equiv="Expires" content="-1" />
    <meta http-equiv="Pragma" content="no-cache" />
    <script src="javascripts/prototype.js" type="text/javascript"></script>
    <script src="javascripts/scriptaculous.js" type="text/javascript"></script>
    <script src="javascripts/rspec.js" type="text/javascript"></script>
    <link href="stylesheets/rspec.css" rel="stylesheet" type="text/css" />
  </head>
  <body>
    <div id="container">
EOF
          end

          def collected_steps(steps)
            unless steps.empty?
              @output.puts "      <ul id=\"stock_steps\" style=\"display: none;\">"
              steps.each do |step|
                @output.puts "        <li>#{step}</li>"
              end
              @output.puts "      </ul>"
            end
          end

          def run_ended
            @output.puts <<-EOF
     <p class='trace'>
EOF
            
            @output.puts "#@count scenarios: #@successful_scenario_count succeeded, #{@failed_scenarios.size} failed, #@pending_scenario_count pending <br/>"
            unless @pending_steps.empty?
              @output.puts "\nPending Steps: <br/>"
              @pending_steps.each_with_index do |pending, i|
                story_name, scenario_name, msg = pending
                @output.puts "#{i+1}) #{story_name} (#{scenario_name}): #{msg} <br/>"
              end
            end
            unless @failed_scenarios.empty?
              @output.print "\nFAILURES: <br/>"
              @failed_scenarios.each_with_index do |failure, i|
                title, scenario_name, err = failure
                @output.print %[
                    #{i+1}) #{title} (#{scenario_name}) FAILED
                    #{err.class}: #{err.message}
                    #{err.backtrace.join("<br/>\n")}
                    ' <br/>'    
                ]
              end
            end            

            @output.puts <<-EOF
      </p>
    </div>
  </body>
</head>
EOF
          end
          
          def story_started(title, narrative)
            @story_failed = false
            @story_text = <<-EOF 
        <dt>Story: #{h title}</dt>
        <dd>
          <p>
            #{h(narrative).split("\n").join("<br />")}
          </p>
EOF
          end

          def story_ended(title, narrative)     
            if @story_failed
              @output.puts <<-EOF
      <dl class="story failed">
EOF
            else
              @output.puts <<-EOF
      <dl class="story passed">
EOF
            end
              @output.puts <<-EOF
#{@story_text}
        </dd>
      </dl>
EOF
          end
     
          def scenario_started(story_title, scenario_name)
            @previous_type = nil
            @scenario_failed = false
            @scenario_text = <<-EOF
              <dt>Scenario: #{h scenario_name}</dt>
              <dd>
                <ul class="steps">
EOF
          end

          def scenario_ended
            if @scenario_failed
              @story_text += <<-EOF
            <dl class="failed">
EOF
            else
              @story_text += <<-EOF
            <dl class="passed">
EOF
            end
            
            @story_text += <<-EOF
#{@scenario_text}
                </ul>
              </dd>
            </dl>
EOF
          end
          
          def found_scenario(type, description)
          end

          def scenario_succeeded(story_title, scenario_name)
            @successful_scenario_count += 1            
            scenario_ended
          end

          def scenario_pending(story_title, scenario_name, reason)
            @pending_scenario_count += 1 unless @scenario_already_failed
            @scenario_pending = true
            @scenario_already_failed = true
            scenario_ended
          end

          def scenario_failed(story_title, scenario_name, err)
            @failed_scenarios << [story_title, scenario_name, err] unless @scenario_already_failed            
            @scenario_already_failed = true
            @scenario_failed = true
            @story_failed = true
            scenario_ended
          end

          def step_upcoming(type, description, *args)
          end

          def step_succeeded(type, description, *args)
            print_step('passed', type, description, *args) # TODO: uses succeeded CSS class
          end

          def step_pending(type, description, *args)
            @pending_steps << [@current_story_title, @current_scenario_name, description]
            @scenario_pending = true
            @scenario_ok = false            
            print_step('pending', type, description, *args)
          end

          def step_failed(type, description, *args)
            print_step('failed', type, description, *args)
          end
          
          def print_step(klass, type, description, *args)
            spans = args.map { |arg| "<span class=\"param\">#{arg}</span>" }
            desc_string = description.step_name
            arg_regexp = description.arg_regexp           
            inner = if(type == @previous_type)
              "And "
            else
              "#{type.to_s.capitalize} "
            end
            i = -1
            inner += desc_string.gsub(arg_regexp) { |param| spans[i+=1] }
            
            @scenario_text += "                  <li class=\"#{klass}\">#{inner}</li>\n"
            
            if type == :'given scenario'
              @previous_type = :given
            else
              @previous_type = type
            end
            
          end
        end
      end
    end
  end
end
