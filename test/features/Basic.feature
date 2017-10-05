# language: en

Feature: Basic
	
	@done
	Scenario: Basic functionality
		Given ten users and their item preferences
		When I request two recommendations for a user
		Then I obtain two recommendations
