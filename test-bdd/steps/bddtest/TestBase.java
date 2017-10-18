package bddtest;

import cucumber.api.Scenario;

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
	
	public void setScenario(Scenario s) { this.scenario = s; }
	
	public Scenario getScenario() { return scenario; }
	
	public void assertThat(boolean expr) throws Exception {
		Utils.assertThat(expr);
	}
	
	public void assertThat(boolean expr, String msg) throws Exception {
		Utils.assertThat(expr, msg);
	}
}
