require 'rexml/document'

log_file = ARGV[0] || 'funit.log'
output_file = ARGV[1] || 'junit-report.xml'

tests = []
expected_tests = {}
current_mod = nil
current_scenario = nil
start_timestamp = 0.0
timestamp = 0.0
message = nil

File.readlines(log_file).each do |line|
  line = line.strip

  # End of tests and scenario
  if match = line.match(/__FUNIT__(.+)__====END====/)
    current_scenario = nil
    current_mod = nil
    next
  end

  # Start of scenario
  if match = line.match(/____SCENARIO____:\s*(.+)/)
    current_scenario = match[1].strip
    next
  elsif not current_scenario
    next
  end
  
  if match = line.match(/^(\d\.\d{3})/)
    timestamp = match[1].to_f
  end

  # Start of tests
  if match = line.match(/__FUNIT__(.+)__====BEGIN (\d+) TESTS====/)
    current_mod = match[1].strip
    expected_count = match[2].to_i
    start_timestamp = timestamp
    expected_tests[current_mod] ||= 0
    expected_tests[current_mod] += expected_count
    message = ""
    next
  end

  # Test result
  if match = line.match(/__FUNIT__(.+)__(SUCCESS|FAILURE|ERROR|SKIPPED)__(.+)/)
    mod_name  = match[1]
    status    = match[2]
    test_name = match[3].strip

    tests << {
      mod:      mod_name,
      scenario: current_scenario || "unknown",
      name:     test_name,
      status:   status,
      time:     timestamp - start_timestamp,
      message:  message
    }

    start_timestamp = timestamp
    message = ""
    next
  end

  if not current_mod
    next
  end
  
  if match = line.match(/__FUNIT__.+__(.+)/)
    message << "\n" << match[1]
  else
    message << "\n" << line
  end
end

missing_tests = 0
expected_tests.each do |mod, expected|
  actual = tests.count { |t| t[:mod] == mod }
  missing_tests += (expected - actual)
end

doc = REXML::Document.new
doc << REXML::XMLDecl.new("1.0", "UTF-8")

testsuites = REXML::Element.new("testsuites")
doc.add_element(testsuites)

tests.group_by { |t| t[:mod] }.each do |mod_name, mod_tests|
  mod_failures = mod_tests.count { |t| t[:status] == "FAILURE" }
  mod_errors   = mod_tests.count { |t| t[:status] == "ERROR" }
  mod_skipped = 0
  mod_time = 0.0

  testsuite = REXML::Element.new("testsuite")
  testsuite.add_attribute("name", "funit.#{mod_name}")
  testsuite.add_attribute("tests", mod_tests.size.to_s)
  testsuite.add_attribute("failures", mod_failures.to_s)
  testsuite.add_attribute("errors", mod_errors.to_s)

  mod_tests.group_by { |t| t[:scenario] }.each do |scenario_name, scenario_tests|
    scenario_failures = scenario_tests.count { |t| t[:status] == "FAILURE" }
    scenario_errors   = scenario_tests.count { |t| t[:status] == "ERROR" }
    scenario_skipped  = scenario_tests.count { |t| t[:status] == "SKIPPED" }
    scenario_time = 0.0

    sub_suite = REXML::Element.new("testsuite")
    sub_suite.add_attribute("name", scenario_name)
    sub_suite.add_attribute("tests", scenario_tests.size.to_s)
    sub_suite.add_attribute("failures", scenario_failures.to_s)
    sub_suite.add_attribute("errors", scenario_errors.to_s)
    sub_suite.add_attribute("skipped", scenario_skipped.to_s)

    scenario_tests.each do |test|
      testcase = REXML::Element.new("testcase")
      testcase.add_attribute("classname", "#{mod_name}.#{scenario_name}")
      testcase.add_attribute("name", test[:name])
      testcase.add_attribute("time", test[:time])
      scenario_time += test[:time]

      if test[:status] == "FAILURE"
        failure = REXML::Element.new("failure")
        failure.add_attribute("message", "Test failure")
        failure.add_attribute("type", "AssertionFailed")
        failure.add_text(REXML::CData.new(test[:message])) if test[:message] && !test[:message].empty?
        testcase.add_element(failure)
      elsif test[:status] == "ERROR"
        error = REXML::Element.new("error")
        error.add_attribute("message", "Test error")
        error.add_attribute("type", "RuntimeError")
        error.add_text(REXML::CData.new(test[:message])) if test[:message] && !test[:message].empty?
        testcase.add_element(error)
      end

      if test[:message] && !test[:message].empty?
        system_out = REXML::Element.new("system-out")
        system_out.add_text(REXML::CData.new(test[:message]))
        testcase.add_element(system_out)
      end

      sub_suite.add_element(testcase)
    end

    mod_skipped += scenario_skipped
    mod_time += scenario_time
    sub_suite.add_attribute("time", scenario_time.to_s)
    testsuite.add_element(sub_suite)
  end

  testsuite.add_attribute("skipped", mod_skipped)
  testsuite.add_attribute("time", mod_time)
  testsuites.add_element(testsuite)
end

File.open(output_file, "w") do |f|
  formatter = REXML::Formatters::Pretty.new(2)
  formatter.compact = true
  formatter.write(doc, f)
end

passed = tests.count { |t| t[:status] == "SUCCESS" }
failed = tests.count { |t| t[:status] == "FAILURE" }
errored = tests.count { |t| t[:status] == "ERROR" }

puts "JUnit report generated: #{output_file}"
puts "   Total tests: #{tests.size} | Passed: #{passed} | Failures: #{failed} | Errors: #{errored}"

if missing_tests > 0
  puts "#{missing_tests} expected tests did not run!"
  exit 1
end

exit 1 if failed > 0 || errored > 0
exit 0