import json
import openai
import os
from pathlib import Path

def fetch_openai_completion(text: str, lang: str):
    model = "gpt-3.5-turbo"

    prompt = ("I am developing a music player app similar to Spotify. I'm now doing the localizations and translations for all"
              f"text that appears in the app. Please translate the following English text to {lang} and try to use"
              f" terminology that most applications would use: {text}. As an example if we're translationg English to Spanish, instead of translating 'home' to 'hogar' use 'inicio'."
              "Return only the translated word, trimmed, without any other text. I'm going to paste your response into a JSON file.")

    messages = [
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": prompt}
    ]

    try:
        response = openai.chat.completions.create(
            temperature=.3,
            max_tokens=100,
            model=model,
            messages=messages,
        )
        text = response.choices[0].message.content
        print(text)
        return text

    except Exception as e:
        text = f"An error occurred: {e}"
        print(text)
        return ""

def process_languages(supported_languages):
    openai.api_key = os.getenv('OPENAI_API_KEY')
    
    # Get the base directory (where your script is)
    base_dir = Path(os.path.dirname(os.path.abspath(__file__)))
    
    # Create the translations directory if it doesn't exist
    translations_dir = base_dir / "assets" / "translations"
    translations_dir.mkdir(parents=True, exist_ok=True)
    
    en_file_path = translations_dir / "en.json"
    
    # Check if en.json exists, if not create a sample one
    if not en_file_path.exists():
        print(f"Warning: {en_file_path} not found. Creating a sample file.")
        sample_en = {
            "home": "Home",
            "search": "Search",
            "library": "Library",
            "settings": "Settings"
        }
        with open(en_file_path, 'w', encoding='utf-8') as f:
            json.dump(sample_en, f, ensure_ascii=False, indent=4)
    
    # Open and read the contents of the 'en' file
    with open(en_file_path, 'r', encoding='utf-8') as f:
        # Use json.load to read the JSON contents
        en_dict = json.load(f)

        for lang in supported_languages:
            print('Creating or updating file for language:', lang)
            lang_file_path = translations_dir / f"{lang}.json"

            # Initialize an empty language dictionary
            lang_dict = {}

            # Check if language file exists and load it
            if lang_file_path.exists():
                try:
                    with open(lang_file_path, 'r', encoding='utf-8') as f:
                        # Use json.load to read the JSON contents
                        lang_dict = json.load(f)
                except json.JSONDecodeError:
                    pass

            # Add missing keys from the English dictionary
            for key, value in en_dict.items():
                if key not in lang_dict:
                    lang_dict[key] = ''

            # Fetch translations for empty strings
            for key, value in en_dict.items():
                if lang_dict[key] == '':
                    print(f'Looking up translation for key: {key}...', end=' ')
                    lang_dict[key] = fetch_openai_completion(value, lang)

            # Now save the updated dictionary to the file
            with open(lang_file_path, 'w', encoding='utf-8') as f:
                # Use json.dump to write the JSON contents
                json.dump(lang_dict, f, ensure_ascii=False, indent=4)

def main():
    # Check for OpenAI API key
    if not os.getenv('OPENAI_API_KEY'):
        print("ERROR: OPENAI_API_KEY environment variable not set.")
        print("Please set it by running: set OPENAI_API_KEY=your_api_key (on Windows)")
        print("Or export OPENAI_API_KEY=your_api_key (on macOS/Linux)")
        return

    supported_languages = ['es', 'fr', 'de', 'it', 'pt',  'zh', 'ja', 'ko', 'ar',
                           # filipino
                           'tl',
                           # indonesia
                           'id', 'cs', 'nl', 'pl', 'nn',
                           'sv']

    # let's start with just spanish and japanese
    # supported_languages = ['es', 'ja']

    # first let's get the contents of the 'en' file
    process_languages(supported_languages)

if __name__ == '__main__':
    main()