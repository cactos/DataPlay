![](http://i.imgur.com/esjTHFE.png)

### Overview
DataPlay is an open-source data analysis and exploration game developed by [PlayGen](http://playgen.com/) as part of the EU's [CELAR](http://celarcloud.eu) initiative.

The aim of DataPlay, besides taking CELAR for a spin, is to provide a collaborative environment in which non-expert users get to "play" with government data. The system presents the user with a range of elements of the data, displayed in a variety of visual forms. People are then encouraged to explore this data together. The system also seeks to identify potential correlations between disparate datasets, in order to help users discover hidden patterns within the data.

### Architecture
The back end is written in [Go](http://golang.org/), to provide concurrency for large volume data processing. There is a multiple master/node architecture which relies on [RabbitMQ](http://www.rabbitmq.com/) for its queue processing. The back end also utilises [Martini](https://github.com/go-martini/martini) for web routing, [PostgreSQL](http://www.postgresql.org/) with [GORM](https://github.com/jinzhu/gorm) for dealing with the government data, [Cassandra](http://cassandra.apache.org/) coupled with [gocql](https://github.com/gocql/gocql) for handling the web data and [Redis](http://redis.io/) for storing any volatile data.

The front end is written in [CoffeeScript](http://coffeescript.org/) and [AngularJS](https://angularjs.org/) and makes use of the [d3.js](http://d3js.org/), [dc.js](http://dc-js.github.io/dc.js/) and [NVD3.js](http://nvd3.org/) charting packages.

DataPlay alpha contains a rudimentary selection of datasets drawn from [data.gov.uk](http://data.gov.uk/), along with political information taken from the [BBC](http://www.bbc.co.uk/news/), which was extracted and analysed via [python](https://www.python.org/) scripted [import.io](https://import.io/) and Go implemented [embed.ly](http://embed.ly/).

##Screens
### Landing Page
![](http://i.imgur.com/yJyJ4GC.png)

### Home Page
![](http://i.imgur.com/2vkyTVS.png)

### Overview Screen
![](http://i.imgur.com/N4kCiPG.png)

### Search Page
![](http://i.imgur.com/1ZYsaQb.png)

### Chart Page
![](http://i.imgur.com/cEakHPq.png)

## Installation

1. Install Ubuntu & Node.js [Refer `tools/images/scripts/base.sh`]
2. Install all necessary dependencies `npm install`

Backend:

`./run.sh --mode=3`

Frontend:

`cd www-src`

`grunt build`

## Usage

Development:

1. Run Go in Classic mode `./run.sh --mode=3`
2. Run AngularJS `cd www-src && npm install && grunt serve`

Staging:

1. Run Gamification server in Master mode `./run.sh --mode=2`
2. Run Compute server in Node mode `./run.sh --mode=1`
3. Deploy & run Frontend in `cd www-src && npm install && grunt serve:dist`

Production:

1. HAProxy Load Balancer [`tools/images/scripts/app/loadbalancer.sh`]
2. Gamification instances [`tools/images/scripts/app/master.sh`]
3. Computation instances [`tools/images/scripts/app/node.sh`]
4. PostgreSQL DB instance [`tools/images/scripts/db/postgresql.sh`]
5. Cassandra DB instance [`tools/images/scripts/app/cassandra.sh`]
6. Redis & RabbitMQ instance [`tools/images/scripts/queue/redis_rabbitmq.sh`]

## Contributing

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request :D

## History

TODO: Write history

## Credits

TODO: Write credits

## License

TODO: Write license
