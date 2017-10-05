package test;

import cucumber.api.Format;
import cucumber.api.Scenario;
import cucumber.api.java.en.Given;
import cucumber.api.java.en.Then;
import cucumber.api.java.en.When;
import cucumber.api.java.Before;
import cucumber.api.java.After;

import org.json.*;

public class TestBase {

	public Process process;

	private Scenario scenario;
	
	public TestBase() {
		try {
		} catch (Throwable t) {
			t.printStackTrace();
			throw t;
		}
	}
	
	@Before
	public void beforeEachScenario() throws Exception {
	}
	
	@After
	public void afterEachScenario() throws Exception {
	}
	
	public void setScenario(Scenario s) { this.scenario = s; }
	
	public Scenario getScenario() { return scenario; }
	
	public void assertThat(boolean expr) throws Exception {
		Utils.assertThat(expr);
	}
	
	public void assertThat(boolean expr, String msg) throws Exception {
		Utils.assertThat(expr, msg);
	}
}
