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
      if current_status.nil? || check_report.status != current_status.status
        current_status = Status.create(check_report: check_report)
        statuses << current_status
      else
        Status.update(status: current_status, check_report: check_report)
      end
    end

    return statuses
  end

  class Status
    attr_accessor :status, :start, :end

    def self.create(check_report:)
      status = Status.new
      status.status = check_report.status
      status.start = DateTime.iso8601(check_report.checked_at)
      status.end = DateTime.iso8601(check_report.checked_at)

      return status
    end

    def duration
      total_difference = (self.end.to_time - self.start.to_time)
      Time.at(total_difference.to_i.abs).utc.strftime("%H:%M:%S")
    end

    def self.update(status:, check_report:)
      raise ArgumentError if check_report.status != status.status
      status.end = DateTime.iso8601(check_report.checked_at)
    end
  end
end