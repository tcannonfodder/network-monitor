require_relative 'reporting'

class Database
  attr_accessor :path, :db

  def initialize(path:)
    self.path = path
    create_database
    create_tables
  end

  def create_database
    logger.debug("creating database")
    self.db = SQLite3::Database.new(self.path)
  end

  def create_tables
    logger.debug("creating tables")
    db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS checks(
        id INTEGER PRIMARY KEY,
        status TEXT,
        created_at DATETIME
      );
    SQL

    db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS check_runs(
        id INTEGER PRIMARY KEY,
        check_id INTEGER,
        url TEXT,
        response_time NUMERIC,
        response_code INT,
        timeout BOOLEAN,
        created_at DATETIME,
        FOREIGN KEY(check_id) REFERENCES checks(id)
      );
    SQL
  end

  def save_check(check:)
    insert_sql = <<-SQL
      INSERT INTO checks
      (
        status,
        created_at
      )

      VALUES (?, ?);
    SQL

    logger.debug("saving check")
    db.execute(insert_sql, [
      check.status,
      check.created_at.to_datetime.new_offset("0").iso8601
    ])

    row_id_sql = <<-SQL
      SELECT last_insert_rowid()
    SQL

    logger.debug("getting check ID")
    db.execute(row_id_sql) do |row|
      return row[0]
    end
  end

  def save_check_run(check_id:, check_run:)
    logger.debug("saving run for check: #{check_id}")
    insert_sql = <<-SQL
      INSERT INTO check_runs
      (
        check_id, url, response_time, response_code, timeout, created_at
      )

      VALUES (?, ?, ?, ?, ?, ?);
    SQL

    db.execute(insert_sql, [
      check_id,
      check_run.url,
      check_run.response_time,
      check_run.response_code,
      check_run.timeout_int,
      check_run.created_at.to_datetime.new_offset("0").iso8601
    ])
  end

  def get_ordered_checks
    select_sql = <<-SQL
      SELECT * FROM checks ORDER BY created_at ASC;
    SQL

    results = []

    db.execute(select_sql) do |row|
      results << CheckReport.new(id: row[0], status: row[1], checked_at: row[2])
    end

    return results
  end
end