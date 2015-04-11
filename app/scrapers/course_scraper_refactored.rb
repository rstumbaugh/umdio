require 'open-uri'
require 'nokogiri'

list_of_semesters = ['201401', '201405', '201408', '201412', '201501', '201505', '201508', '201512']

department_pages = []
list_of_queries = []


# get section ids
list_of_semesters.each do |semester|
  base_url = "https://ntst.umd.edu/soc/#{semester}"

  Nokogiri::HTML(open(base_url))
    .search('span.prefix-abbrev')
    .map do |e|
      department_pages.push("https://ntst.umd.edu/soc/#{semester}/#{e.text}")
    end

end

# get course page classes, assemble the queries
department_pages.each do |department|
  holder = ''
  curr_department = department.split('/soc/')[1][0,6] #hack

  Nokogiri::HTML(open(department))
    .search('div.course')
    .map do |e|
      holder += "#{e.attr('id')},"
    end
    list_of_queries.push("https://ntst.umd.edu/soc/#{curr_department}/sections?courseIds=#{holder}")
end


# Nokogiri::HTML(open(url))
#   .search('div.course-sections')
#   .map do |e|
#     puts e.attr('id')
#   end
