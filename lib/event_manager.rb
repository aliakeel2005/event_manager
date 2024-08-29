require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
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
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'you can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"
  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(number)
  arr_number = number.to_s.chars
  unwanted_characters = ['-', '(', ')', ' ', '.']
  arr_number.reject! do |element|
    unwanted_characters.include?(element)
  end
  case arr_number.length

  when 0..9
    arr_number = 'phone number unavailable'
  when 11
    if arr_number[0] == '1'
      arr_number.shift
    else
      arr_number = 'phone number unavailable'
    end
  when 10

  else
    arr_number = 'phone number unavailable'
  end
  arr_number = arr_number.join if arr_number.is_a?(Array)
  arr_number
end

contents = CSV.open('event_attendees.csv',
                    headers: true,
                    header_converters: :symbol)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new(template_letter)
sum_of_dates = 0
sum_of_time = 0
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  phone_number = row[:homephone]
  reg_date = row[:regdate]
  sum_of_dates += 1

  # to find average, convert all reg_date(s) to seconds
  # find the sum of all reg_date(s)
  # divide by how many reg_date(s) there is
  sum_of_time += Time.strptime(reg_date, '%m/%d/%y').to_i

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislator_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)

  clean_number = clean_phone_number(phone_number)
  puts "#{name} #{clean_number} #{reg_date}"
end
# to find average registration date
seconds = sum_of_time / sum_of_dates
p Time.at(seconds).strftime('%m/%d/%y')
