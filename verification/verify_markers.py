from playwright.sync_api import sync_playwright
import time

def run():
    with sync_playwright() as p:
        print("Launching browser...")
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()

        print("Navigating to home...")
        try:
            page.goto("http://localhost:8080", timeout=60000)
        except Exception as e:
            print(f"Navigation failed: {e}")
            browser.close()
            return

        print("Waiting for load (30s)...")
        time.sleep(30)

        print("Taking home screenshot...")
        page.screenshot(path="verification/home.png")

        # Check if we see EndMile
        content = page.content()
        if "EndMile" in content or "Search" in content:
            print("Found expected text in content.")
        else:
            print("Did not find expected text in content.")
            # print(content[:500]) # Print beginning of content

        print("Clicking Search...")
        try:
            # Try to click search button by role
            search_btn = page.get_by_role("button", name="Search")
            if search_btn.count() > 0:
                search_btn.click()
            else:
                # Fallback to get_by_text
                page.get_by_text("Search").click()

            print("Search clicked.")
        except Exception as e:
            print(f"Failed to click Search: {e}")
            browser.close()
            return

        print("Waiting for summary...")
        time.sleep(10)
        page.screenshot(path="verification/summary.png")

        print("Clicking result...")
        try:
             # Click something that looks like a result.
             # Use a generic locator for any text starting with £
             # Or click the first result card if we can find a selector.
             # Results are in ListView.builder.
             # Let's try to click by text again.
             page.locator("text=£").first.click()
             print("Result clicked.")
        except Exception as e:
            print(f"Failed to click result: {e}")

        print("Waiting for detail...")
        time.sleep(10)
        page.screenshot(path="verification/detail.png")

        browser.close()

if __name__ == "__main__":
    run()
