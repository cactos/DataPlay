'use strict'

###*
 # @ngdoc function
 # @name dataplayApp.controller:ChartsCorrelatedCtrl
 # @description
 # # ChartsCorrelatedCtrl
 # Controller of the dataplayApp
###
angular.module('dataplayApp')
	.controller 'ChartsCorrelatedCtrl', ['$scope', '$location', '$routeParams', 'Overview', 'PatternMatcher', 'Charts', 'Tracker', ($scope, $location, $routeParams, Overview, PatternMatcher, Charts, Tracker) ->

		$scope.corrLineOptions =
			chart:
				type: "multiChart"
				height: 450
				margin:
					top: 15
					right: 35
					bottom: 25
					left: 35
				x: (d, i) -> i
				y: (d) -> d[1]
				color: d3.scale.category10().range()
				transitionDuration: 250
				xAxis:
					axisLabel: ""
					showMaxMin: false
					tickFormat: (d) -> d3.time.format("%d-%m-%Y") new Date d
					ticks: $scope.xTicks
				yAxis1:
					orient: 'left'
					axisLabel: ""
					tickFormat: (d) -> d3.format(",f") d
					showMaxMin: false
					highlightZero: false
				yAxis2:
					orient: 'right'
					axisLabel: ""
					tickFormat: (d) -> d3.format(",f") d
					showMaxMin: false
					highlightZero: false
				areas:
					dispatch:
						elementClick: (e) ->
							console.log 'areas elementClick', e
				lines:
					dispatch:
						elementClick: (e) ->
							console.log 'lines elementClick', e
				yDomain1: [0, 1000]
				yDomain2: [0, 1000]

		$scope.corrLineData = []

		$scope.params = $routeParams
		$scope.mode = 'correlated'
		$scope.width = 570
		$scope.height = $scope.width * 9 / 16 # 16:9
		$scope.margin =
			top: 50
			right: 20
			bottom: 50
			left: 100
		$scope.marginAlt =
			top: 0
			right: 20
			bottom: 50
			left: 110
		$scope.xTicks = 8

		$scope.chartRendered = null
		$scope.chart =
			title: ""
			description: "N/A"
			data: null
			values: []
		$scope.xScale = null
		$scope.yDomain = null
		$scope.userObservations = []
		$scope.userObservationsMessage = []
		$scope.observation =
			x: null
			y: null
			message: ''

		$scope.info =
			discoveredId: null
			validated: null
			invalidated: null
			patternId: null
			discoverer: ''
			discoverDate: ''
			validators: []
			source:
				prim: ''
				seco: ''
			strength: ''

		$scope.init = () ->
			$scope.initChart()
			return

		$scope.translateToNv = (values) ->
			normalise = (d) ->
				if typeof d is 'string'
					if not isNaN Date.parse d
						return Date.parse d
					if not isNaN parseFloat d
						return parseFloat d
				return d

			values.map (v) ->
				x: normalise v.x || 0
				y: parseFloat v.y || 0

		$scope.initChart = () ->
			Charts.correlated $scope.params.correlationid
				.success (data, status) ->
					if data? and data.chartdata
						$scope.chart = data.chartdata
						$scope.chart.type = $scope.params.type

						[1..2].forEach (i) ->
							vals = $scope.translateToNv data.chartdata['table' + i].values
							dataRange = do ->
								min = d3.min vals, (item) -> parseFloat item.y
								[
									if min > 0 then 0 else min
									d3.max vals, (item) -> parseFloat item.y
								]
							$scope.corrLineData.push
								key: data.chartdata['table' + i].title
								type: 'area'
								yAxis: i
								values: vals
							$scope.corrLineOptions.chart['yDomain' + i] = dataRange
							$scope.corrLineOptions.chart['yAxis' + i].tickValues = do ->
								[1..8].map (num) ->
									dataRange[0] + ((dataRange[1] - dataRange[0]) * ((1 / 8) * num))

						if data.desc? and data.desc.length > 0
							description = data.desc.replace /(h1>|h2>|h3>)/ig, 'h4>'
							description = description.replace /\n/ig, ''
							$scope.chart.description = description

						$scope.reduceData()

					if data?
						$scope.info.patternId = data.patternid or ''
						$scope.info.discoveredId = data.discoveredid or ''
						$scope.info.discoverer = data.discoveredby or ''
						$scope.info.discoverDate = if data.discoverydate then Overview.humanDate new Date( data.discoverydate ) else ''
						$scope.info.validators = data.validatedby or ''
						$scope.info.source =
							prim: data.source1 or ''
							seco: data.source2 or ''
						$scope.info.strength = data.statstrength

					$scope.initObservations()
					console.log "Chart", $scope.chart

					# Track a page visit
					Tracker.visited $scope.params.id, $scope.params.key, $scope.params.type, $scope.params.x, $scope.params.y, $scope.params.z
				.error (data, status) ->
					console.log "Charts::init::Error:", status

			return

		$scope.initObservations = (redraw) ->
			id = "#{$scope.params.correlationid}"

			Charts.getObservations $scope.info.discoveredId
				.then (res) ->
					$scope.userObservations.splice 0, $scope.userObservations.length

					res.data?.forEach? (obsv) ->
						x = obsv.x
						y = obsv.y
						if $scope.chart.patterns[$scope.chart.table1.xLabel].valuePattern is 'date'
							if not(x instanceof Date) and (typeof x is 'string')
								xdate = new Date x
								if xdate.toString() isnt 'Invalid Date' then x = xdate
							x = Overview.humanDate x

						xy = "#{x.replace(/\W/g, '')}-#{y.replace(/\W/g, '')}"
						$scope.userObservationsMessage[xy] = obsv.comment
						$scope.userObservations.push
							xy: xy
							oid : obsv['observation_id']
							user: obsv.user
							validationCount: parseInt(obsv.validations - obsv.invalidations) || 0
							message: obsv.comment
							date: Overview.humanDate new Date(obsv.created)
							coor:
								x: obsv.x
								y: obsv.y

					if redraw? and redraw
						$scope.redrawObservationIcons()

						newObservations = d3.select 'g.stack-list > .observations.new'
						$scope.renderObservationIcons $scope.xScale, $scope.yDomain, $scope.chart, newObservations
				, $scope.handleError
			return

		$scope.reduceData = () ->
			$scope.chart.data = $scope.chart.table1.values
			$scope.chart.patterns = {}
			$scope.chart.patterns[$scope.chart.table1.xLabel] =
				valuePattern: PatternMatcher.getPattern $scope.chart.table1.values[0]['x']
				keyPattern: PatternMatcher.getKeyPattern $scope.chart.table1.values[0]['x']

			if $scope.chart.patterns[$scope.chart.table1.xLabel].valuePattern is 'date'
				for value, key in $scope.chart.table1.values
					$scope.chart.table1.values[key].x = new Date(value.x)

				for value, key in $scope.chart.table2.values
					$scope.chart.table2.values[key].x = new Date(value.x)

			if $scope.chart.table1.yLabel?
				$scope.chart.patterns[$scope.chart.table1.yLabel] =
					valuePattern: PatternMatcher.getPattern $scope.chart.table1.values[0]['y']
					keyPattern: PatternMatcher.getKeyPattern $scope.chart.table1.values[0]['y']

		$scope.getXScale = (data) ->
			xScale = switch data.patterns[data.table1.xLabel].valuePattern
				when 'label'
					d3.scale.ordinal()
						.domain data.ordinals
						.rangeBands [0, $scope.width]
				when 'date'
					d3.time.scale()
						.domain d3.extent data.group.all(), (d) -> d.key
						.range [0, $scope.width]
				else
					d3.scale.linear()
						.domain d3.extent data.group.all(), (d) -> parseInt d.key
						.range [0, $scope.width]

			xScale

		$scope.getYScale = (data) ->
			yScale = switch data.patterns[data.yLabel].valuePattern
				when 'label'
					d3.scale.ordinal()
						.domain data.ordinals
						.rangeBands [$scope.height, 0]
				when 'date'
					d3.time.scale()
						.domain d3.extent data.group.all(), (d) -> d.value
						.range [$scope.height, 0]
				else
					d3.scale.linear()
						.domain d3.extent data.group.all(), (d) -> parseInt d.value
						.range [$scope.height, 0]

			yScale

		$scope.lineChartPostSetup = (chart) ->
			data = $scope.chart

			# tableData = []
			# _.merge tableData, data.table1.values
			# _.merge tableData, data.table2.values
			# console.log "tableData", tableData

			# _.merge data.table2.values, data.table1.values

			data.xDomain = [new Date(data.from), new Date(data.to)]
			data.entry = crossfilter data.table1.values
			data.dimension = data.entry.dimension (d) -> d.x
			data.group = data.dimension.group().reduceSum (d) -> d.y

			data.entry2 = crossfilter data.table2.values
			data.dimension2 = data.entry2.dimension (d) -> d.x
			data.group2 = data.dimension2.group().reduceSum (d) -> d.y

			chart.dimension data.dimension
			chart.group data.group, data.table1.title
			chart.stack data.group2, data.table2.title

			chart.legend dc.legend()

			data.ordinals = []
			data.ordinals.push d.key for d in data.group.all() when d not in data.ordinals

			# chart.colorAccessor (d, i) -> parseInt(d.y) % data.ordinals.length
			chart.colors d3.scale.category10()

			chart.xAxis()
				.ticks $scope.xTicks
				# .tickFormat customTimeFormat

			xScale = d3.time.scale()
				.domain data.xDomain
				.range [0, $scope.width]
			chart.x xScale

			return

		$scope.rangeChartPostSetup = (chart) ->
			data = $scope.chart

			data.xDomain = [new Date(data.from), new Date(data.to)]
			data.entry = crossfilter data.table1.values
			data.dimension = data.entry.dimension (d) -> d.x
			data.group = data.dimension.group().reduceSum (d) -> d.y

			chart.dimension data.dimension
			chart.group data.group, data.table1.title

			data.ordinals = []
			data.ordinals.push d.key for d in data.group.all() when d not in data.ordinals

			chart.colorAccessor (d, i) -> parseInt(d.y) % data.ordinals.length

			chart.xAxis().ticks $scope.xTicks

			xScale = d3.time.scale()
				.domain data.xDomain
				.range [0, $scope.width]
			chart.x xScale

			return

		$scope.rowChartPostSetup = (chart) ->
			data = $scope.chart

			data.entry = crossfilter data.table1.values
			data.dimension = data.entry.dimension (d) -> d.x
			data.group = data.dimension.group().reduceSum (d) -> d.y

			chart.dimension data.dimension
			chart.group data.group

			data.ordinals = []
			data.ordinals.push d.key for d in data.group.all() when d not in data.ordinals

			chart.colorAccessor (d, i) -> (i + 1) % 20

			chart.xAxis()
				.ticks $scope.xTicks

			chart.x $scope.getYScale data

			if ordinals? and ordinals.length > 0
				chart.xUnits switch data.patterns[data.table1.xLabel].valuePattern
					when 'date' then d3.time.years
					when 'intNumber' then dc.units.integers
					when 'label', 'text' then dc.units.ordinal
					else dc.units.ordinal

			return

		$scope.stackedChartPostSetup = (chart) ->
			data = $scope.chart

			data.entry = crossfilter data.table1.values
			data.dimension = data.entry.dimension (d) -> d.x
			data.group = data.dimension.group().reduceSum (d) -> d.y

			chart.dimension data.dimension
			chart.group data.group
			chart.stack data.group2, data.table2.title

			data.ordinals = []
			data.ordinals.push d.key for d in data.group.all() when d not in data.ordinals

			chart.colorAccessor (d, i) -> i + 1

			xScale = d3.time.scale()
				.domain data.xDomain
				.range [0, $scope.width]
			chart.x xScale

			if ordinals? and ordinals.length > 0
				chart.xUnits switch data.patterns[data.table1.xLabel].valuePattern
					when 'date' then d3.time.years
					when 'intNumber' then dc.units.integers
					when 'label', 'text' then dc.units.ordinal
					else dc.units.ordinal

			return

		$scope.bubbleChartPostSetup = (chart) ->
			data = $scope.chart

			minR = null
			maxR = null

			###
			# TODO: when X/Y is String group all similar X/Y and SUM Y/X.
			# if Z is 'transaction_number' or 'invoice_number' ignore it
			# and replace radius with count of X/Y
			###

			data.entry = crossfilter data.table1.values
			data.dimension = data.entry.dimension (d) ->
				z = Math.abs parseInt d.z

				if not minR? or minR > z
					minR = if z is 0 then 1 else z

				if not maxR? or maxR <= z
					maxR = if z is 0 then 1 else z

				"#{d.x}|#{d.y}|#{d.z}"

			data.group = data.dimension.group().reduceSum (d) -> d.y

			chart.dimension data.dimension
			chart.group data.group

			data.ordinals = []
			data.ordinals.push d.key.split("|")[0] for d in data.group.all() when d not in data.ordinals

			chart.keyAccessor (d) -> d.key.split("|")[0]
			chart.valueAccessor (d) -> d.key.split("|")[1]
			chart.radiusValueAccessor (d) ->
				r = Math.abs d.key.split("|")[2]
				if r >= minR then r else minR

			chart.x switch data.patterns[data.table1.xLabel].valuePattern
				when 'label'
					d3.scale.ordinal()
						.domain data.ordinals
						.rangeBands [0, $scope.width]
				when 'date'
					d3.time.scale()
						.domain d3.extent data.group.all(), (d) -> d.key.split("|")[0]
						.range [0, $scope.width]
				else
					d3.scale.linear()
						.domain d3.extent data.group.all(), (d) -> parseInt d.key.split("|")[0]
						.range [0, $scope.width]

			chart.y switch data.patterns[data.table1.xLabel].valuePattern
				when 'label'
					d3.scale.ordinal()
						.domain data.ordinals
						.rangeBands [0, $scope.height]
				when 'date'
					d3.time.scale()
						.domain d3.extent data.group.all(), (d) -> d.key.split("|")[1]
						.range [0, $scope.height]
				else
					d3.scale.linear()
						.domain d3.extent data.group.all(), (d) -> parseInt d.key.split("|")[1]
						.range [0, $scope.height]

			rScale = d3.scale.linear()
				.domain d3.extent data.group.all(), (d) -> Math.abs parseInt d.key.split("|")[2]
			chart.r rScale

			chart.label (d) -> x = d.key.split("|")[0]

			chart.title (d) ->
				x = d.key.split("|")[0]
				y = d.key.split("|")[1]
				z = d.key.split("|")[2]
				"#{data.table1.xLabel}: #{x}\n#{data.yLabel}: #{y}\n#{data.zLabel}: #{z}"

			minRL = Math.log minR
			maxRL = Math.log maxR
			scale = Math.abs Math.log (maxRL - minRL) / (maxR - minR)

			chart.maxBubbleRelativeSize scale / 100

			chart.zoomOutRestrict true
			chart.mouseZoomable true

			# chart.renderlet (c) ->
			# 	circles = c.svg().selectAll('g.chart-body').selectAll('g circle')
			# 	for circle in circles[0]
			# 		r = circle.r
			# 		if r.baseVal.value < 0
			# 			r.baseVal.value = Math.abs r.baseVal.value
			# 			r.animVal = r.baseVal

			return

		$scope.scatterChartPostSetup = (chart) ->
			data = $scope.chart

			data.xDomain = [new Date(data.from), new Date(data.to)]
			data.entry = crossfilter data.table1.values
			data.dimension = data.entry.dimension (d) -> d.x
			data.group = data.dimension.group().reduceSum (d) -> d.y

			chart.dimension data.dimension
			chart.group data.group

			chart.keyAccessor (d) -> d.key
			chart.valueAccessor (d) -> d.value

			xScale = d3.time.scale()
				.domain data.xDomain
				.range [0, $scope.width]
			chart.x xScale

			chart.xAxis().ticks $scope.xTicks

			yScale = d3.scale.linear()
				.domain d3.extent data.group.all(), (d) -> d.value
				.range [$scope.height, 0]
			chart.y yScale

			chart.zoomOutRestrict true
			chart.mouseZoomable true

			chart.title (d) -> "#{data.table1.xLabel}: #{d.key}\n#{data.table1.yLabel}: #{d.value}"

			# chart.colors d3.scale.category20()

			# chart.title (d) ->
			# 	x = d.key.split("|")[0]
			# 	y = d.key.split("|")[1]
			# 	"#{data.table1.xLabel}: #{x}\n#{data.yLabel}: #{y}"

			return

		$scope.validateObservation = (item, valFlag) ->
			if item.oid?
				Charts.validateObservation item.oid, valFlag
					.success (res) ->
						item.validationCount += (valFlag) ? 1 : -1

		$scope.addObservation = (x, y, space, comment) ->
			$scope.observations.push
				x: x
				y: y
				space: space
				comment: if comment? and comment.length > 0 then comment else ""
				timestamp: Date.now()

			$scope.$apply()

		$scope.resetObservations = ->
			$scope.observations = []

			d3.selectAll('g.observations.new > circle').remove()

		$scope.resetAll = ->
			dc.filterAll()
			dc.redrawAll()

			$scope.resetObservations()

		return
	]
