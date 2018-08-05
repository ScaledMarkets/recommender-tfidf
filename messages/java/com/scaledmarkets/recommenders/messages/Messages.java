package com.scaledmarkets.recommenders.messages;

public class Messages {
	
	public static class Message {
	}
	
	public static class ErrorMessage extends Message {
		public ErrorMessage(String msg) { this.message = msg; }
		public String message;
		public void setMessage(String msg) { this.message = msg; }
		public String getMessage() { return this.message; }
	}

	public static class NoRecommendationMessage extends Message {
		public String message = "No recommendation";
		public String getMessage() { return this.message; }
		public void setMessage(String message) { this.message = message; }
	}
	
	public static class RecommendationMessage extends Message {
		public RecommendationMessage(long itemID, float value) {
			this.itemID = itemID;
			this.value = value;
		}
		
		public long itemID;
		public float value;
		
		public long getItemID() { return this.itemID; }
		public void setItemID(long id) { this.itemID = id; }
		public float getValue() { return this.value; }
		public void setValue(float v) { this.value = v; }
	}
}
