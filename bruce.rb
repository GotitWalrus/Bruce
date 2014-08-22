#!/usr/bin/ruby
# -*- encoding: utf-8 -*-

require 'youtube_it'
require 'htmlentities'
require 'cinch'
require 'open-uri'
require 'uri'
require 'json'
require 'net/https'

bot = Cinch::Bot.new do
	configure do |c|
		c.server = "irc.smoothirc.net"
		c.channels = ["#photo", "#culture"]
		c.nick = "Bruce"
		c.encoding = "UTF-8"

		$youtube = YouTubeIt::Client.new 
		$decoder = HTMLEntities.new
	
		# Lastfm API key
		# get your own at http://www.lastfm.fr/api/account/create	
		$api_key = ""

	end

	helpers do
		def youtube_search(query)
			results = $youtube.videos_by(:query => query, :max_results => 1)

			return results.videos[0]
		end

		def youtube_parse_title(id)
			result = $youtube.video_by(id)

			return result
		end

		def link_parse_title(link)
			return if ((link.include? "youtube.com") || (link.include? "youtu.be"))
			begin
				title = open(link).read =~ /<title>(.*?)<\/title>/
				return $decoder.decode($1)
			rescue Exception => e
			end
		end

		def get_current_song(user)
			parsed = JSON.parse(open("http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&user=" + user + "&api_key=" + $api_key + "&format=json&limit=1").read)['recenttracks']['track']
			begin
				return parsed['artist']['#text'] + " - " + parsed['name']
			rescue Exception => e
				begin
					return parsed[0]['artist']['#text'] + " - " + parsed[0]['name']
				rescue Exception => e
					return "Sorry, something went wrong!"
				end
			end
		end
	end

	on :channel, /^!yt (.+)/i do |m, query|
		video = youtube_search(query)
		if video 
			if video.duration > 60*60 
				m.reply "http://youtube.com/watch?v=#{video.unique_id} :: #{video.title} :: Duration : #{Time.at(video.duration).gmtime.strftime("%H:%M:%S")} :: Views : #{video.view_count}"
			else
				m.reply "http://youtube.com/watch?v=#{video.unique_id} :: #{video.title} :: Duration : #{Time.at(video.duration).gmtime.strftime("%M:%S")} :: Views : #{video.view_count}"
			end
		else
			m.reply "No results."
		end
	end

	on :channel, /(?:(http[s]?:\/\/)?(?:www\.)?youtube.*watch\?v=([a-zA-Z0-9\-_]+))/i do |m, link, id|
		video = youtube_parse_title(id)
		if video.duration > 60*60 
			m.reply "#{video.title} :: Duration : #{Time.at(video.duration).gmtime.strftime("%H:%M:%S")} :: Views : #{video.view_count}"
		else
			m.reply "#{video.title} :: Duration : #{Time.at(video.duration).gmtime.strftime("%M:%S")} :: Views : #{video.view_count}"
		end
	end

	on :channel, /^!lfm (.+)/i do |m, cuser|
		m.reply get_current_song(cuser)
	end

	on :channel, /((https?:\/\/)?(www.)?(([a-zA-Z0-9\-]){2,}\.){1,4}([a-zA-Z]){2,6}(\/([a-zA-Z\-_\/\.0-9#:?=&~;,\+%]*)?)?)/i do |m, link|
		m.reply link_parse_title(link)
	end

	on :channel, /^!help/ do |m|
		m.user.send "Available commands are : !yt, !lfm, !si, !citation. You can tell me a YouTube URL on a channel, I will text you back the title."
	end

	on :channel, /^!citation/ do |m|
		open("http://www.citation-et-proverbe.fr/random").read =~ /<meta name="twitter:title" content="(.*)" \/>/i
		msg = $decoder.decode($1)

		m.reply msg
	end

	on :channel, /^!si/ do |m|
		open("http://www.savoir-inutile.com/index.php").read =~ /<h2\sid="phrase".+\W>(.*)<\/h2>/
		msg = $decoder.decode($1)

		m.reply msg
	end
end
bot.start

