# temp scraper to find open seat info

require 'open-uri'
require 'nokogiri'
require 'mongo'

include Mongo

host = 'localhost'
port = MongoClient::DEFAULT_PORT

puts "Connecting to #{host} at port #{port}"
db_class = MongoClient.new(host, port, pool_size: 2, pool_timeout: 2).db('umdclass')

# Architecture:
# build list of queries
course_collections = db_class.collection_names().select { |e| e.include?('courses') }.map { |name| db_class.collection(name) }
section_queries = []
course_collections.each do |c|
  semester = c.name.scan(/courses(.+)/)[0]
  if not semester.nil?
    semester = semester[0]
    c.find({},{fields: {_id:0,course_id:1}}).to_a
      .each_slice(200){|a| section_queries << 
        "https://ntst.umd.edu/soc/#{semester}/sections?courseIds=#{a.map{|e| e['course_id']}.join(',')}"}
  end
end

puts "added all urls"


# separate by collections by semester (prof201608)
# store in a hash of course id => array of sections?
# for now, just store array of course ids

section_queries.each do |query|
  	semester = query.scan(/soc\/(.+)\//)[0][0]
	page = Nokogiri::HTML(open(query))
	prof_coll = db_class.collection("profs#{semester}");
	bulk = prof_coll.initialize_unordered_bulk_op


	semester = query.scan(/soc\/(.+)\//)[0][0]
	course_divs = page.search('div.course-sections')


	profs = {}

	course_divs.each do |course_div|
		course_id = course_div.attr('id')

		puts "Getting prof for #{course_id} (#{semester})"

		course_div.search('div.section').each do |section|
			instructors = section.search('span.section-instructors').text.gsub(/\t|\r\n/,'').encode('UTF-8', :invalid => :replace).split(',')
			instructors.map!(&:strip)
			instructors.each do |x| 
				profs[x] ||= []
				profs[x] |= [course_id]
			end
		end
	end

	profs.sort.to_h.each do |name, courses|
		# push all courses to prof's entry
		bulk.find({name: name}).upsert.update(
			{"$set" => {name: name, semester: semester},
			 "$addToSet" => {course: {"$each" => courses} }
			}
	)
	end
	bulk.execute unless profs.empty?
end




















