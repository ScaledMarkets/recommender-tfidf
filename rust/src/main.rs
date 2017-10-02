// BDD testing:
// https://github.com/acmcarther/cucumber
// http://www.solrtutorial.com/solrj-tutorial.html
// https://lucene.apache.org/solr/6_6_0/solr-core/index.html
// https://lucene.apache.org/solr/guide/6_6/index.html






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
