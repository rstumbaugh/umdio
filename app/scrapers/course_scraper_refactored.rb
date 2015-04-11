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
  Nokogiri::HTML(open(department))
    .search('div.course')
    .map do |e|
      id = e.attr('id')
      holder += "#{id},"
    end
    list_of_queries.push("https://ntst.umd.edu/soc/#{department}/sections?courseIds=#{holder}")
end




# url = "https://ntst.umd.edu/soc/201508/sections?courseIds=AASP100,AASP100H,AASP101,AASP187,AASP200,AASP202,AASP202H,AASP274,AASP297,AASP298I,AASP298Z,AASP303,AASP305,AASP310,AASP386,AASP396,AASP397,AASP398A,AASP398C,AASP398D,AASP398G,AASP398Q,AASP402,AASP441,AASP443,AASP478A,AASP478B,AASP498K,AASP498Q,AASP498W,AASP499N,"

# Nokogiri::HTML(open(url))
#   .search('div.course-sections')
#   .map do |e|
#     puts e.attr('id')
#   end
