import pandas as pd
import pyodbc
from transformers import pipeline

# Fetch data from SQL Server
def fetch_data_from_sql():
    conn_str = (
        "Driver={SQL Server};"
        "Server=DESKTOP-54EIU7M\SQLEXPRESS;"
        "Database=MarketingAnalytics;"
        "Trusted_Connection=yes;"
    )
    conn = pyodbc.connect(conn_str)
    
    query = """
        SELECT ReviewID, CustomerID, ProductID, ReviewDate, Rating, ReviewText
        FROM customer_reviews
    """
    
    df = pd.read_sql(query, conn)
    conn.close()
    
    return df

# Load data
customer_reviews_df = fetch_data_from_sql()

sentiment_model = pipeline(
    "sentiment-analysis",
    model="cardiffnlp/twitter-roberta-base-sentiment",
    top_k=None
)

weights = {"LABEL_0": -1, "LABEL_1": 0, "LABEL_2": 1}

def analyze_sentiment(text):
    result = sentiment_model(text)[0]
    weighted_score = sum(weights[d['label']] * d['score'] for d in result)
    return weighted_score
    
# Sentiment categorization logic
def categorize_sentiment(score, rating):
    if score > 0.5:
        if rating >= 4:
            return 'Positive'
        elif rating == 3:
            return 'Mixed Positive'
        else:
            return 'Mixed Negative'
    elif score < -0.5:
        if rating <= 2:
            return 'Negative'
        elif rating == 3:
            return 'Mixed Negative'
        else:
            return 'Mixed Positive'
    else:
        if rating >= 4:
            return 'Positive'
        elif rating <= 2:
            return 'Negative'
        else:
            return 'Neutral'

# Sentiment score bucketing
def sentiment_bucket(score):
    if score >= 0.5:
        return '0.5 to 1.0'
    elif 0.0 <= score < 0.5:
        return '0.0 to 0.49'
    elif -0.5 <= score < 0.0:
        return '-0.49 to 0.0'
    else:
        return '-1.0 to -0.5'

# Apply sentiment analysis
customer_reviews_df['SentimentScore'] = customer_reviews_df['ReviewText'].apply(analyze_sentiment)

# Apply sentiment categorization
customer_reviews_df['SentimentCategory'] = customer_reviews_df.apply(
    lambda row: categorize_sentiment(row['SentimentScore'], row['Rating']),
    axis=1
)

# Apply sentiment bucketing
customer_reviews_df['SentimentBucket'] = customer_reviews_df['SentimentScore'].apply(sentiment_bucket)

# Preview results
print(customer_reviews_df.head())

# Save output
customer_reviews_df.to_csv('advanced_sentiment_analysis.csv', index=False)

