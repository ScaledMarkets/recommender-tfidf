# language: en

Feature: Basic
	
	@done @tfidf @database
	Scenario: Database
		Given ten users and identical item preferences in a database
		When I remotely request a recommendation for user 10 with threshold 0.1
		Then I obtain one recommendation
