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
			path = "/chart/#{guid}/#{key}/#{type}/#{x}/#{y}"
			if z? then path += "/#{z}"
			$http.get config.api.base_url + path

		correlated: (key) ->
			$http.get config.api.base_url + "/chartcorrelated/#{key}"

		bookmark: (bookmarks) ->
			$http.post config.api.base_url + "/setbookmark",
				data: bookmarks

		creditChart: (type, chartId, valFlag) ->
			path = '/chart/'
			path += if type is 'rid' then chartId.replace /\//g, '_' else chartId
			path += "/#{valFlag}"

			$http.put config.api.base_url + path

		getObservations: (id) ->
			$http.get config.api.base_url + "/observations/#{id}"

		createObservation: (did, x, y, message) ->
			$http.put config.api.base_url + "/observations",
				did: '' + did
				x: "#{x}"
				y: "#{y}"
				comment: message

		creditObservation: (id, valFlag) ->
			$http.put config.api.base_url + "/observations/#{id}/#{valFlag}"

		flagObservation: (id) ->
			$http.post config.api.base_url + "/observations/flag/#{id}"

	]
