class CheckReport
  attr_accessor :id, :status, :checked_at

  def initialize(id:,status:,checked_at:)
    self.id = id
    self.status = status
    self.checked_at = checked_at
  end
end

class OutageReport
  def self.from(check_history:)
    return [] if check_history.empty?
    statuses = []

    current_status = nil

    check_history.each do |check_report|
      logger.debug("check_report: #{check_report.checked_at}")
      if current_status.nil?
        logger.debug("Creating new status: #{check_report.status}")
        current_status = Status.create(check_report: check_report)
        statuses << current_status
      elsif current_status.large_time_difference?(previous_time: DateTime.iso8601(check_report.checked_at))
        logger.debug("Creating indeterminate. Start: #{current_status.end} End: #{check_report.checked_at}")
        statuses << Status.create_indeterminate(start_time: check_report.checked_at, end_time: current_status.start)

        logger.debug("Creating new status after indeterminate: #{check_report.status}")
        current_status = Status.create(check_report: check_report)
        statuses << current_status
      elsif check_report.status != current_status.status
        logger.debug("Creating new status after status change: #{current_status.status} -> #{check_report.status}")
        current_status = Status.create(check_report: check_report)
        statuses << current_status
      else
        logger.debug("Updating status: #{check_report.checked_at}")
        Status.update(status: current_status, check_report: check_report)
      end
    end

    return statuses
  end

  class Status
    attr_accessor :status, :start, :end

    def self.create_indeterminate(start_time:, end_time:)
      status = Status.new
      status.status = "indeterminate"
      status.start = DateTime.iso8601(start_time.to_s)
      status.end = DateTime.iso8601(end_time.to_s)

      return status
    end

    def self.create(check_report:)
      status = Status.new
      status.status = check_report.status
      status.start = DateTime.iso8601(check_report.checked_at)
      status.end = DateTime.iso8601(check_report.checked_at)

      return status
    end

    def duration
      total_difference = (self.end.to_time - self.start.to_time).to_i
      #find the seconds
      seconds = total_difference % 60
   
      #find the minutes
      minutes = (total_difference / 60) % 60
   
      #find the hours
      hours = (total_difference/3600)
   
      #format the time
   
      return format("%02d",hours.to_s) + ":" + format("%02d",minutes.to_s) + ":" + format("%02d",seconds.to_s)
    end

    def large_time_difference?(previous_time:)
      total_difference = (self.start.to_time - previous_time.to_time)

      logger.debug("time difference: #{total_difference}")
      return total_difference.to_f >= (60 * 10)
    end

    def self.update(status:, check_report:)
      raise ArgumentError if check_report.status != status.status
      status.start = DateTime.iso8601(check_report.checked_at)
    end
  end
end