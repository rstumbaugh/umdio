# temp scraper to find open seat info

require 'open-uri'
require 'nokogiri'
require 'mongo'

include Mongo

host = 'localhost'
port = MongoClient::DEFAULT_PORT

puts "Connecting to #{host} at port #{port}"
db = MongoClient.new(host, port, pool_size: 2, pool_timeout: 2).db("testing")

# list of years to scrape passed as param from Rakefile
years = ARGV

# get all semesters in each year
semesters = []
years.each { |year|
	semesters.push(year + '01')
	# semesters.push(year + '05')
	# semesters.push(year + '08')
	# semesters.push(year + '12')
}

puts "semesters: #{semesters}"

# base url for schedule of classes
base_url = "https://ntst.umd.edu/soc/"


# make hash of semester => list of departments
depts = {}
num_depts = 0
semesters.each { |semester|
	depts[semester] = []
	puts "Searching for departments in term #{semester}"

	url = base_url + semester
	Nokogiri::HTML(open(url)).search('span.prefix-abbrev').each { |dept_abbrev|
		depts[semester].push dept_abbrev.text
		num_depts += 1
	}

	puts "#{num_depts} departments found so far..."
}


depts.each { |semester, dept_arr|
	puts "Getting all courses for semester #{semester}"
	courses = []
	dept_arr.each { |dept|
		#puts "Getting courses for #{dept}"
		url = base_url + "#{semester}/#{dept}"

		if dept == "CMSC" then
			puts "opening url to #{url}"
			page = Nokogiri::HTML(open(url))

			page.search('div.course').each { |course|
				course_id = course.search('div.course-id').text
				course_title = course.search('span.course-title').text
				credits = course.search('span.course-min-credits').text

				description = course.search('div.approved-course-texts-container').text + course.search('div.course-texts-container').text
				description = description.strip.gsub(/[\n\r\t]/, '')

				if course_id == "CMSC330" then
					prereq = /Prerequisite: ([^.]+)/.match(description)[1]
				end
			}
		end
	}
}

















