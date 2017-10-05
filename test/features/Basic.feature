# language: en

Feature: Basic
	
	@done @usersimrec
	Scenario: Basic functionality
		Given four users and their item preferences
		When I request two recommendations for a user
		Then I obtain two recommendations
	
	@done @usersimrec
	Scenario: All users the same
		Given ten users with identical item preferences
		When I request two recommendations for a user
		Then I obtain two recommendations
