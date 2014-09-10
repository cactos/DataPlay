'use strict'

###*
 # @ngdoc service
 # @name dataplayApp.Charts
 # @description
 # # Charts
 # Factory in the dataplayApp.
###
angular.module('dataplayApp')
	.factory 'Charts', ['$http', 'config', ($http, config) ->
		related: (guid, key, type, x, y, z) ->
			if z?
				$http.get config.api.base_url + "/chart/#{guid}/#{key}/#{type}/#{x}/#{y}/#{z}"
			else
				$http.get config.api.base_url + "/chart/#{guid}/#{key}/#{type}/#{x}/#{y}"

		correlated: (key) ->
			$http.get config.api.base_url + "/chartcorrelated/#{key}"

		bookmark: (bookmarks) ->
			$http.post config.api.base_url + "/setbookmark",
				data: bookmarks

		getObservations: (chart) ->
			$http.get config.api.base_url + "/observations/#{chart}"

		createObservation: (chart, x, y, message) ->
			$http.post config.api.base_url + "/observations/#{chart}",
				x: x
				y: y
				comment: message
	]
