package scaledmarkets.recommenders.solr;


import java.io.IOException;

import org.apache.solr.client.solrj.SolrClient;
import org.apache.solr.client.solrj.SolrQuery;
import org.apache.solr.client.solrj.SolrServerException;
import org.apache.solr.client.solrj.impl.HttpSolrClient;
import org.apache.solr.client.solrj.response.QueryResponse;
import org.apache.solr.common.SolrDocumentList;

public class SolrJSearcher {
	public static void main(String[] args) throws IOException, SolrServerException {
		SolrClient client = new HttpSolrClient.Builder("http://localhost:8983/solr/collection1").build();
		
		SolrQuery query = new SolrQuery();
		query.setQuery("sony digital camera");
		query.addFilterQuery("cat:electronics","store:amazon.com");
		query.setFields("id","price","merchant","cat","store");
		query.setStart(0);
		query.set("defType", "edismax");
		
		QueryResponse response = client.query(query);
		SolrDocumentList results = response.getResults();
		for (int i = 0; i < results.size(); ++i) {
			System.out.println(results.get(i));
		}
	}
}
