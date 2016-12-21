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
	# semesters.push(year + '01')
	# semesters.push(year + '05')
	semesters.push(year + '08')
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

def utf_safe text
  if !text.valid_encoding?
    text = text.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
  end
  text
end

depts.each { |semester, dept_arr|
	puts "Getting all courses for semester #{semester}"
	courses = []
	coll = db.collection('testing')
	bulk = coll.initialize_unordered_bulk_op
	dept_arr.each { |dept|
		puts "Getting courses for #{dept}"

		url = base_url + "#{semester}/#{dept}"
		page = Nokogiri::HTML(open(url), nil, "UTF-8")

  		dept_name = page.search('span.course-prefix-name').text.strip


		page.search('div.course').each { |course|
			course_id = course.search('div.course-id').text
			course_title = course.search('span.course-title').text
			credits = course.search('span.course-min-credits').text

			approved = course.search('div.approved-course-texts-container')
			other = course.search('div.course-texts-container')

			if approved.css('> div').length > 1 then 
				text = approved.css('> div:first-child').text.strip + other.css('> div').text.strip
			else 
				text = other.css('> div').text.strip
			end

			text = utf_safe text

			match = /Prerequisite: ([^.]+\.)/.match(text)
			text = match ? text.gsub(match[0], '') : text
			prereq = match ? match[1] : nil


			match = /Corequisite: ([^.]+\.)/.match(text)
			text = match ? text.gsub(match[0], '') : text
			coreq = match ? match[1] : nil

			match = /(?:Restricted to)|(?:Restriction:) ([^.]+\.)/.match(text)
			text = match ? text.gsub(match[0], '') : text
			restrictions = match ? match[1] : nil

			match = /Credit (?:(?:only )|(?:will be ))?granted for(?: one of the following)?:? ([^.]+\.)/.match(text)
			text = match ? text.gsub(match[0], '') : text
			credit_granted_for = match ? match[1] : nil

			match = /Also offered as:? ([^.]+\.)/.match(text)
			text = match ? text.gsub(match[0], '') : text
			also_offered_as = match ? match[1] : nil


			match = /Formerly:? ([^.]+\.)/.match(text)
			text = match ? text.gsub(match[0], '') : text
			formerly = match ? match[1] : nil

			match = /Additional information: ([^.]+\.)/.match(text)
			text = match ? text.gsub(match[0], '') : text
			additional_info = match ? match[1] : nil

			if approved.css('> div').length > 0 then

				description = utf_safe approved.css('> div:last-child').text.strip.gsub(/\t|(\r\n)/, '')
				additional_info = additional_info ? additional_info += ' '+text : text
				additional_info = additional_info && additional_info.strip.empty? ? nil : additional_info.strip

			elsif other.css('> div').length > 0 then
				description = text.strip.empty? ? nil : text.strip
			end

			relationships = {
				prereqs: prereq,
				coreqs: coreq,
				restrictions: restrictions,
				credit_granted_for: credit_granted_for,
				also_offered_as: also_offered_as,
				formerly: formerly,
				additional_info: additional_info 
			}

			courses << {
				course_id: course_id,
				name: course_title,
				dept_id: dept,
				department: dept_name,
				semester: semester,
				credits: course.css('span.course-min-credits').first.content,
				grading_method: course.at_css('span.grading-method abbr') ? 
								course.at_css('span.grading-method abbr').attr('title').split(', ') : [],
				core: utf_safe(course.css('div.core-codes-group').text).gsub(/\s/, '').delete('CORE:').split(','),
				gen_ed: utf_safe(course.css('div.gen-ed-codes-group').text).gsub(/\s/, '').delete('General Education:').split(','),
				description: description,
				relationships: relationships
			}
		}
	}

	courses.each { |course|
		bulk.find({course_id: course[:course_id]}).upsert.update({ "$set" => course })
	}
	bulk.execute
}




















