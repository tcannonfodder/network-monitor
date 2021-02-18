# network-monitor

## Installation

Make sure you've installed:

- `sudo apt-get install ruby ruby-dev sqlite3 libsqlite3-dev`
- `sudo gem install bundler`
- the gems via `bundle install`

## Running a check

Running `check` will run a check for the sites listed in `sites.txt` and store the results in `monitor.sqlite` (these can be changed by passing flags to the command, see `--help`)

## Generating an outage report

Running `outage-report` will read the data in the `monitor.sqlite` database and return a report of how long the network was in each status, over time, to `outage-report.csv` (these can be changed by passing flags to the command, see `--help`)


## Installing the systemd config

You can run the following command to install the systemd services:

```sh
sudo cp ./system-config/* /lib/systemd/system/
sudo systemctl enable network-monitor-check.service
sudo systemctl enable network-monitor-outage-report.service
sudo systemctl start network-monitor-check.timer
sudo systemctl start network-monitor-outage-report.timer
sudo systemctl enable network-monitor-check.timer
sudo systemctl enable network-monitor-outage-report.timer
```