package unittest;

public class TestBase {

	public Process process;
	
	public TestBase() {
		try {
		} catch (Throwable t) {
			t.printStackTrace();
			throw t;
		}
	}
	
	public void assertThat(boolean expr) throws Exception {
		Utils.assertThat(expr);
	}
	
	public void assertThat(boolean expr, String msg) throws Exception {
		Utils.assertThat(expr, msg);
	}
}
