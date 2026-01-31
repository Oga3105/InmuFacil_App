
import easyocr
import os

def extract_text():
    # Paths to the uploaded images
    base_path = r"C:\Users\Os\.gemini\antigravity\brain\2e9115ca-f251-4425-a6f1-7eb1d98acabe"
    images = [
        "uploaded_media_0_1769883083570.png",
        "uploaded_media_1_1769883083570.png",
        "uploaded_media_2_1769883083570.png",
        "uploaded_media_3_1769883083570.png",
        "uploaded_media_4_1769883083570.png"
    ]

    print("Initializing EasyOCR...")
    reader = easyocr.Reader(['es'], gpu=False) # Spanish model

    full_text = ""
    
    for img_name in images:
        img_path = os.path.join(base_path, img_name)
        if not os.path.exists(img_path):
            print(f"Skipping missing file: {img_path}")
            continue
            
        print(f"Processing {img_name}...")
        results = reader.readtext(img_path, detail=0, paragraph=True)
        
        page_text = "\n".join(results)
        full_text += f"\n--- PAGE {img_name} ---\n{page_text}\n"

    print("\n=== EXTRACTED TEXT ===")
    print(full_text)

if __name__ == "__main__":
    extract_text()
