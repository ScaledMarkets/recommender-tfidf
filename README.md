# recommender-tfidf
Basic TF-IDF recommender

The recomender microservice takes a vector of attributes, and provides URLs of
documents that best match those attributes.

# Microservices

One service endpoint enables the user to define the attributes:
```
defineAttributes
```

Another endpoint performs a recommendation.

```
recommend(attributes: []string)
```

# Usage

* Deploy SOLR and recommender microservice.
* Train recommender: 
** Define schema.
** Create core, and add documents.

