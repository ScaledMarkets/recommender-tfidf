# language: en

Feature: Basic
	
	@done @usersimrec @file
	Scenario: Basic functionality
		Given four users and their item preferences
		When I locally request two recommendations for a user
		Then I obtain two recommendations
	
	@done @usersimrec @file
	Scenario: All users the same
		Given ten users with identical item preferences
		When I locally request two recommendations for a user
		Then I obtain two recommendations

	@done @usersimrec @database
	Scenario: Database
		Given four users and their item preferences in a database
		When I remotely request a recommendation for a user
		Then I obtain one recommendation
