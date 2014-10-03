'use strict'

###*
 # @ngdoc function
 # @name dataplayApp.controller:HomeCtrl
 # @description
 # # HomeCtrl
 # Controller of the dataplayApp
###
angular.module('dataplayApp')
	.controller 'HomeCtrl', ['$scope', '$location', 'Home', 'Auth', 'Overview', 'PatternMatcher', 'config', ($scope, $location, Home, Auth, Overview, PatternMatcher, config) ->
		$scope.config = config

		$scope.searchquery = ''

		$scope.validatePatterns = null

		$scope.myActivity = null
		$scope.recentObservations = null
		$scope.dataExperts = null

		$scope.chartsRelated = []

		$scope.relatedChart = new RelatedCharts $scope.chartsRelated

		$scope.init = ->
			Home.getAwaitingValidation()
				.success (data) ->
					if data? and data.charts? and data.charts.length > 0
						for key, chart of data.charts
							continue unless $scope.relatedChart.isPlotAllowed chart.type
							continue unless chart.relationid?

							guid = chart.relationid.split("/")[0]

							key = parseInt(key)
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

							$scope.chartsRelated.push chart if PatternMatcher.includePattern(
								chart.patterns[chart.xLabel].valuePattern,
								chart.patterns[chart.xLabel].keyPattern
							)

						console.log $scope.chartsRelated
					else
						$scope.validatePatterns = []
				.error ->
					$scope.validatePatterns = []

			Home.getActivityStream()
				.success (data) ->
					if data instanceof Array
						$scope.myActivity = data.map (d) ->
							date: Overview.humanDate new Date d.time
							pretext: d.activitystring
							linktext: d.patternid
							url: d.linkstring
					else
						$scope.myActivity = []
				.error ->
					$scope.myActivity = []

			Home.getRecentObservations()
				.success (data) ->
					if data instanceof Array
						$scope.recentObservations = data.map (d) ->
							user:
								name: d.username
								avatar: "http://www.gravatar.com/avatar/#{d.MD5email}?d=identicon"
							text: d.comment
							url: d.linkstring
					else
						$scope.recentObservations = []
				.error ->
					$scope.recentObservations = []

			Home.getDataExperts()
				.success (data) ->
					if data instanceof Array

						medals = ['gold', 'silver', 'bronze']

						$scope.dataExperts = data.map (d, key) ->
							obj =
								rank: key + 1
								name: d.username
								avatar: "http://www.gravatar.com/avatar/#{d.MD5email}?d=identicon"
								score: d.reputation

							if obj.rank <= 3 then obj.rankclass = medals[obj.rank - 1]

							obj
					else
						$scope.dataExperts = []
				.error ->
					$scope.dataExperts = []

		$scope.search = ->
			$location.path "/search/#{$scope.searchquery}"

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