class Check
  attr_accessor :runs, :created_at

  def initialize(url_strings: , created_at: DateTime.now)
    self.runs = []
    self.created_at = DateTime.now

    url_strings.each do |url_string|
      runs << CheckRun.new(url_string: url_string, created_at: self.created_at)
    end
  end

  def run_checks
    logger.debug("running checks")
    self.runs.each do |run|
      run.check
    end
  end

  def save!(database:)
    check_id = database.save_check(check: self)

    self.runs.each do |run|
      database.save_check_run(check_id: check_id, check_run: run)
    end
  end

  def status
    if self.runs.all?{|run| run.timeout }
      return "outage"
    elsif self.runs.any?{|run| run.timeout }
      return "partial_outage"
    else
      return "ok"
    end
  end
end

class CheckRun
  attr_accessor :uri, :response_time, :response_code, :timeout, :created_at

  include HTTParty


  def initialize(url_string:, created_at: DateTime.now)
    self.uri = self.class.parse_url_string(url: url_string)
    self.created_at = created_at
  end

  def self.parse_url_string(url:)
    URI(url)
  end

  def url
    self.uri.to_s
  end

  def timeout_int
    if self.timeout
      return 1
    else
      return 0
    end
  end

  def check
    begin
      start_time = Time.now
      response = Timeout::timeout(30) { response = HTTParty.get(self.uri) }
      end_time = Time.now

      elapsed_milliseconds = (end_time - start_time) * 1_000.0

      logger.info("#{self.url}: #{response.code} (#{elapsed_milliseconds}ms)")

      self.response_time = elapsed_milliseconds
      self.response_code = response.code
      self.timeout = false
    rescue StandardError => e
      logger.error("#{self.url}: #{e.message}")
      self.timeout = true
      self.response_time = nil
      self.response_code = nil
    end
  end
end