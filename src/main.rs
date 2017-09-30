// BDD testing:
// https://github.com/acmcarther/cucumber


fn main() {
    println!("Hello, world!");
    println!("{}", w(1.0))
}

fn w(tf: f64) -> f64 {

	if tf > 0.0 {
		return 1.0 + tf.log(10.0)
	}
	0.0
}
