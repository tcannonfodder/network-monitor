# network-monitor


## Running a check

Running `check` will run a check for the sites listed in `sites.txt` and store the results in `monitor.sqlite` (these can be changed by passing flags to the command, see `--help`)

## Generating an outage report

Running `outage-report` will read the data in the `monitor.sqlite` database and return a report of how long the network was in each status, over time, to `outage-report.csv` (these can be changed by passing flags to the command, see `--help`)