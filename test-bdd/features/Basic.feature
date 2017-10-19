# language: en

Feature: Basic
	
	@done @usersimrec @database
	Scenario: Database
		Given four users and their item preferences in a database
		When I remotely request a recommendation for user 4 with threshold 0.1
		Then I obtain one recommendation
