'use strict'

###*
 # @ngdoc function
 # @name dataplayApp.controller:LandingCtrl
 # @description
 # # LandingCtrl
 # Controller of the dataplayApp
###
angular.module('dataplayApp')
	.controller 'LandingCtrl', ['$scope', '$location', 'Home', 'Auth', 'Overview', 'PatternMatcher', 'config', ($scope, $location, Home, Auth, Overview, PatternMatcher, config) ->
		$scope.config = config
		$scope.Auth = Auth
		$scope.username = Auth.get config.userName

		$scope.loading =
			charts: true

		$scope.chartsRelated = []

		$scope.relatedChart = new RelatedCharts $scope.chartsRelated
		$scope.relatedChart.setPreview true
		$scope.relatedChart.width = 225
		$scope.relatedChart.height = 175

		if Auth.isAuthenticated()
			$location.path '/home'

		$scope.stats =
			players: null
			discoveries: null
			datasets: null

		$scope.init = ->
			Home.getStats()
				.success (data) ->
					if data instanceof Array
						data.forEach (d) ->
							$scope.stats[d.Label] = $scope.commarise d.Value

			$scope.loading.charts = true

			Home.getTopRated()
				.success (data) ->
					$scope.loading.charts = false

					if data? and data.length > 0
						for key, chart of data
							continue unless $scope.relatedChart.isPlotAllowed chart.type
							continue unless key < 4

							key = parseInt(key)

							if chart.relationid?
								guid = chart.relationid.split("/")[0]

								chart.key = key
								chart.id = "related-#{guid}-#{chart.key + $scope.relatedChart.offset.related}-#{chart.type}"
								chart.url = "charts/related/#{guid}/#{chart.key}/#{chart.type}/#{chart.xLabel}/#{chart.yLabel}"
								chart.url += "/#{chart.zLabel}" if chart.type is 'bubble'

								chart.patterns = {}
								chart.patterns[chart.xLabel] =
									valuePattern: PatternMatcher.getPattern chart.values[0]['x']
									keyPattern: PatternMatcher.getKeyPattern chart.values[0]['x']

								if chart.patterns[chart.xLabel].valuePattern is 'date'
									for value, key in chart.values
										chart.values[key].x = new Date(value.x)

								if chart.yLabel?
									chart.patterns[chart.yLabel] =
										valuePattern: PatternMatcher.getPattern chart.values[0]['y']
										keyPattern: PatternMatcher.getKeyPattern chart.values[0]['y']

								$scope.relatedChart.setLabels chart

								$scope.chartsRelated.push chart

							else if chart.correlationid?
								chartObj = new CorrelatedChart chart.type

								if not chartObj.error and $scope.params?.id?.length > 0
									chartObj.info =
										key: key
										id: "correlated-#{$scope.params.id}-#{chart.key + $scope.offset.correlated}-#{chart.type}"
										url: "charts/correlated/#{chart.correlationid}"
										title: [chart.table1.title, chart.table2.title]

									[1..2].forEach (i) ->
										vals = chartObj.translateData chart['table' + i].values, chart.type
										dataRange = do ->
											min = d3.min vals, (item) -> parseFloat item.y
											[
												if min > 0 then 0 else min
												d3.max vals, (item) -> parseFloat item.y
											]
										type = if chart.type is 'column' or chart.type is 'bar' then 'bar' else 'area'

										chartObj.data.push
											key: chart['table' + i].title
											type: type
											yAxis: i
											values: vals
										chartObj.options.chart['yDomain' + i] = dataRange
										chartObj.options.chart['yAxis' + i].tickValues = [0]
										chartObj.options.chart.xAxis.tickValues = []

									chartObj.setAxisTypes 'none', 'none', 'none'
									chartObj.setSize null, 200
									chartObj.setMargin 25, 25, 25, 25
									chartObj.setLegend false
									chartObj.setTooltips false
									chartObj.setPreview true
									chartObj.setLabels chart

									$scope.chartsRelated.push chartObj

		$scope.commarise = (num) ->
			Number(num).toLocaleString()

		$scope.width = $scope.relatedChart.width
		$scope.height = $scope.relatedChart.height
		$scope.margin = $scope.relatedChart.margin

		$scope.hasRelatedCharts = $scope.relatedChart.hasRelatedCharts
		$scope.lineChartPostSetup = $scope.relatedChart.lineChartPostSetup
		$scope.rowChartPostSetup = $scope.relatedChart.rowChartPostSetup
		$scope.columnChartPostSetup = $scope.relatedChart.columnChartPostSetup
		$scope.pieChartPostSetup = $scope.relatedChart.pieChartPostSetup
		$scope.bubbleChartPostSetup = $scope.relatedChart.bubbleChartPostSetup

		return
	]
