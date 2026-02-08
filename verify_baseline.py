from playwright.sync_api import sync_playwright
import time

def verify_app():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        page.goto("http://localhost:5173/")
        time.sleep(2) # Wait for page to load
        page.screenshot(path="verification_before.png")
        print("Screenshot saved to verification_before.png")
        browser.close()

if __name__ == "__main__":
    verify_app()
