class BotController < ApplicationController

  def send_message(chat_id, message, reply_to_id = nil)
    response = HTTP.get("https://api.telegram.org/bot#{Rails.application.credentials.bot_api!}/sendMessage", params: {chat_id: chat_id, text: message, reply_to_message_id: reply_to_id})
    if response.status.success?
      debug("Message sent: #{message}\nResponse: #{response.body}")
    else
      debug("Error sending message: #{message}\nError: #{response.body}")
    end
  end

  def debug(message)
    if Rails.configuration.debug
      print("#{message}\n")
    end
  end

  def start
    debug("New /start from #{params[:message][:chat][:first_name]}")
    send_message(params[:message][:chat][:id], "Howdy #{params[:message][:from][:first_name]}.\nI am the bot for CambFurs admins to help administrate our telegram chats.\nTo get started, please send /help to view a list of all commands.")
  end

  def approve
    debug("Admin approval request from #{params[:message][:from][:first_name]}")
    message = ""
    if params[:message][:from][:id] == Rails.application.credentials.owner_id!
      if params[:message][:reply_to_message].present?
        if !User.where(user_id: params[:message][:reply_to_message][:text]).none?
          user = User.find_by(user_id: params[:message][:reply_to_message][:text])
          user.approved = true
          if user.save
            message = "Approving admin request for #{user.username}."
            send_message(params[:message][:reply_to_message][:text], "You have been approved for admin access! Welcome!")
          else
            message = "Uh oh, something went wrong. Unable to approve admin"
          end
        else
          message = "Admin request not found!"
        end
      else
        message = "You must reply to a message in order to use this command."
      end
    else
      message = "Only my owner can use this command. Sorry! 😢"
    end
    send_message(params[:message][:chat][:id], message)
  end

  def revoke
    debug("Admin revoke request from #{params[:message][:from][:first_name]} for #{params[:message][:reply_to_message].present? ? params[:message][:reply_to_message][:text] : params[:message][:text].delete_prefix("/revoke ")}")
    message = ""
    if params[:message][:from][:id] == Rails.application.credentials.owner_id!
      if params[:message][:reply_to_message].present? || !params[:message][:text].delete_prefix("/revoke ").start_with?("/revoke")
        user_id = params[:message][:reply_to_message].present? ? params[:message][:reply_to_message][:text] : params[:message][:text].delete_prefix("/revoke ")
        if !User.where(user_id: user_id).none?
          user = User.find_by(user_id: user_id)
          user.approved = false
          if user.save
            message = "Revoking admin access for #{user.username}."
            send_message(user_id, "Admin access revoked. If you want to become an admin again, you will have to re-apply")
          else
            message = "Something went wrong, unable to revoke access for #{user.username}."
          end
        else
          message = "Admin not found, unable to revoke access."
        end
      else
        message = "You must reply to a message or specify the user_id in order to use this command."
      end
    else
      message = "Only my owner can use this command. Sorry! 😢"
    end
    send_message(params[:message][:chat][:id], message)
  end

  def apply
    debug("Admin application request from #{params[:message][:from][:first_name]}")
    message = ""
    if User.where(user_id: params[:message][:from][:id], approved: true).none?
      new_user = User.where(user_id: params[:message][:from][:id]).none? ? User.create(username: params[:message][:from][:first_name], user_id: params[:message][:from][:id], approved: false) : User.find_by(user_id: params[:message][:from][:id])
      message = "Admin request sent, please wait for approval."
      send_message(Rails.application.credentials.owner_id!, "New admin request for #{new_user.username}.\nTo approve, please reply to next message with /approve")
      send_message(Rails.application.credentials.owner_id!, "#{new_user.user_id}")
    else
      message = "You are already an admin, no need to apply again."
    end
    send_message(params[:message][:chat][:id], message)
  end

  def help
    debug("Help message")
    send_message(params[:message][:chat][:id], "This bot is for CambFurs admins to help administrate our Telegram chats.\nInitial available commands:\n\/help - This message\n\/start - Initial welcome message\n\/apply - Send a request to become an admin\n\nOnce approved, you can use the following commands:\n\/list_admins - List all admins and their user_id\n\/list_messages - List of all messages\n\/edit_message - Edit a message which I post\n\/blacklist - List all words on the blacklist\n\/add_blacklist - Add a word to the blacklist\n\/remove_blacklist - Remove a word from the blacklist\n\nOnly my owner can use these commands:\n\/approve - Approve an admin\n\/revoke user_id - Revoke admin access\n\/add_message - add a new message to the system for me to use\n\/delete_message - Delete a message from my memory")
  end

  def list_admins
    debug("Admin list request from #{params[:message][:from][:first_name]}")
    message = "List of current admins:"
    if !User.where(user_id: params[:message][:from][:id], approved: true).none?
      User.where(approved: true).each do |user|
        message += "\n#{user.username}: #{user.user_id}"
      end
    else
      message = "Sorry, only admins can use this command."
    end
    send_message(params[:message][:chat][:id], message)
  end

  def list_messages
    debug("Message list request from #{params[:message][:from][:first_name]}")
    message = "List of current messages:"
    if !User.where(user_id: params[:message][:from][:id], approved: true).none?
      Message.all.each do |single_message|
        message += "\n#{single_message.message_id} - #{single_message.message}"
      end
    else
      message = "Sorry, only admins can use this command."
    end
    send_message(params[:message][:chat][:id], message)
  end

  def add_message
    debug("New message request from #{params[:message][:from][:first_name]}")
    message = ""
    if params[:message][:from][:id] == Rails.application.credentials.owner_id!
      message = "Reply to this message with the new message in the format:\nmessage_name - message"
    else
      message = "Only my owner can use this command. Sorry! 😢"
    end
    send_message(params[:message][:chat][:id], message)
  end

  def new_message
    debug("New message response from #{params[:message][:from][:first_name]}, message #{params[:message][:text]}")
    message = ""
    if params[:message][:from][:id] == Rails.application.credentials.owner_id!
      message_parts = params[:message][:text].split(" - ")
      if message_parts.length > 1
        new_message = Message.create(message_id: message_parts[0], message: message_parts[1..-1].join(" - "))
        message = "New message created:\n#{new_message.message_id} - #{new_message.message}"
      else
        message = "Message in incorrect format"
      end
    else
      message = "Only my owner can use this command. Sorry! 😢"
    end
    send_message(params[:message][:chat][:id], message)
  end

  def delete_message
    debug("Delete message request from #{params[:message][:from][:first_name]}")
    message = ""
    if params[:message][:from][:id] == Rails.application.credentials.owner_id!
      message = "Reply to this message with the message_name you'd like to delete."
    else
      message = "Only my owner can use this command. Sorry! 😢"
    end
    send_message(params[:message][:chat][:id], message)
  end

  def destroy_message
    debug("Delete message response from #{params[:message][:from][:first_name]}, for message #{params[:message][:text]}")
    message = ""
    if params[:message][:from][:id] == Rails.application.credentials.owner_id!
      if !Message.where(message_id: params[:message][:text]).none?
        if Message.find_by(message_id: params[:message][:text]).destroy
          message = "Message deleted!"
        else
          message = "Issue deleting message."
        end
      else
        message = "Unable to find message to delete."
      end
    else
      message = "Only my owner can use this command. Sorry! 😢"
    end
    send_message(params[:message][:chat][:id], message)
  end

  def edit_message
    debug("Edit message request from #{params[:message][:from][:first_name]}")
    message = ""
    if !User.where(user_id: params[:message][:from][:id], approved: true).none?
        message = "Reply to this message with the edited message in the format:\nmessage_name - message"
    else
      message = "Sorry, only admins can use this command."
    end
    send_message(params[:message][:chat][:id], message)
  end

  def save_message
    debug("Edit message response from #{params[:message][:from][:first_name]}, for message #{params[:message][:text]}")
    message = ""
    if !User.where(user_id: params[:message][:from][:id], approved: true).none?
      message_parts = params[:message][:text].split(" - ")
      if message_parts.length > 1
        if !Message.where(message_id: message_parts[0]).none?
          edited_message = Message.find_by(message_id: message_parts[0])
          edited_message.message = message_parts[1..-1].join(" - ")
          if edited_message.save
            message = "Saved edited message."
          else
            message = "Unable to save new message."
          end
        else
          message = "Unable to find message to edit."
        end
      else
        message = "Incorrect format for edited message."
      end
    else
      message = "Only my owner can use this command. Sorry! 😢"
    end
    send_message(params[:message][:chat][:id], message)
  end

  def blacklist

  end

  def add_blacklist

  end

  def remove_blacklist

  end

  def parse_details(message, username = "")
    message = Message.find_by(message_id: "lobby_welcome").message
    message = message.gsub(/{username}/, username)
    return message
  end

  def index
    if params[:message].present? && params[:message][:from][:id] == params[:message][:chat][:id] # Ensure message came from private chat

      if params[:message][:entities].present? && params[:message][:entities][0][:type] == "bot_command"
        case params[:message][:text]
          when /^\/start/ # Initial start/welcome message
            start
          when /^\/approve/ # Approve admin request
            approve
          when /^\/revoke/ # Revoke admin access
            revoke
          when /^\/apply/ # Apply to gain admin access
            apply
          when /^\/help/ # List all commands
            help
          when /^\/list_admins/ # List all admins
            list_admins
          when /^\/blacklist/ # List all words on the blacklist
            #list blacklist
          when /^\/add_blacklist/ # Add word to blacklist
            #add to blacklist
          when /^\/remove_blacklist/ # Remove word from blacklist
            #remove from blacklist
          when /^\/list_messages/ # List all configurable messages
            list_messages
          when /^\/add_message/ # Add configurable message
            add_message
          when /^\/delete_message/ # Remove configurable message
            delete_message
          when /^\/edit_message/ # Edit configurable message
            edit_message
          else
            send_message(params[:message][:chat][:id], "Sorry, command not found")
        end
      elsif params[:message][:reply_to_message].present? && params[:message][:reply_to_message][:from][:username] == Rails.application.credentials.bot_username! # Reply to bot
        case params[:message][:reply_to_message][:text]
          when /^Reply to this message with the new message in the format:/
            new_message
          when /^Reply to this message with the message_name you'd like to delete./
            destroy_message
          when /^Reply to this message with the edited message in the format:/
            save_message
          else
            send_message(params[:message][:chat][:id], "I'm sorry, I don't quite understand")
        end
      end
    elsif params[:chat_member].present? && params[:chat_member][:new_chat_member].present? && params[:chat_member][:new_chat_member][:status] == "member" # Check for new chat member
      debug("New user entered the lobby")
      User.where(approved: true).each do |user|
        send_message(user.user_id, "New user in the CambFurs lobby:\n#{params[:chat_member][:new_chat_member][:user][:first_name]}")
      end
      send_message(params[:chat_member][:chat][:id], parse_details("lobby_welcome", params[:chat_member][:new_chat_member][:user][:first_name]))
    end
  end

end
