class Parser
  attr_reader :count_pending_msgs, :get_msgs, :get_friend_prog, :get_friend_score, :post_users, :get_users, \
              :max_dyno, :mean, :median, :modes

  Line = Struct.new(:method, :path, :host, :fwd, :dyno, :connect, :service)

  LOG_FORMAT = /method=(\S+) path=(\S+) host=(\S+) fwd=(\S+) dyno=(\S+) connect=(\d+)ms service=(\d+)ms/

  def initialize(file_path)
    @file_path = file_path
    @dynos = Hash.new(0)
    @response_times = Hash.new(0)
    @max_dyno = nil
    @mean = @median = 0
    @modes = []             # there can be more than one mode
    @total_elements = 0
    @count_pending_msgs = 0
    @get_msgs = 0
    @get_friend_prog = 0
    @get_friend_score = 0
    @post_users = 0
    @get_users = 0
    parse
  end

  def parse
    if File.exist?(@file_path)
      open_file_and_parse
    else
      puts 'File does not exists.'
    end
  end

  def parse_line line
    line.match(LOG_FORMAT) { |m| Line.new(*m.captures) }
  end

  def open_file_and_parse
    @total_elements = 0
    File.open(@file_path).each do |line|
      @total_elements += 1
      data = parse_line(line)
      @dynos[data[:dyno]] += 1
      response_time = data[:connect].to_i + data[:service].to_i
      @response_times[response_time] += 1
      api_parser(data[:method], data[:path])
    end
    unless @total_elements == 0
      max_dyno
      compute_stats
    end
    print_results
  end

  def max_dyno
    @max_dyno = @dynos.max_by{ |key, value| value }[0]
  end

  def is_count_pending_messages method
    !!method.match(/api\/users\/[0-9]+\/count_pending_messages/)
  end

  def is_get_messages method
    !!method.match(/api\/users\/[0-9]+\/get_messages/)
  end

  def is_friends_progress method
    !!method.match(/api\/users\/[0-9]+\/get_friends_progress/)
  end

  def is_friends_score method
    !!method.match(/api\/users\/[0-9]+\/get_friends_score/)
  end

  def is_users method
    !!method.match(/api\/users\/[0-9]+/)
  end

  def api_parser method, path
    if method == 'GET'
      if is_count_pending_messages  path
        @count_pending_msgs += 1
      elsif is_get_messages path
        @get_msgs += 1
      elsif is_friends_progress path
        @get_friend_prog += 1
      elsif is_friends_score path
        @get_friend_score += 1
      elsif is_users path
        @get_users += 1
      end
    elsif method == 'POST'
      if is_users path
        @post_users += 1
      end
    end
  end

  def compute_stats
    @response_times = @response_times.sort.to_h
    mean
    mode
    median
  end

  def median
    cumm_sum = 0
    if @total_elements % 2 != 0
      median_pos = (@total_elements + 1) / 2
      @response_times.each do |key, value|
        cumm_sum += value
        if cumm_sum >= median_pos
          @median = key
          break
        end
      end
    else
      first_median_pos = @total_elements / 2
      second_median_pos = @total_elements / 2 + 1
      index = -1
      first_median = nil
      @response_times.each do |key, value|
        index += 1
        cumm_sum += value
        if cumm_sum >= first_median_pos
          first_median = key
          break
        end
      end
      second_median = cumm_sum >= second_median_pos ? first_median : @response_times.keys[index + 1]
      @median = (first_median + second_median) / 2
    end
  end

  def mode
    max_frequency = @response_times.max_by{ |key, value| value }[1]
    @response_times.each do |key, value|
      @modes << key if value == max_frequency
    end
  end

  def mean
    mean_numerator = 0
    @response_times.each do |key, value|
      mean_numerator += key * value
    end
    @mean = mean_numerator / @total_elements
  end

  def print_results
    puts "GET /api/users/{user_id}/count_pending_messages: #{@count_pending_msgs}"
    puts "GET /api/users/{user_id}/get_messages: #{@get_msgs}"
    puts "GET /api/users/{user_id}/get_friends_progress: #{@get_friend_prog}"
    puts "GET /api/users/{user_id}/get_friends_score: #{@get_friend_score}"
    puts "POST /api/users/{user_id}: #{@post_users}"
    puts "GET /api/users/{user_id}: #{@get_users}"
    puts "Mean of Response Time: #{@mean}"
    puts "Median of Response Time: #{@median}"
    puts "Mode(s) of Response Time: #{@modes}"
    puts "Max Responding Dyno: #{@max_dyno}"
  end
end
