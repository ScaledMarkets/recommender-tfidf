# language: en

Feature: Basic
	
	@done @usersimrec @database
	Scenario: Database
		Given four users and their item preferences in a database
		When I remotely request a recommendation for a user
		Then I obtain one recommendation
