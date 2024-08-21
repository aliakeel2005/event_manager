require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
template_letter = File.read('form_letter.html')
puts 'event manager initalized!'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislator_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
    rescue
      'you can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
    end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"
  File.open(filename, 'w') do |file|
    file.puts form_letter
  end

end

def phone_number(number)

end



contents = CSV.open('event_attendees.csv',
headers: true,
header_converters: :symbol)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new(template_letter)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
   phone_number = row[5]
   arr_number = phone_number.to_s.chars
   unwanted_characters = ["-", "(", ")", " ", "."]
   arr_number.reject! do |element|
    unwanted_characters.include?(element)
   end
   puts "Original phone number: #{phone_number}, Array: #{arr_number}"
   case arr_number.length

   when 0..9
    arr_number = "phone number unavailable"
   when 11
    if arr_number[0] == '1'
      arr_number.shift
      p arr_number
    else
      arr_number = "phone number unavailable"
    end
  when 10

  else
    arr_number = "phone number unavailable"
  end
  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislator_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)
  save_thank_you_letter(id,form_letter)
  puts "#{arr_number}"
end
