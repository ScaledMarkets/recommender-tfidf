package bddtest;

public class Utils {
	
	public static void assertThat(boolean expr) throws Exception {
		assertThat(expr, null);
	}
	
	public static void assertThat(boolean expr, String msg) throws Exception {
		if (msg != null) msg = "; " + msg;
		if (! expr) throw new Exception("Assertion violation" + msg);
	}
}
