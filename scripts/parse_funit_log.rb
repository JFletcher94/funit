require 'rexml/document'

log_file = ARGV[0] || 'funit.log'
output_file = ARGV[1] || 'junit-report.xml'

tests = []
expected_tests = {}
current_mod = nil
current_scenario = nil

File.readlines(log_file).each do |line|
  line = line.strip

  if match = line.match(/__FUNIT__([^=]+)====BEGIN (\d+) TESTS====/)
    current_mod = match[1].strip
    expected_count = match[2].to_i
    expected_tests[current_mod] ||= 0
    expected_tests[current_mod] += expected_count
    next
  end

  if match = line.match(/____SCENARIO____:\s*(.+)/)
    current_scenario = match[1].strip
  end

  if match = line.match(/__FUNIT__([^_]+)__([A-Z]+)__(.+)/)
    mod_name  = match[1]
    status    = match[2]
    test_name = match[3].strip

    tests << {
      mod:      mod_name,
      scenario: current_scenario || "unknown",
      name:     test_name,
      status:   status,
      time:     0.0
    }
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

  testsuite = REXML::Element.new("testsuite")
  testsuite.add_attribute("name", "funit.#{mod_name}")
  testsuite.add_attribute("tests", mod_tests.size.to_s)
  testsuite.add_attribute("failures", mod_failures.to_s)
  testsuite.add_attribute("errors", mod_errors.to_s)
  testsuite.add_attribute("skipped", "0")
  testsuite.add_attribute("time", "0")

  mod_tests.group_by { |t| t[:scenario] }.each do |scenario_name, scenario_tests|
    scenario_failures = scenario_tests.count { |t| t[:status] == "FAILURE" }
    scenario_errors   = scenario_tests.count { |t| t[:status] == "ERROR" }

    sub_suite = REXML::Element.new("testsuite")
    sub_suite.add_attribute("name", scenario_name)
    sub_suite.add_attribute("tests", scenario_tests.size.to_s)
    sub_suite.add_attribute("failures", scenario_failures.to_s)
    sub_suite.add_attribute("errors", scenario_errors.to_s)
    sub_suite.add_attribute("skipped", "0")
    sub_suite.add_attribute("time", "0")

    scenario_tests.each do |test|
      testcase = REXML::Element.new("testcase")
      testcase.add_attribute("classname", "#{mod_name}.#{scenario_name}")
      testcase.add_attribute("name", test[:name])
      testcase.add_attribute("time", test[:time])

      if test[:status] == "FAILURE"
        failure = REXML::Element.new("failure")
        failure.add_attribute("message", "Test failed")
        failure.add_attribute("type", "AssertionFailed")
        testcase.add_element(failure)
      elsif test[:status] == "ERROR"
        error = REXML::Element.new("error")
        error.add_attribute("message", "Test errored")
        error.add_attribute("type", "RuntimeError")
        testcase.add_element(error)
      end

      sub_suite.add_element(testcase)
    end

    testsuite.add_element(sub_suite)
  end

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