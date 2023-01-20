namespace :bot do

    desc "Send meet reminders"
    task :send_meets => [:environment] do |task, args|
        today_meets = Meet.where("meet_date = ?", Date.today)
        tomorrow_meets = Meet.where("meet_date = ?", Date.today+1.day)
        next_week_meets = Meet.where("meet_date = ?", Date.today+1.week)

        today_meets.each do |meet|
            HTTP.get("https://api.telegram.org/bot#{Rails.application.credentials.bot_api!}/sendMessage", params: {chat_id: Rails.application.credentials.main_id!, text: "Todays the day!\n\nThe meet is now starting #{meet.in_person ? "at" : "on"} #{meet.location}.#{"\n#{Rails.application.credentials.virtual_url!}" if !meet.in_person}\n\n#{meet.notes}"})
        end

        tomorrow_meets.each do |meet|
            HTTP.get("https://api.telegram.org/bot#{Rails.application.credentials.bot_api!}/sendMessage", params: {chat_id: Rails.application.credentials.main_id!, text: "Hi everyone! Just a quick reminder that the meet is tomorrow!\n\nThe meet will be #{meet.in_person ? "at" : "on"} #{meet.location} starting from 12:00/noon.#{"\n#{Rails.application.credentials.virtual_url!}" if !meet.in_person}\n\n#{meet.notes}"})
            HTTP.get("https://api.telegram.org/bot#{Rails.application.credentials.bot_api!}/sendPoll", params: {chat_id: Rails.application.credentials.main_id!, question: "Will you be attending the meet?", options: "[\"Yes\", \"Likely\", \"Not sure\", \"Unlikely\", \"No\"]", is_anonymous: false})
        end

        next_week_meets.each do |meet|
            HTTP.get("https://api.telegram.org/bot#{Rails.application.credentials.bot_api!}/sendMessage", params: {chat_id: Rails.application.credentials.main_id!, text: "Meet Reminder time!\n\nThe meet for #{meet.meet_date.strftime("%B")} will be next week on #{meet.meet_date.strftime("%d/%m/%Y")}.\n\nThe meet will be starting #{meet.in_person ? "at" : "on"} #{meet.location} from 12:00/noon.#{"\n#{Rails.application.credentials.virtual_url!}" if !meet.in_person}\n\n#{meet.notes}"})
            HTTP.get("https://api.telegram.org/bot#{Rails.application.credentials.bot_api!}/sendPoll", params: {chat_id: Rails.application.credentials.main_id!, question: "Will you be attending the meet?", options: "[\"Yes\", \"Likely\", \"Not sure\", \"Unlikely\", \"No\"]", is_anonymous: false})
        end
    end

end