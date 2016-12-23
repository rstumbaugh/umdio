# temp scraper to find open seat info

require 'open-uri'
require 'nokogiri'
require 'mongo'

include Mongo

host = 'localhost'
port = MongoClient::DEFAULT_PORT

puts "Connecting to #{host} at port #{port}"
db_class = MongoClient.new(host, port, pool_size: 2, pool_timeout: 2).db('umdclass')
db_test = MongoClient.new(host, port, pool_size: 2, pool_timeout: 2).db('testing')

# Architecture:
# build list of queries
semesters_to_check = ["courses201601", "courses201605", "courses201608", "courses201612"]
course_collections = semesters_to_check.map { |e| db_class.collection(e) }
section_queries = []
course_collections.each do |c|
	semester = c.name.scan(/courses(.+)/)[0]
	if not semester.nil?
		semester = semester[0]
		c.find({},{fields: {_id:0,course_id:1}}).to_a
		.each_slice(200){|a| 
			section_queries << 
		"https://ntst.umd.edu/soc/#{semester}/sections?courseIds=#{a.map{|e| e['course_id']}.join(',')}"}
	end
end

puts "added all urls"

# separate by collections by semester (prof201608)
# store in a hash of course id => array of sections?
# for now, just store array of course ids

section_queries.each do |query|
	page = Nokogiri::HTML(open(query))
	prof_coll = db_test.collection("testing")
	bulk = prof_coll.initialize_unordered_bulk_op


	semester = query.scan(/soc\/(.+)\//)[0][0]
	course_divs = page.search('div.course-sections')


	profs = {}

	course_divs.each do |course_div|
		course_id = course_div.attr('id')

		course_div.search('div.section').each do |section|
			instructors = section.search('span.section-instructors').text.gsub(/\t|\r\n/,'').encode('UTF-8', :invalid => :replace).split(',').map(&:strip)
			puts "#{course_id}: #{instructors}"
		end
	end


end




















