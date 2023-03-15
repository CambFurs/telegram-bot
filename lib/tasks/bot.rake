namespace :bot do

    desc "Send meet reminders"
    task :send_meets => [:environment] do |task, args|

        require 'icalendar'

        chat = Rails.application.credentials.main_id!

        credentials = Calendav::Credentials::Standard.new(
              host: "https://caladmin.cambfurs.co.uk",
              username: "user",
              password: "pass",
              authentication: :basic_auth
            )
        client = Calendav.client(credentials)
        calendars = client.calendars.list
        yesterday_meets = client.events.list(calendars[0].url, from: Time.now.beginning_of_day-1.day, to: Time.now.beginning_of_day)
        today_meets = client.events.list(calendars[0].url, from: Time.now.beginning_of_day, to: Time.now.beginning_of_day+1.day)
        tomorrow_meets = client.events.list(calendars[0].url, from: Time.now.beginning_of_day+1.day, to: Time.now.beginning_of_day+2.days)
        next_week_meets = client.events.list(calendars[0].url, from: Time.now.beginning_of_day+1.week, to: Time.now.beginning_of_day+1.week+1.day)

        yesterday_meets.each do |meet|
            raw_calendar = Icalendar::Calendar.parse(meet.calendar_data).first
            raw_meet = raw_calendar.events.first

            if raw_meet.summary.ical_params.count
                HTTP.get("https://api.telegram.org/bot#{Rails.application.credentials.bot_api!}/unpinChatMessage", params: {chat_id: chat, message_id: raw_meet.summary.ical_params[:post]})
            end
            raw_calendar.events.first.summary.ical_params = {}
            client.events.update(meet.url, raw_calendar.to_ical, etag: meet.etag)
        end

        today_meets.each do |meet|
            raw_calendar = Icalendar::Calendar.parse(meet.calendar_data).first
            raw_meet = raw_calendar.events.first

            if raw_meet.summary.ical_params.count
                HTTP.get("https://api.telegram.org/bot#{Rails.application.credentials.bot_api!}/unpinChatMessage", params: {chat_id: chat, message_id: raw_meet.summary.ical_params[:post]})
            end
            response = HTTP.get("https://api.telegram.org/bot#{Rails.application.credentials.bot_api!}/sendMessage", params: {chat_id: chat, text: "Todays the day!\n\nThe meet is now starting #{raw_meet.location != "Discord" ? "at" : "on"} #{raw_meet.location}.#{"\n#{Rails.application.credentials.virtual_url!}" if raw_meet.location == "Discord"}\n\n#{raw_meet.description}"})
            if response.status.success?
                raw_calendar.events.first.summary.ical_params = {post: response.parse["result"]["message_id"]}
                client.events.update(meet.url, raw_calendar.to_ical, etag: meet.etag)
                HTTP.get("https://api.telegram.org/bot#{Rails.application.credentials.bot_api!}/pinChatMessage", params: {chat_id: chat, message_id: response.parse["result"]["message_id"]})
            end
        end

        tomorrow_meets.each do |meet|
            raw_calendar = Icalendar::Calendar.parse(meet.calendar_data).first
            raw_meet = raw_calendar.events.first

            if raw_meet.summary.ical_params.count
                HTTP.get("https://api.telegram.org/bot#{Rails.application.credentials.bot_api!}/unpinChatMessage", params: {chat_id: chat, message_id: raw_meet.summary.ical_params[:post]})
            end
            response = HTTP.get("https://api.telegram.org/bot#{Rails.application.credentials.bot_api!}/sendMessage", params: {chat_id: chat, text: "Hi everyone! Just a quick reminder that the meet is tomorrow!\n\nThe meet will be #{raw_meet.location != "Discord" ? "at" : "on"} #{raw_meet.location} starting from 12:00/noon.#{"\n#{Rails.application.credentials.virtual_url!}" if raw_meet.location == "Discord"}\n\n#{raw_meet.description}"})
            if response.status.success?
                raw_calendar.events.first.summary.ical_params = {post: response.parse["result"]["message_id"]}
                client.events.update(meet.url, raw_calendar.to_ical, etag: meet.etag)
                HTTP.get("https://api.telegram.org/bot#{Rails.application.credentials.bot_api!}/pinChatMessage", params: {chat_id: chat, message_id: response.parse["result"]["message_id"]})
            end
            HTTP.get("https://api.telegram.org/bot#{Rails.application.credentials.bot_api!}/sendPoll", params: {chat_id: chat, question: "Will you be attending the meet?", options: "[\"Yes\", \"Likely\", \"Not sure\", \"Unlikely\", \"No\"]", is_anonymous: false})
        end

        next_week_meets.each do |meet|
            raw_calendar = Icalendar::Calendar.parse(meet.calendar_data).first
            raw_meet = raw_calendar.events.first

            response = HTTP.get("https://api.telegram.org/bot#{Rails.application.credentials.bot_api!}/sendMessage", params: {chat_id: chat, text: "Meet Reminder time!\n\nThe meet for #{raw_meet.dtstart.strftime("%B")} will be next week on #{raw_meet.dtstart.strftime("%d/%m/%Y")}.\n\nThe meet will be starting #{raw_meet.location != "Discord" ? "at" : "on"} #{raw_meet.location} from 12:00/noon.#{"\n#{Rails.application.credentials.virtual_url!}" if raw_meet.location == "Discord"}\n\n#{raw_meet.description}"})
            if response.status.success?
                raw_calendar.events.first.summary.ical_params = {post: response.parse["result"]["message_id"]}
                client.events.update(meet.url, raw_calendar.to_ical, etag: meet.etag)
                HTTP.get("https://api.telegram.org/bot#{Rails.application.credentials.bot_api!}/pinChatMessage", params: {chat_id: chat, message_id: response.parse["result"]["message_id"]})
            end
            HTTP.get("https://api.telegram.org/bot#{Rails.application.credentials.bot_api!}/sendPoll", params: {chat_id: chat, question: "Will you be attending the meet?", options: "[\"Yes\", \"Likely\", \"Not sure\", \"Unlikely\", \"No\"]", is_anonymous: false})
          end
    end

end