import boto3
import json
from pprint import pprint

# Initialize the Comprehend client once
comprehend = boto3.client('comprehend')

def detect_language(text):
    """Detect the dominant language of the text."""
    print("\n=== Language Detection ===")
    response = comprehend.detect_dominant_language(Text=text)
    return response['Languages'][0]['LanguageCode']

def analyze_sentiment(text, language_code):
    """Analyze the sentiment of the text."""
    print("\n=== Sentiment Analysis ===")
    response = comprehend.detect_sentiment(
        Text=text,
        LanguageCode=language_code
    )
    print(f"Sentiment: {response['Sentiment']}")
    print("Sentiment Scores:")
    pprint(response['SentimentScore'])
    return response['Sentiment']

def extract_key_phrases(text, language_code):
    """Extract key phrases from the text."""
    print("\n=== Key Phrases ===")
    response = comprehend.detect_key_phrases(
        Text=text,
        LanguageCode=language_code
    )
    for phrase in response['KeyPhrases']:
        print(f"- {phrase['Text']} (Score: {phrase['Score']:.2f})")
    return response['KeyPhrases']

def detect_entities(text, language_code):
    """Detect entities in the text."""
    print("\n=== Named Entities ===")
    response = comprehend.detect_entities(
        Text=text,
        LanguageCode=language_code
    )
    for entity in response['Entities']:
        print(f"- {entity['Text']} ({entity['Type']}, Score: {entity['Score']:.2f})")
    return response['Entities']

def detect_pii(text, language_code):
    """Detect PII entities in the text and return both the entities and masked text."""
    print("\n=== PII Detection ===")
    response = comprehend.detect_pii_entities(
        Text=text,
        LanguageCode=language_code
    )
    
    # Sort entities by position in text (reversed to handle overlapping entities correctly)
    entities = sorted(response['Entities'], key=lambda x: x['BeginOffset'], reverse=True)
    
    # Define sensitive PII types that should be masked
    sensitive_types = {
        'BANK_ACCOUNT_NUMBER', 'CREDIT_DEBIT_NUMBER', 'PIN',
        'PASSWORD', 'SSN', 'PASSPORT_NUMBER', 'NAME',
        'EMAIL', 'PHONE', 'ADDRESS', 'DATE_TIME',
        'PERSON', 'AGE', 'USERNAME', 'URL'
    }
    
    # Create a copy of text for masking
    masked_text = text
    
    for entity in entities:
        entity_type = entity['Type']
        score = entity['Score']
        start = entity['BeginOffset']
        end = entity['EndOffset']
        
        # Get the actual text for this entity
        entity_text = text[start:end]
        
        if entity_type in sensitive_types:
            print(f"- {entity_type}: **MASKED** (Score: {score:.2f}, Position: {start}-{end})")
            # Replace sensitive information with asterisks in masked text
            masked_text = masked_text[:start] + '*' * (end - start) + masked_text[end:]
        else:
            print(f"- {entity_type}: '{entity_text}' (Score: {score:.2f}, Position: {start}-{end})")
    
    print("\n=== Masked Text ===")
    print(masked_text)
    
    return {
        'entities': entities,
        'masked_text': masked_text
    }

def detect_syntax(text, language_code):
    """Analyze syntax in the text."""
    print("\n=== Syntax Analysis ===")
    response = comprehend.detect_syntax(
        Text=text,
        LanguageCode=language_code
    )
    for token in response['SyntaxTokens']:
        print(f"- {token['Text']}: {token['PartOfSpeech']['Tag']}")
    return response['SyntaxTokens']

def main():
    # Single comprehensive text example that includes various elements for analysis
    sample_text = """
    Dear Mr. John Smith,
    
    I am writing to confirm your AWS account setup. Amazon Web Services (AWS) has successfully 
    processed your registration on May 15, 2025. Your new account manager, Sarah Johnson, 
    is based in our Seattle headquarters at 410 Terry Ave N, Seattle, WA 98109.
    
    We're extremely happy to have you as a customer! You can reach our 24/7 support team 
    at support@aws.amazon.com or (555) 123-4567. Your customer ID is AWS-123456789.
    
    AWS offers excellent cloud services, and Jeff Bezos's vision has transformed the 
    technology industry. Your free tier includes access to machine learning and AI services 
    through Amazon SageMaker, which has received overwhelmingly positive feedback from users.
    """

    print("\n=== Sample Text ===")
    print(sample_text)
    
    # Detect language first
    lang_code = detect_language(sample_text)
    print(f"Detected Language Code: {lang_code}")

    # Run all analyses
    sentiment = analyze_sentiment(sample_text, lang_code)
    entities = detect_entities(sample_text, lang_code)
    key_phrases = extract_key_phrases(sample_text, lang_code)
    syntax = detect_syntax(sample_text, lang_code)
    pii_result = detect_pii(sample_text, lang_code)
    
    # Access PII entities and masked text separately if needed
    pii_entities = pii_result['entities']
    masked_text = pii_result['masked_text']

if __name__ == "__main__":
    main()